import '../../domain/entities/partido.dart';
import '../../domain/entities/ronda.dart';
import '../../domain/entities/enfrentamiento.dart';
import '../../engine/derby_engine.dart';

/// Caso de uso: Registrar el resultado de una pelea.
///
/// Actualiza enfrentamiento con resultado y recalcula puntos.
class RegistrarResultado {
  final DerbyEngine _engine;

  const RegistrarResultado(this._engine);

  /// Registra el [resultado] en el [enfrentamiento] y recalcula
  /// los puntos de todos los [partidos] para la [ronda] dada.
  ///
  /// Retorna la lista de partidos con puntos actualizados.
  List<Partido> ejecutar({
    required List<Partido> partidos,
    required Ronda ronda,
    required int enfrentamientoId,
    required ResultadoPelea resultado,
  }) {
    // Actualizar el enfrentamiento con el resultado
    final enfrentamientosActualizados = ronda.enfrentamientos.map((e) {
      if (e.id == enfrentamientoId) {
        return e.conResultado(resultado);
      }
      return e;
    }).toList();

    final rondaActualizada = Ronda(
      numero: ronda.numero,
      enfrentamientos: enfrentamientosActualizados,
      esRondaBase: ronda.esRondaBase,
      fechaCreacion: ronda.fechaCreacion,
    );

    // Recalcular puntos
    return _engine.actualizarPuntos(partidos, rondaActualizada);
  }
}
