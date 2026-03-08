import os

with open('lib/application/usecases/generar_sorteo.dart', 'r') as f:
    text = f.read()
    
func_code = """
  static int calcularRondasPL(List<Partido> partidos, List<Gallo> gallos) {
    if (partidos.isEmpty) return 0;
    final activos = partidos.where((p) => p.estado == EstadoPartido.activo && !p.eliminado && !p.esComodin).map((p) => p.id).toSet();
    if (activos.isEmpty) return 0;
    
    final conteos = <int, int>{};
    for (var p in activos) {
      conteos[p] = 0;
    }
    for (var g in gallos) {
      if (!g.esBase && activos.contains(g.partidoId)) {
        conteos[g.partidoId] = (conteos[g.partidoId] ?? 0) + 1;
      }
    }

    if (conteos.values.isEmpty) return 0;
    int maxPL = conteos.values.reduce(
        (a, b) => a > b ? a : b
    );
    return maxPL;
  }
}
"""

text = text.replace("  }\n}", func_code)

with open('lib/application/usecases/generar_sorteo.dart', 'w') as f:
    f.write(text)

