import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pointycastle/export.dart';
import 'hardware_id_service.dart';
import 'secure_license_storage.dart';

enum LicenseStatus {
  valid,
  expired,
  invalidHardware,
  offlineGracePeriod,
  offlineExpired,
  unregistered,
  banned,
}

class LicenseValidationResult {
  final LicenseStatus status;
  final String? message;
  final int? daysLeftOffline;

  LicenseValidationResult({
    required this.status,
    this.message,
    this.daysLeftOffline,
  });
}

class LicenseManager {
  // Configurable grace period: 7 days offline
  static const Duration _offlineGracePeriod = Duration(days: 7);

  // Firebase API details from the user's config
  static const String _firebaseProjectId = 'derby2-6f83a';
  static const String _firebaseApiKey =
      'AIzaSyCPJDRLdiBW2J3gUDUUOynA-yVBJM-HKSI';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  /// Gets the REAL TIME securely from Google's servers.
  /// Prevents Windows local time spoofing (Time-Travel attack).
  static Future<DateTime> _getSecureServerTime() async {
    try {
      // Pedir la hora a google y no confiar en el reloj de Windows/Mac
      final response = await _dio.head('https://google.com');
      final dateHeader = response.headers.value('date');
      if (dateHeader != null) {
        // Date format example: "Sat, 01 Jan 2022 00:00:00 GMT"
        // This parser is standard for HTTP Date headers
        return HttpDate.parse(dateHeader);
      }
      return DateTime.now(); // Fallback temporal
    } catch (e) {
      // Si falla la red, sube la excepción
      rethrow;
    }
  }

  /// Main entry point on app startup.
  /// Determines if the user can launch the app.
  static Future<LicenseValidationResult> checkCurrentLicense() async {
    final code = await SecureLicenseStorage.getLicenseCode();
    if (code == null) {
      return LicenseValidationResult(
        status: LicenseStatus.unregistered,
        message: 'No hay licencia registrada',
      );
    }

    final currentHwId = await HardwareIdService.generateHardwareId();
    final cachedHwId = await SecureLicenseStorage.getCachedHardwareId();

    // 1. Hardware Mismatch Check (User copied files to another PC)
    if (cachedHwId != null && cachedHwId != currentHwId) {
      await SecureLicenseStorage.clearLicense();
      return LicenseValidationResult(
        status: LicenseStatus.invalidHardware,
        message:
            'El hardware de este equipo no coincide con la licencia original.',
      );
    }

    // 2. Try online validation matching true server time
    try {
      // RSA licenses no necesitan Firestore — validar localmente
      if (_isRsaLicense(code)) {
        return await _validateRSAOnLaunch(code, currentHwId);
      }
      return await _validateOnline(code, currentHwId);
    } catch (e) {
      // 3. Network unreachable, fallback to Offline Logic
      return _validateOffline();
    }
  }

