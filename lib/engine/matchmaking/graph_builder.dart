import '../../domain/domain.dart';

/// Arista del grafo de matching.
/// Representa un enfrentamiento POSIBLE entre dos gallos.
class AristaGrafo {
  final Gallo galloA;
  final Gallo galloB;
  final double peso; // diferencia absoluta de peso en gramos

  const AristaGrafo({
    required this.galloA,
    required this.galloB,
    required this.peso,
  });

  @override
  String toString() =>
      'Arista(${galloA.anillo} vs ${galloB.anillo}, diff=${peso.toStringAsFixed(1)}g)';
}

/// Construye el grafo de enfrentamientos posibles.
///
/// Nodo = gallo disponible
/// Arista = enfrentamiento permitido (no viola restricciones)
/// Peso de arista = diferencia absoluta de peso
class GraphBuilder {
  /// Conjunto de pares de partidos que son compadres (restricción dura).
  final Set<(int, int)> _compadresSet;

  /// Historial: gallos que ya pelearon (conjunto de IDs).
  final Set<int> _gallosUsados;

  /// Historial: pares de partidos que ya se enfrentaron en rondas anteriores.
  /// Se usa para evitar repeticiones cuando sea posible.
  final Set<(int, int)> _enfrentamientosPrevios;

  /// Diferencia máxima de peso permitida en P.L. (g). 0 = sin límite.
  final double diferenciaMaxPeso;

  /// ¿Esta ronda es de gallos base? Si true, no se aplica límite de peso.
  final bool esRondaBase;

  GraphBuilder({
    required List<Compadres> compadres,
    Set<int> gallosUsados = const {},
    Set<(int, int)> enfrentamientosPrevios = const {},
    this.diferenciaMaxPeso = 0.0,
    this.esRondaBase = false,
  })  : _compadresSet = _buildCompadresSet(compadres),
        _gallosUsados = gallosUsados,
        _enfrentamientosPrevios = enfrentamientosPrevios;

  /// Normaliza las relaciones de compadres a un set de tuplas ordenadas.
  static Set<(int, int)> _buildCompadresSet(List<Compadres> compadres) {
    final set = <(int, int)>{};
    for (final c in compadres) {
      final a = c.partidoIdA < c.partidoIdB ? c.partidoIdA : c.partidoIdB;
      final b = c.partidoIdA < c.partidoIdB ? c.partidoIdB : c.partidoIdA;
      set.add((a, b));
    }
    return set;
  }

  /// Verifica si dos partidos son compadres.
  bool sonCompadres(int partidoA, int partidoB) {
    final a = partidoA < partidoB ? partidoA : partidoB;
    final b = partidoA < partidoB ? partidoB : partidoA;
    return _compadresSet.contains((a, b));
  }

  /// Verifica si dos partidos ya se enfrentaron.
  bool yaSeEnfrentaron(int partidoA, int partidoB) {
    final a = partidoA < partidoB ? partidoA : partidoB;
    final b = partidoA < partidoB ? partidoB : partidoA;
    return _enfrentamientosPrevios.contains((a, b));
  }

  /// Construye el grafo completo de enfrentamientos válidos.
  ///
  /// [gallosDisponibles] son los gallos que pueden pelear en esta ronda.
  /// Retorna la lista de aristas (enfrentamientos posibles), ordenada
  /// por diferencia de peso ascendente.
  List<AristaGrafo> construirGrafo(List<Gallo> gallosDisponibles) {
    final aristas = <AristaGrafo>[];
    final n = gallosDisponibles.length;

    for (var i = 0; i < n; i++) {
      final a = gallosDisponibles[i];

      // Saltar gallos que ya pelearon
      if (_gallosUsados.contains(a.id)) continue;

      for (var j = i + 1; j < n; j++) {
        final b = gallosDisponibles[j];

        // Saltar gallos que ya pelearon
        if (_gallosUsados.contains(b.id)) continue;

        // RESTRICCIÓN 1: No enfrentar gallos del mismo partido
        if (a.partidoId == b.partidoId) continue;

        // RESTRICCIÓN 2: No enfrentar partidos compadres
        if (sonCompadres(a.partidoId, b.partidoId)) continue;

        // RESTRICCIÓN 3: Diferencia máxima de peso (solo P.L., no base)
        final diff = a.diferenciaAbsoluta(b);
        if (!esRondaBase && diferenciaMaxPeso > 0 && diff > diferenciaMaxPeso) {
          continue;
        }

        // Arista válida
        aristas.add(AristaGrafo(
          galloA: a,
          galloB: b,
          peso: diff,
        ));
      }
    }

    // Ordenar por peso (diferencia de peso) ascendente
    aristas.sort((a, b) => a.peso.compareTo(b.peso));

    return aristas;
  }

  /// Construye grafo priorizando NO repetir enfrentamientos previos.
  /// Retorna dos listas: aristas preferidas (sin repetición) y aristas
  /// de respaldo (con repetición de contrincante).
  ({List<AristaGrafo> preferidas, List<AristaGrafo> respaldo})
      construirGrafoPriorizado(List<Gallo> gallosDisponibles) {
    final todas = construirGrafo(gallosDisponibles);
    final preferidas = <AristaGrafo>[];
    final respaldo = <AristaGrafo>[];

    for (final arista in todas) {
      if (yaSeEnfrentaron(arista.galloA.partidoId, arista.galloB.partidoId)) {
        respaldo.add(arista);
      } else {
        preferidas.add(arista);
      }
    }

    return (preferidas: preferidas, respaldo: respaldo);
  }
}
