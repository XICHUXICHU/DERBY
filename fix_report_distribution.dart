import 'dart:io';

void main() {
  final file = File('lib/application/usecases/generar_sorteo.dart');
  var content = file.readAsStringSync();
  
  final out = content.replaceFirst(
    "Set<int> usadosEnRonda = {};",
    "Set<int> usadosEnRonda = {}; /* Modified by Smart Dist */"
  );
  
  file.writeAsStringSync(out);
}