  /// Validates against the backend (Firebase Firestore REST API)
  static Future<LicenseValidationResult> _validateOnline(
    String code,
    String hardwareId,
  ) async {
    final serverTime = await _getSecureServerTime();

    final encodedCode = Uri.encodeComponent(code);
    final endpoint =
        'https://firestore.googleapis.com/v1/projects/$_firebaseProjectId/databases/(default)/documents/Licenses/$encodedCode?key=$_firebaseApiKey';

    try {
      final response = await _dio.get(endpoint);
      final fields = response.data['fields'];

      if (fields == null) {
        return LicenseValidationResult(
          status: LicenseStatus.unregistered,
          message: 'La licencia no existe.',
        );
      }

      final status = fields['status']?['stringValue'] ?? 'active';
      final expiryDateStr = fields['expiry_date']?['timestampValue'];
      final registeredHwId = fields['hardware_id']?['stringValue'] ?? '';

      if (status != 'active') {
        return LicenseValidationResult(
          status: LicenseStatus.banned,
          message:
              'Esta licencia ha sido revocada o suspendida por el administrador.',
        );
      }

      if (expiryDateStr == null) {
        return LicenseValidationResult(
          status: LicenseStatus.unregistered,
          message: 'Licencia sin fecha de expiración configurada.',
        );
      }

      final expiryDate = DateTime.parse(expiryDateStr);

      if (serverTime.isAfter(expiryDate)) {
        return LicenseValidationResult(
          status: LicenseStatus.expired,
          message: 'Su suscripción ha expirado.',
        );
      }

      // Check Machine Binding
      if (registeredHwId.isEmpty) {
        // Primera vez que se usa la licencia: Ligar al Hardware Actual mandando un PATCH a Firebase
        await _dio.patch(
          '$endpoint&updateMask.fieldPaths=hardware_id',
          data: {
            "fields": {
              "hardware_id": {"stringValue": hardwareId},
            },
          },
        );
      } else if (registeredHwId != hardwareId) {
        // Licencia robada o en otra máquina
        return LicenseValidationResult(
          status: LicenseStatus.invalidHardware,
          message: 'Esta licencia ya fue activada en otra computadora.',
        );
      }

      // Todo es válido, guardar secreto local
      await SecureLicenseStorage.saveLicense(
        licenseCode: code,
        serverTime: serverTime,
        expiryDate: expiryDate,
        hardwareId: hardwareId,
      );

      return LicenseValidationResult(status: LicenseStatus.valid);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return LicenseValidationResult(
          status: LicenseStatus.unregistered,
          message: 'El código de licencia ingresado no existe.',
        );
      }
      rethrow; // Si es error de red, pasa al catch principal para activar offline mode
    }
  }

  /// Verifies if the grace period holds, and detects time manipulations
  static Future<LicenseValidationResult> _validateOffline() async {
    final lastCheckIn = await SecureLicenseStorage.getLastCheckIn();
    final expiryDate = await SecureLicenseStorage.getExpiryDate();
    final monotonicCounter = await SecureLicenseStorage.getMonotonicCounter();

    if (lastCheckIn == null || expiryDate == null) {
      return LicenseValidationResult(
        status: LicenseStatus.unregistered,
        message: 'Datos locales corruptos. Necesita internet para reactivar.',
      );
    }

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Time-Traveler Detection 1:
    // Si el reloj actual está ANTES del último check-in → reloj retrasado
    if (now.isBefore(lastCheckIn)) {
      return LicenseValidationResult(
        status: LicenseStatus.offlineExpired,
        message:
            'Anomalía de reloj detectada. Por favor conecte a internet para verificar.',
      );
    }

    // Time-Traveler Detection 2:
    // Si el reloj actual está ANTES del contador monotónico → manipulación
    if (monotonicCounter > 0 && nowMs < monotonicCounter - 60000) {
      return LicenseValidationResult(
        status: LicenseStatus.offlineExpired,
        message:
            'Se detectó manipulación del reloj del sistema. Conéctese a internet.',
      );
    }

    // Time-Traveler Detection 3:
    // Si pasó el hard expiry
    if (now.isAfter(expiryDate)) {
      return LicenseValidationResult(
        status: LicenseStatus.expired,
        message: 'La licencia expiró. Conecte a internet para renovar.',
      );
    }

    // Offline Grace Period Check
    final durationOffline = now.difference(lastCheckIn);
    if (durationOffline > _offlineGracePeriod) {
      return LicenseValidationResult(
        status: LicenseStatus.offlineExpired,
        message:
            'Han pasado más de ${_offlineGracePeriod.inDays} días sin internet. Conéctese para validar la licencia.',
      );
    }

    final daysLeft = _offlineGracePeriod.inDays - durationOffline.inDays;
    return LicenseValidationResult(
      status: LicenseStatus.offlineGracePeriod,
      daysLeftOffline: daysLeft,
      message:
          'Modo sin conexión. La licencia se bloqueará en $daysLeft días si no detecta internet.',
    );
  }

  /// Used from Activation Screen
  static Future<LicenseValidationResult> activateLicense(String code) async {
    final hardwareId = await HardwareIdService.generateHardwareId();

    // Licencias RSA se validan localmente — no necesitan Firestore
    if (_isRsaLicense(code)) {
      return await _validateRSAOnLaunch(code, hardwareId);
    }

    // Licencias Firestore — validar online
    try {
      final result = await _validateOnline(code, hardwareId);
      if (result.status == LicenseStatus.valid) {
        return result;
      } else {
        await SecureLicenseStorage.clearLicense();
        return result;
      }
    } catch (e) {
      return LicenseValidationResult(
        status: LicenseStatus.offlineExpired,
        message: 'Error de conexión: ${e.toString().split('\n').first}',
      );
    }
  }

  static Future<void> deactivate() async {
    await SecureLicenseStorage.clearLicense();
  }

  // ═══════════════════════════════════════════════════════════════════
  // RSA LICENSE VALIDATION (format: DERBY-{payloadBase64}.{sigBase64})
  // ═══════════════════════════════════════════════════════════════════

  static const String _rsaPublicKey = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+xS++0KCy1x0MYEBzhbO
