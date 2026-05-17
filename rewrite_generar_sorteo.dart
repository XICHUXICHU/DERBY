import 'dart:io';

void main() {
  final file = File('lib/application/usecases/generar_sorteo.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains("GlobalPoolMatcher")) {
    content = content.replaceAll(
      "import '../../engine/derby_engine.dart';",
      "import '../../engine/derby_engine.dart';\nimport '../../engine/matchmaking/global_pool_matcher.dart';"
    );
  }
  
  final globalFunc = """
  List<Ronda> _ejecutarGlobal(
      List<Partido> partidos, List<Gallo> gallosEfectivos, List<Compadres> compadres, int nRondas) {
    if (nRondas <= 0) return [];
    final gallosPL = gallosEfectivos.where((g) => !g.esBase).toList();
    if (gallosPL.isEmpty) return [];

    print("🐓 Ejecutando GlobalPoolMatcher para \${gallosPL.length} gallos usando \$nRondas rondas.");
    final pares = GlobalPoolMatcher.emparejarTodo(gallos: gallosPL, compadres: compadres);

    final rondasGeneradas = <Ronda>[];
    List<ParGlobal> pool = List.from(pares);
    
    for (int i = 1; i <= nRondas; i++) {
      List<Enfrentamiento> fights = [];
      Set<int> usadosEnRonda = {};
      List<ParGlobal> restantes = [];
      
      for (var p in pool) {
        if (!usadosEnRonda.contains(p.a.partidoId) && !usadosEnRonda.contains(p.b.partidoId)) {
          usadosEnRonda.add(p.a.partidoId);
          usadosEnRonda.add(p.b.partidoId);
          fights.add(Enfrentamiento(galloA: p.a, galloB: p.b));
        } else {
          restantes.add(p);
        }
      }
      
      if (i == nRondas) {
        for (var p in restantes) {
          fights.add(Enfrentamiento(galloA: p.a, galloB: p.b));
        }
        restantes.clear();
      }
      pool = restantes;
      rondasGeneradas.add(Ronda(numero: i, enfrentamientos: fights, partidosBye: const []));
    }
    return rondasGeneradas;
  }
""";

  if (!content.contains("_ejecutarGlobal")) {
     content = content.replaceFirst("class GenerarSorteo {", "class GenerarSorteo {\n" + globalFunc);
  }
  
  // Replace the implementation of ejecutarPrimerBloque
  final regexPrimer = RegExp(r"List<Ronda> ejecutarPrimerBloque\(\{.*?return rondasGeneradas;\n  \}", dotAll: true);
  content = content.replaceFirst(regexPrimer, """List<Ronda> ejecutarPrimerBloque({
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    int? numRondasIniciales,
    int? partidoDoblePreferidoId,
    int? galloBasePromovidoId,
  }) {
    final rondasPL = calcularRondasPL(partidos, gallos);
    final nRondas = numRondasIniciales ?? rondasPL;
    if (nRondas <= 0) return [];
    final esImpar = partidos.where((p) => p.estado == EstadoPartido.activo && !p.eliminado && !p.esComodin).length % 2 != 0;
    
    final gallosEfectivos = esImpar
        ? _promoverBaseParImpar(partidos: partidos, gallos: gallos, galloBaseIdOverride: galloBasePromovidoId)
        : gallos;
    return _ejecutarGlobal(partidos, gallosEfectivos, compadres, nRondas);
  }""");

  final regexTodas = RegExp(r"List<Ronda> ejecutarTodas\(\{.*?return rondasGeneradas;\n  \}", dotAll: true);
  content = content.replaceFirst(regexTodas, """List<Ronda> ejecutarTodas({
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    int? partidoDoblePreferidoId,
    int? galloBasePromovidoId,
  }) {
    final rondasPL = calcularRondasPL(partidos, gallos);
    if (rondasPL <= 0) return [];
    
    final esImpar = partidos.where((p) => p.estado == EstadoPartido.activo && !p.eliminado && !p.esComodin).length % 2 != 0;
    
    final gallosEfectivos = esImpar
        ? _promoverBaseParImpar(partidos: partidos, gallos: gallos, galloBaseIdOverride: galloBasePromovidoId)
        : gallos;
        
    return _ejecutarGlobal(partidos, gallosEfectivos, compadres, rondasPL);
  }""");
  
  file.writeAsStringSync(content);
}
