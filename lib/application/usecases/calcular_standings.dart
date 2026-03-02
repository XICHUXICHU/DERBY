import '../../domain/entities/partido.dart';
import '../../engine/elimination/elimination_service.dart';
import '../../engine/derby_engine.dart';

/// Resultado de un standing: posición en la tabla.
class StandingEntry {
  final int posicion;
  final Partido partido;
  final bool eliminado;
  final int puntosMaximosPosibles;

  const StandingEntry({
    required this.posicion,
    required this.partido,
    required this.eliminado,
    required this.puntosMaximosPosibles,
  });

  @override
  String toString() =>
      '#$posicion ${partido.nombre}: ${partido.puntos}pts'
      '${eliminado ? " [ELIMINADO]" : ""}';
}

/// Caso de uso: Calcular la tabla de posiciones (standings).
///
/// Ordena partidos por puntos y calcula eliminaciones matemáticas.
class CalcularStandings {
  final DerbyEngine _engine;

  const CalcularStandings(this._engine);

  /// Calcula la tabla de posiciones actual.
  ///
  /// Retorna lista ordenada de mayor a menor puntaje.
  List<StandingEntry> ejecutar({
    required List<Partido> partidos,
    required int rondasRestantes,
  }) {
    // Obtener análisis de eliminación
    final analisis = _engine.calcularEliminaciones(
      partidos: partidos,
      rondasRestantes: rondasRestantes,
    );

    // Crear mapa de eliminaciones
    final eliminadosMap = <int, AnalisisEliminacion>{};
    for (final a in analisis) {
      eliminadosMap[a.partidoId] = a;
    }

    // Ordenar por puntos descendente, luego por nombre
    final ordenados = List<Partido>.from(partidos)
      ..sort((a, b) {
        final cmp = b.puntos.compareTo(a.puntos);
        if (cmp != 0) return cmp;
        return a.nombre.compareTo(b.nombre);
      });

    final standings = <StandingEntry>[];
    for (var i = 0; i < ordenados.length; i++) {
      final p = ordenados[i];
      final info = eliminadosMap[p.id];
      standings.add(StandingEntry(
        posicion: i + 1,
        partido: p,
        eliminado: info?.eliminado ?? false,
        puntosMaximosPosibles: info?.puntosMaximosPosibles ?? p.puntos,
      ));
    }

    return standings;
  }
}
