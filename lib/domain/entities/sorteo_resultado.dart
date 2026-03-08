/// Resultado de una ronda individual para un partido específico.
class RondaResultado {
  /// Número de ronda (1..N).
  final int numeroRonda;

  /// Anillo del gallo propio que pelea.
  final String anilloPropio;

  /// Anillo del gallo rival.
  final String anilloRival;

  /// Fila (1-based) del partido rival en la tabla general.
  final int filaPartidoRival;

  /// Nombre del partido rival.
  final String nombrePartidoRival;

  /// Peso del gallo propio (gramos).
  final double pesoPropio;

  /// Peso del gallo rival (gramos).
  final double pesoRival;

  /// true si este partido tiene bye (descanso) en esta ronda.
  final bool esBye;

  /// true si este partido pelea doble en esta ronda (tiene 2 resultados).
  final bool esDoble;

  const RondaResultado({
    required this.numeroRonda,
    this.anilloPropio = '',
    this.anilloRival = '',
    this.filaPartidoRival = 0,
    this.nombrePartidoRival = '',
    this.pesoPropio = 0,
    this.pesoRival = 0,
    this.esBye = false,
    this.esDoble = false,
  });

  /// Formato corto para la Hoja de Estilo.
  String get formatoCorto {
    if (esBye) return 'BYE';
    final prefix = esDoble ? '×2 ' : '';
    return '$prefix$anilloPropio VS $anilloRival  $filaPartidoRival';
  }

  @override
  String toString() {
    if (esBye) return 'Ronda $numeroRonda: BYE';
    final prefix = esDoble ? '[×2] ' : '';
    return '${prefix}Ronda $numeroRonda: $anilloPropio VS $anilloRival (fila $filaPartidoRival)';
  }
}

/// Resultado completo del sorteo para un partido.
class PartidoResultado {
  /// ID del partido.
  final int partidoId;

  /// Nombre/dueño del partido.
  final String nombrePartido;

  /// Fila (1-based) de este partido en la tabla general.
  final int fila;

  /// Resultado por ronda.
  final List<RondaResultado> rondas;

  /// Filas (1-based) de los partidos compadres de este partido.
  final List<int> compadresFilas;

  const PartidoResultado({
    required this.partidoId,
    required this.nombrePartido,
    required this.fila,
    required this.rondas,
    this.compadresFilas = const [],
  });

  @override
  String toString() => 'Partido $nombrePartido (fila $fila): ${rondas.length} rondas';
}

/// Resultado completo del sorteo (todas las rondas).
class SorteoResultado {
  /// Nombre del derby.
  final String nombreDerby;

  /// Fecha del sorteo.
  final DateTime fecha;

  /// Número total de rondas generadas.
  final int rondasGeneradas;

  /// Resultados por partido (ordenados por fila).
  final List<PartidoResultado> partidos;

  /// Advertencias no bloqueantes (ej: partido impar sin emparejar).
  final List<String> advertencias;

  const SorteoResultado({
    required this.nombreDerby,
    required this.fecha,
    required this.rondasGeneradas,
    required this.partidos,
    this.advertencias = const [],
  });

  @override
  String toString() =>
      'Sorteo "$nombreDerby": ${partidos.length} partidos, $rondasGeneradas rondas';
}
