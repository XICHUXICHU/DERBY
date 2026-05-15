import 'package:dio/dio.dart';

Future<void> main() async {
  const firebaseProjectId = 'derby2-6f83a';
  final dio = Dio();
  
  final code = 'DERBY-DEMO-1234';
  final endpoint = 'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/Licenses/$code';
  
  final expiryDate = DateTime.now().toUtc().add(const Duration(days: 365));

  print('Registrando licencia $code ...');
  
  try {
    await dio.patch(
      endpoint,
      data: {
        "fields": {
          "hardware_id": { "stringValue": "" },
          "status": { "stringValue": "active" },
          "expiry_date": { "timestampValue": expiryDate.toIso8601String() }
        }
      }
    );
    print('✅ ¡Licencia de prueba guardada!');
  } catch (e) {
    print('Error: $e');
  }
}
