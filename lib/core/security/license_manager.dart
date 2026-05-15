import 'dart:io';
import 'package:dio/dio.dart';
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

    final endpoint =
        'https://firestore.googleapis.com/v1/projects/$_firebaseProjectId/databases/(default)/documents/Licenses/$code?key=$_firebaseApiKey';

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
    try {
      final result = await _validateOnline(code, hardwareId);
      if (result.status == LicenseStatus.valid) {
        return result;
      } else {
        await SecureLicenseStorage.clearLicense();
        return result;
      }
    } catch (e, stack) {
      print('Error activando licencia: $e\n$stack');
      return LicenseValidationResult(
        status: LicenseStatus.offlineExpired,
        message: 'Error de conexión: ${e.toString().split('\n').first}',
      );
    }
  }

  static Future<void> deactivate() async {
    await SecureLicenseStorage.clearLicense();
  }
}