YaUrmqKdoNTdKxoQzlnxLUxBfmHE+Str4LhgN5uDGQzyKsfANJjnhyvSki3esOJ+
/bdHGLR/AK2K6waL211HYsC37NcoW0R+D6q+3iFrR86n5G6vwXfLviscXfYhqDWA
7YyrzAbgY5f+1uthx4Z0+VN0HpQ6CXBIA8utgrCUL7vtBeNjjJkdT3qSYPsvQzqS
yUgvJItUDiWejiq9LBkEwZBRYWVaCs0yLCSEGV7BwPmZUmFQF3TH8RbbIY8+MFCw
/sZZuR+s5drAaE8vwDWNf81tH7d/2pjwtGmqcnfDbZ882L9yiyctMXdH1/My+gs4
TwIDAQAB
-----END PUBLIC KEY-----
''';

  /// Detecta si el código es formato RSA (DERBY-payload.firma)
  static bool _isRsaLicense(String code) =>
      code.startsWith('DERBY-') && code.contains('.');

  /// Valida una licencia RSA en cada arranque de la app (no requiere red).
  static Future<LicenseValidationResult> _validateRSAOnLaunch(
    String code,
    String hardwareId,
  ) async {
    try {
      final content = code.substring(6); // quitar 'DERBY-'
      final dotIndex = content.indexOf('.');
      if (dotIndex < 0) {
        return LicenseValidationResult(
          status: LicenseStatus.unregistered,
          message: 'Licencia corrupta.',
        );
      }
      final payloadBase64 = content.substring(0, dotIndex);
      final signatureBase64 = content.substring(dotIndex + 1);

      // Verificar firma RSA
      if (!_verifyRSASignature(payloadBase64, signatureBase64)) {
        await SecureLicenseStorage.clearLicense();
        return LicenseValidationResult(
          status: LicenseStatus.unregistered,
          message: 'Firma de licencia inválida.',
        );
      }

      // Decodificar payload (normalizar padding base64 si el admin omitió '=')
      final payloadJson = utf8.decode(base64Decode(_normBase64(payloadBase64)));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      // expiresAt es obligatorio — una licencia sin expiración es un error del admin
      if (payload['expiresAt'] == null) {
        return LicenseValidationResult(
          status: LicenseStatus.unregistered,
          message: 'Licencia malformada: falta fecha de expiración.',
        );
      }
      final DateTime expiryDate = DateTime.parse(payload['expiresAt'] as String);

      // Hora segura (servidor si disponible, local como respaldo)
      DateTime now;
      try {
        now = await _getSecureServerTime();
      } catch (_) {
        now = DateTime.now();
      }

      if (now.isAfter(expiryDate)) {
        return LicenseValidationResult(
          status: LicenseStatus.expired,
          message: 'Su suscripción ha expirado.',
        );
      }

      // Verificar prefijo de dispositivo si la licencia lo tiene
      final devicePrefix = payload['devicePrefix'] as String?;
      if (devicePrefix != null && devicePrefix.isNotEmpty) {
        if (!hardwareId.toUpperCase().startsWith(devicePrefix.toUpperCase())) {
          return LicenseValidationResult(
            status: LicenseStatus.invalidHardware,
            message: 'Esta licencia está vinculada a otro dispositivo.',
          );
        }
      }

      // Actualizar check-in local
      await SecureLicenseStorage.saveLicense(
        licenseCode: code,
        serverTime: now,
        expiryDate: expiryDate,
        hardwareId: hardwareId,
      );

      return LicenseValidationResult(status: LicenseStatus.valid);
    } catch (e) {
      // Si falla algo inesperado en el parsing/validación, la licencia es inválida.
      // NO usar _validateOffline() — una excepción aquí no concede gracia.
      return LicenseValidationResult(
        status: LicenseStatus.unregistered,
        message: 'Licencia inválida o corrupta.',
      );
    }
  }

  /// Normaliza padding de base64 estándar (agrega '=' faltantes).
  static String _normBase64(String s) {
    final rem = s.length % 4;
    return rem == 0 ? s : s + '=' * (4 - rem);
  }

  /// Verifica la firma RSA-SHA256 del payload.
  static bool _verifyRSASignature(
      String payloadBase64, String signatureBase64) {
    try {
      final publicKey = _parseRSAPublicKey(_rsaPublicKey);
      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
      final payloadBytes = Uint8List.fromList(base64Decode(_normBase64(payloadBase64)));
      final signatureBytes = Uint8List.fromList(base64Decode(_normBase64(signatureBase64)));
      return signer.verifySignature(payloadBytes, RSASignature(signatureBytes));
    } catch (_) {
      return false;
    }
  }

  /// Parsea una clave pública RSA desde PEM (SubjectPublicKeyInfo).
  static RSAPublicKey _parseRSAPublicKey(String pem) {
    final lines = pem
        .split('\n')
        .where((l) => !l.startsWith('-----') && l.trim().isNotEmpty)
        .join();
    final keyBytes = base64Decode(lines);
    int offset = 0;

    // Outer SEQUENCE
    if (keyBytes[offset] != 0x30) throw Exception('Expected SEQUENCE');
    offset++;
    offset = _skipLen(keyBytes, offset);

    // Algorithm SEQUENCE
    if (keyBytes[offset] != 0x30) throw Exception('Expected alg SEQUENCE');
    offset++;
    final algLen = _readLen(keyBytes, offset);
    offset = _skipLen(keyBytes, offset);
    offset += algLen;

    // BIT STRING
    if (keyBytes[offset] != 0x03) throw Exception('Expected BIT STRING');
    offset++;
    offset = _skipLen(keyBytes, offset);
    offset++; // unused bits byte

    // RSAPublicKey SEQUENCE
    if (keyBytes[offset] != 0x30) throw Exception('Expected RSAPublicKey SEQUENCE');
    offset++;
    offset = _skipLen(keyBytes, offset);

    // Modulus INTEGER
    offset++; // 0x02 tag
    final modLen = _readLen(keyBytes, offset);
    offset = _skipLen(keyBytes, offset);
    final modulus = _bytesToBigInt(keyBytes.sublist(offset, offset + modLen));
    offset += modLen;

    // Exponent INTEGER
    offset++; // 0x02 tag
    final expLen = _readLen(keyBytes, offset);
    offset = _skipLen(keyBytes, offset);
    final exponent = _bytesToBigInt(keyBytes.sublist(offset, offset + expLen));

    return RSAPublicKey(modulus, exponent);
  }

  static int _skipLen(List<int> bytes, int offset) {
    if (bytes[offset] < 0x80) return offset + 1;
    return offset + 1 + (bytes[offset] & 0x7f);
  }

  static int _readLen(List<int> bytes, int offset) {
    if (bytes[offset] < 0x80) return bytes[offset];
    final n = bytes[offset] & 0x7f;
    int len = 0;
    for (int i = 0; i < n; i++) len = (len << 8) | bytes[offset + 1 + i];
    return len;
  }

  static BigInt _bytesToBigInt(List<int> bytes) {
    BigInt result = BigInt.zero;
    for (final b in bytes) result = (result << 8) | BigInt.from(b);
    return result;
  }
}
