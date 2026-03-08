import 'dart:io';

void main() {
  final f = File('lib/engine/derby_engine.dart');
  var s = f.readAsStringSync();

  s = s.replaceAll(
    'for (var r = 0; r < numRondasPL; r++) {',
    'int limit = resultado.matchings.keys.isEmpty ? numRondasPL : resultado.matchings.keys.length;\n    for (var r = 0; r < limit; r++) {',
  );

  f.writeAsStringSync(s);
}
