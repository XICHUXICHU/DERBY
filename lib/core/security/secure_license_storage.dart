import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacena los datos de licencia usando el almacén seguro del sistema operativo.
/// Windows: Windows Credential Manager con DPAPI (clave inextractable por código)
/// macOS:   Keychain del sistema
class SecureLicenseStorage {
  static const _kLicenseCode = 'derby_lc';
  static const _kLastCheckIn = 'derby_ci';
  static const _kLocalExpiry = 'derby_ex';
  static const _kCachedHardwareId = 'derby_hw';
  static const _kMonotonicCounter = 'derby_mc';

  static final _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(),
  );

  /// Saves the active license details securely
  static Future<void> saveLicense({
    required String licenseCode,
    required DateTime serverTime,
    required DateTime expiryDate,
    required String hardwareId,
  }) async {
    final prevCounterStr = await _storage.read(key: _kMonotonicCounter);
    final prevCounter = int.tryParse(prevCounterStr ?? '0') ?? 0;
    final newCounter = serverTime.millisecondsSinceEpoch;
    await Future.wait([
      _storage.write(key: _kLicenseCode, value: licenseCode),
      _storage.write(key: _kLastCheckIn, value: serverTime.millisecondsSinceEpoch.toString()),
      _storage.write(key: _kLocalExpiry, value: expiryDate.millisecondsSinceEpoch.toString()),
      _storage.write(key: _kCachedHardwareId, value: hardwareId),
      _storage.write(
        key: _kMonotonicCounter,
        value: (newCounter > prevCounter ? newCounter : prevCounter).toString(),
      ),
    ]);
  }

  /// Get the stored license code
  static Future<String?> getLicenseCode() => _storage.read(key: _kLicenseCode);

  /// Get the date when the app last verified the license online
  static Future<DateTime?> getLastCheckIn() async {
    final val = await _storage.read(key: _kLastCheckIn);
    if (val == null) return null;
    final ms = int.tryParse(val);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// Get the official expiration date
  static Future<DateTime?> getExpiryDate() async {
    final val = await _storage.read(key: _kLocalExpiry);
    if (val == null) return null;
    final ms = int.tryParse(val);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// Get the hardware ID used when the license was activated
  static Future<String?> getCachedHardwareId() => _storage.read(key: _kCachedHardwareId);

  /// Get the monotonic counter (always-increasing timestamp)
  /// Used to detect clock rollback attacks
  static Future<int> getMonotonicCounter() async {
    final val = await _storage.read(key: _kMonotonicCounter);
    return int.tryParse(val ?? '0') ?? 0;
  }

  /// Wipe the stored license data
  static Future<void> clearLicense() async {
    await Future.wait([
      _storage.delete(key: _kLicenseCode),
      _storage.delete(key: _kLastCheckIn),
      _storage.delete(key: _kLocalExpiry),
      _storage.delete(key: _kCachedHardwareId),
      _storage.delete(key: _kMonotonicCounter),
    ]);
  }
}
