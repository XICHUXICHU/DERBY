import '../domain/domain.dart';

/// Resultado del análisis de eliminación para un partido.
class AnalisisEliminacion {
  final int partidoId;
  final int puntosActuales;
  final int puntosMaximosPosibles;
  final int umbralPremio;         // Mínimo de puntos para zona de premio
  final bool eliminado;

  const AnalisisEliminacion({
    required this.partidoId,
    required this.puntosActuales,
    required this.puntosMaximosPosibles,
    required this.umbralPremio,
    required this.eliminado,
  });

  @override
  String toString() =>
      'Eliminacion(partido=$partidoId, pts=$puntosActuales, '
      'max=$puntosMaximosPosibles, umbral=$umbralPremio, '
      'eliminado=$eliminado)';
}

/// Servicio de eliminación matemática.
///
/// Después de cada ronda, calcula si un partido puede
/// todavía alcanzar la zona de premio. Si no puede,
/// lo marca como eliminado y lo excluye de futuros emparejamientos.
///
/// Puro Dart. No depende de Flutter ni Drift.
class EliminationService {
  /// Analiza todos los partidos y determina cuáles están eliminados.
  ///
  /// [partidos]: todos los partidos del derby.
  /// [rondasRestantes]: rondas aún por jugar.
  /// [puntosVictoria]: puntos otorgados por victoria.
  /// [posicionesPremio]: cuántos partidos entran en zona de premio.
  ///
  /// Retorna lista de análisis, uno por partido activo.
  List<AnalisisEliminacion> analizar({
    required List<Partido> partidos,
    required int rondasRestantes,
    required int puntosVictoria,
    required int posicionesPremio,
  }) {
    if (rondasRestantes <= 0 || partidos.isEmpty) return [];

    // Calcular el umbral: el punto mínimo para entrar en zona de premio.
    // Es el puntaje del partido en posición posicionesPremio
    // asumiendo el PEOR escenario para cada uno.
    final puntosMaximos = partidos
        .where((p) => p.estado == EstadoPartido.activo)
        .map((p) => p.puntosMaximosPosibles(rondasRestantes, puntosVictoria))
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Descendente

    // El umbral es el puntaje máximo del partido en la posición premio+1
    // (el primero que quedaría fuera si todos los de arriba ganan todo).
    // Usamos un enfoque conservador: un partido está eliminado solo si
    // incluso ganando todo, NO puede superar al partido en la última
    // posición de premio.
    final umbral = posicionesPremio <= puntosMaximos.length
        ? puntosMaximos[posicionesPremio - 1]
        : 0;

    final resultados = <AnalisisEliminacion>[];

    for (final partido in partidos) {
      if (partido.estado != EstadoPartido.activo) continue;

      final maxPosible =
          partido.puntosMaximosPosibles(rondasRestantes, puntosVictoria);

      // Calculamos cuántos partidos tienen un puntaje mínimo garantizado
      // superior al máximo posible de este partido.
      final partidosMejores = partidos
          .where((p) =>
              p.id != partido.id &&
              p.estado == EstadoPartido.activo &&
              p.puntos > maxPosible) // Puntos actuales ya mayores que su max
          .length;

      // Si hay más partidos con puntos actuales superiores a su máximo
      // posible que las posiciones de premio, está eliminado.
      final eliminado = partidosMejores >= posicionesPremio;

      resultados.add(AnalisisEliminacion(
        partidoId: partido.id,
        puntosActuales: partido.puntos,
        puntosMaximosPosibles: maxPosible,
        umbralPremio: umbral,
        eliminado: eliminado,
      ));
    }

    return resultados;
  }

  /// Versión simplificada: retorna solo IDs de partidos eliminados.
  Set<int> partidosEliminados({
    required List<Partido> partidos,
    required int rondasRestantes,
    required int puntosVictoria,
    required int posicionesPremio,
  }) {
    return analizar(
      partidos: partidos,
      rondasRestantes: rondasRestantes,
      puntosVictoria: puntosVictoria,
      posicionesPremio: posicionesPremio,
    )
        .where((a) => a.eliminado)
        .map((a) => a.partidoId)
        .toSet();
  }
}
