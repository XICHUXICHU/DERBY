import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'security/secure_license_storage.dart';

/// Envía eventos de uso anónimos a Firestore para que el admin
/// pueda ver actividad: aperturas de app y derbys creados.
/// Solo escribe — la app nunca lee esta colección.
class AnalyticsService {
  static const _projectId = 'derby2-6f83a';
  static const _apiKey = 'AIzaSyCPJDRLdiBW2J3gUDUUOynA-yVBJM-HKSI';
  static const _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId'
      '/databases/(default)/documents/app_events?key=$_apiKey';

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ),
  );

  /// Registra que el usuario abrió la app.
  static Future<void> logAppOpen() => _send('app_open', {});

  /// Registra que se creó o editó un derby.
  static Future<void> logDerbyCreated(String derbyNombre) =>
      _send('derby_created', {'derby_nombre': _strValue(derbyNombre)});

  // ── interno ──────────────────────────────────────────────────────────────

  static Future<void> _send(
      String type, Map<String, dynamic> extra) async {
    try {
      final info = await _deviceInfo();
      final licenseCode = await SecureLicenseStorage.getLicenseCode();

      final fields = <String, dynamic>{
        'type': _strValue(type),
        'license_code': _strValue(_maskCode(licenseCode)),
        'computer_name': _strValue(info['computer_name']!),
        'windows_version': _strValue(info['windows_version']!),
        'hardware_id': _strValue(info['hardware_id']!),
        'timestamp': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        ...extra,
      };

      await _dio.post(_baseUrl, data: jsonEncode({'fields': fields}));
    } catch (_) {
      // Silencioso — la telemetría nunca debe romper el flujo principal
    }
  }

  static Future<Map<String, String>> _deviceInfo() async {
    try {
      if (Platform.isWindows) {
        final info = await DeviceInfoPlugin().windowsInfo;
        return {
          'computer_name': info.computerName,
          'windows_version': '${info.productName} (build ${info.buildNumber})',
          'hardware_id': info.computerName, // se complementa con hwId de storage
        };
      }
    } catch (_) {}
    return {
      'computer_name': 'desconocido',
      'windows_version': Platform.operatingSystemVersion,
      'hardware_id': 'desconocido',
    };
  }

  static String _maskCode(String? code) {
    if (code == null) return 'sin-licencia';
    if (code.startsWith('DERBY-')) return 'DERBY-****';
    final parts = code.split('-');
    if (parts.length >= 3) {
      return '${parts[0]}-${parts[1]}-${parts[2]}-****';
    }
    return '${code.substring(0, code.length.clamp(0, 8))}****';
  }

  static Map<String, dynamic> _strValue(String v) => {'stringValue': v};
}
