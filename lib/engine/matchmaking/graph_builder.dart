import '../../domain/domain.dart';

/// Arista del grafo de matching.
/// Representa un enfrentamiento POSIBLE entre dos gallos.
class AristaGrafo {
  final Gallo galloA;
  final Gallo galloB;
  final double peso; // diferencia absoluta de peso en gramos (real)

  /// Penalización extra por repetir contrincantes previos.
  /// 0 si es enfrentamiento nuevo. Crece con cada repetición.
  final double penalizacion;

  /// Costo total = peso real + penalización.
  /// El solver usa esto para optimizar; el display usa [peso].
  double get costoTotal => peso + penalizacion;

  const AristaGrafo({
    required this.galloA,
    required this.galloB,
    required this.peso,
    this.penalizacion = 0.0,
  });

  @override
  String toString() =>
      'Arista(${galloA.anillo} vs ${galloB.anillo}, diff=${peso.toStringAsFixed(1)}g'
      '${penalizacion > 0 ? ", pen=${penalizacion.toStringAsFixed(0)}" : ""})';
}

/// Construye el grafo de enfrentamientos posibles.
///
/// Nodo = gallo disponible
/// Arista = enfrentamiento permitido (no viola restricciones)
/// Peso de arista = diferencia absoluta de peso
///
/// Estilo Tuums: usa conteo de enfrentamientos previos (no solo booleano)
/// para penalizar repeticiones gradualmente y poner un límite duro.
class GraphBuilder {
  /// Conjunto de pares de partidos que son compadres (restricción dura).
  final Set<(int, int)> _compadresSet;

  /// Historial: gallos que ya pelearon (conjunto de IDs).
  final Set<int> _gallosUsados;

  /// Historial: pares de partidos → cuántas veces se enfrentaron.
  /// Estilo Tuums: `VecesQueYaSeEnfrentaronEntrePartidos()`.
  final Map<(int, int), int> _conteoEnfrentamientos;

  /// Diferencia máxima de peso permitida en P.L. (g). 0 = sin límite.
  final double diferenciaMaxPeso;

  /// Penalización por cada repetición de enfrentamiento previo (gramos).
  /// Se suma al peso real de la arista para que el solver la desfavorezca.
  /// Calculado automáticamente como `diferenciaMaxPeso * 10 + 1` si > 0,
  /// o 10000.0 si no hay límite de peso.
  final double _penalizacionPorRepeticion;

  GraphBuilder({
    required List<Compadres> compadres,
    Set<int> gallosUsados = const {},
    Map<(int, int), int> conteoEnfrentamientos = const {},
    this.diferenciaMaxPeso = 0.0,
  }) : _compadresSet = _buildCompadresSet(compadres),
       _gallosUsados = gallosUsados,
       _conteoEnfrentamientos = conteoEnfrentamientos,
       _penalizacionPorRepeticion = diferenciaMaxPeso > 0
           ? diferenciaMaxPeso * 10 + 1
           : 10000.0;

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
    return vecesEnfrentados(partidoA, partidoB) > 0;
  }

  /// Retorna cuántas veces dos partidos se han enfrentado.
  /// Estilo Tuums: `VecesQueYaSeEnfrentaronEntrePartidos()`.
  int vecesEnfrentados(int partidoA, int partidoB) {
    final a = partidoA < partidoB ? partidoA : partidoB;
    final b = partidoA < partidoB ? partidoB : partidoA;
    return _conteoEnfrentamientos[(a, b)] ?? 0;
  }

  /// Construye el grafo completo de enfrentamientos válidos.
  ///
  /// [gallosDisponibles] son los gallos que pueden pelear en esta ronda.
  /// Retorna la lista de aristas (enfrentamientos posibles), ordenada
  /// por diferencia de peso ascendente.
  ///
  /// Nota: NO aplica límite duro de repeticiones aquí. El sistema de
  /// penalización en [construirGrafoPriorizado] se encarga de desincentivar
  /// repeticiones sin bloquear la generación del grafo.
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

        // RESTRICCIÓN 3: Diferencia máxima de peso
        final diff = a.diferenciaAbsoluta(b);
        if (diferenciaMaxPeso > 0 && diff > diferenciaMaxPeso) {
          continue;
        }

        // Arista válida
        aristas.add(AristaGrafo(galloA: a, galloB: b, peso: diff));
      }
    }

    // Ordenar por peso (diferencia de peso) ascendente
    aristas.sort((a, b) => a.peso.compareTo(b.peso));

    return aristas;
  }

  /// Construye grafo priorizando NO repetir enfrentamientos previos.
  /// Retorna dos listas: aristas preferidas (sin repetición) y aristas
  /// de respaldo (con repetición de contrincante).
  ///
  /// Las aristas de respaldo llevan penalización proporcional al número
  /// de veces que ya se enfrentaron (estilo Tuums: facilidad gradual).
  /// Esto garantiza que el solver solo las use como último recurso y
  /// prefiera repetir 1 vez antes que 2.
  ({List<AristaGrafo> preferidas, List<AristaGrafo> respaldo})
  construirGrafoPriorizado(List<Gallo> gallosDisponibles) {
    final todas = construirGrafo(gallosDisponibles);
    final preferidas = <AristaGrafo>[];
    final respaldo = <AristaGrafo>[];

    for (final arista in todas) {
      final veces = vecesEnfrentados(
        arista.galloA.partidoId,
        arista.galloB.partidoId,
      );
      if (veces > 0) {
        // Penalización creciente: 1ª repetición = pen*1, 2ª = pen*2, etc.
        // Esto hace que el solver prefiera rivales nuevos, y si debe
        // repetir, prefieriera pares con menos repeticiones.
        respaldo.add(AristaGrafo(
          galloA: arista.galloA,
          galloB: arista.galloB,
          peso: arista.peso,
          penalizacion: _penalizacionPorRepeticion * veces,
        ));
      } else {
        preferidas.add(arista);
      }
    }

    return (preferidas: preferidas, respaldo: respaldo);
  }
}
