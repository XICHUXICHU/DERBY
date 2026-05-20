import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' hide Hmac;
import 'package:path_provider/path_provider.dart';
import 'hardware_id_service.dart';

/// Almacena la licencia cifrada en disco con clave derivada del hardware.
/// Cada máquina genera una clave diferente → copiar el archivo no sirve.
class SecureLicenseStorage {
  static const _keyLicenseCode = 'lc';
  static const _keyLastCheckIn = 'ci';
  static const _keyLocalExpiry = 'ex';
  static const _keyCachedHardwareId = 'hw';
  static const _keyMonotonicCounter = 'mc';

  static const _fileName = '.derby_lic.dat';
  // Salt que se combina con el hardware ID para derivar la clave
  static const _salt = 'D3rby_Pr0_2026_s4lt!';

  /// Deriva una clave de 32 bytes (256 bits) única por máquina
  static Future<Uint8List> _deriveKey() async {
    final hwId = await HardwareIdService.generateHardwareId();
    // HMAC-SHA256(salt, hardwareId) → clave de 32 bytes única
    final hmac = Hmac(sha256, utf8.encode(_salt));
    final digest = hmac.convert(utf8.encode(hwId));
    return Uint8List.fromList(digest.bytes);
  }

  static Future<File> _getFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<Map<String, String>> _readAll() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return {};
      final raw = await file.readAsBytes();
      final key = await _deriveKey();
      final decoded = await _decrypt(raw, key);
      final jsonStr = utf8.decode(decoded);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      // Archivo corrupto o formato antiguo (XOR) — el usuario deberá reactivar
      return {};
    }
  }

  static Future<void> _writeAll(Map<String, String> data) async {
    final file = await _getFile();
    final jsonStr = json.encode(data);
    final key = await _deriveKey();
    final encoded = await _encrypt(utf8.encode(jsonStr), key);
    await file.writeAsBytes(encoded, flush: true);
  }

  /// Cifra con AES-256-GCM. Formato de salida: [12 nonce][ciphertext][16 MAC]
  static Future<Uint8List> _encrypt(List<int> plaintext, Uint8List key) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(key);
    final secretBox = await algorithm.encrypt(plaintext, secretKey: secretKey);
    return Uint8List.fromList(secretBox.concatenation());
  }

  /// Descifra AES-256-GCM y verifica el MAC. Lanza si los datos están alterados.
  static Future<Uint8List> _decrypt(List<int> ciphertext, Uint8List key) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(key);
    final secretBox = SecretBox.fromConcatenation(
      ciphertext,
      nonceLength: 12,
      macLength: 16,
    );
    final decrypted = await algorithm.decrypt(secretBox, secretKey: secretKey);
    return Uint8List.fromList(decrypted);
  }

  /// Saves the active license details securely
  static Future<void> saveLicense({
    required String licenseCode,
    required DateTime serverTime,
    required DateTime expiryDate,
    required String hardwareId,
  }) async {
    final data = await _readAll();
    data[_keyLicenseCode] = licenseCode;
    data[_keyLastCheckIn] = serverTime.millisecondsSinceEpoch.toString();
    data[_keyLocalExpiry] = expiryDate.millisecondsSinceEpoch.toString();
    data[_keyCachedHardwareId] = hardwareId;
    // Contador monotónico: siempre incrementa, nunca puede retroceder
    final prevCounter = int.tryParse(data[_keyMonotonicCounter] ?? '0') ?? 0;
    final newCounter = serverTime.millisecondsSinceEpoch;
    data[_keyMonotonicCounter] = (newCounter > prevCounter ? newCounter : prevCounter).toString();
    await _writeAll(data);
  }

  /// Get the stored license code
  static Future<String?> getLicenseCode() async {
    final data = await _readAll();
    return data[_keyLicenseCode];
  }

  /// Get the date when the app last verified the license online
  static Future<DateTime?> getLastCheckIn() async {
    final data = await _readAll();
    final val = data[_keyLastCheckIn];
    if (val != null) {
      final ms = int.tryParse(val);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  /// Get the official expiration date (from the token/server, not local)
  static Future<DateTime?> getExpiryDate() async {
    final data = await _readAll();
    final val = data[_keyLocalExpiry];
    if (val != null) {
      final ms = int.tryParse(val);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  /// Get the hardware ID used when the license was activated
  static Future<String?> getCachedHardwareId() async {
    final data = await _readAll();
    return data[_keyCachedHardwareId];
  }

  /// Get the monotonic counter (always-increasing timestamp)
  /// Used to detect clock rollback attacks
  static Future<int> getMonotonicCounter() async {
    final data = await _readAll();
    return int.tryParse(data[_keyMonotonicCounter] ?? '0') ?? 0;
  }

  /// Wipe the stored license data
  static Future<void> clearLicense() async {
    try {
      final file = await _getFile();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
