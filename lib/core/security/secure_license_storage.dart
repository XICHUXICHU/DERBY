import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Almacena los datos de licencia en la carpeta local del app.
/// Funciona en Windows MSIX, macOS y cualquier plataforma desktop.
/// path_provider usa la carpeta aislada del app (AppData\Local\Packages\...\LocalState)
class SecureLicenseStorage {
  static const _fileName = 'derby_lic.dat';
  // XOR para que el archivo no sea JSON plano legible
  static const _k = [0x44, 0x52, 0x42, 0x32, 0x4C, 0x49, 0x43, 0x5A];

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  static List<int> _xor(List<int> d) =>
      List.generate(d.length, (i) => d[i] ^ _k[i % _k.length]);

  static Future<Map<String, dynamic>> _read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final raw = await f.readAsBytes();
      return jsonDecode(utf8.decode(_xor(raw))) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _write(Map<String, dynamic> data) async {
    final f = await _file();
    await f.writeAsBytes(_xor(utf8.encode(jsonEncode(data))));
  }

  static Future<void> saveLicense({
    required String licenseCode,
    required DateTime serverTime,
    required DateTime expiryDate,
    required String hardwareId,
  }) async {
    final prev = await _read();
    final prevCounter = (prev['mc'] as int?) ?? 0;
    final newCounter = serverTime.millisecondsSinceEpoch;
    await _write({
      'lc': licenseCode,
      'ci': serverTime.millisecondsSinceEpoch,
      'ex': expiryDate.millisecondsSinceEpoch,
      'hw': hardwareId,
      'mc': newCounter > prevCounter ? newCounter : prevCounter,
    });
  }

  static Future<String?> getLicenseCode() async =>
      (await _read())['lc'] as String?;

  static Future<DateTime?> getLastCheckIn() async {
    final ms = (await _read())['ci'] as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  static Future<DateTime?> getExpiryDate() async {
    final ms = (await _read())['ex'] as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  static Future<String?> getCachedHardwareId() async =>
      (await _read())['hw'] as String?;

  static Future<int> getMonotonicCounter() async =>
      (await _read())['mc'] as int? ?? 0;

  static Future<void> clearLicense() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}
