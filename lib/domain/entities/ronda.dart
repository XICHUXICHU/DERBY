import 'enfrentamiento.dart';

/// Representa una ronda completa del derby.
/// Contiene N/2 enfrentamientos (donde N = partidos activos).
///
/// Si hay número impar de partidos activos:
/// - Primeras 2 rondas: **un solo** partido pelea dos veces con
///   2 gallos distintos contra 2 rivales diferentes (doble pelea).
///   Máximo 1 partido doble por ronda.
/// - Rondas posteriores con impar post-eliminación: un partido
///   **comodín** registrado por el usuario completa los enfrentamientos.
/// - Si no hay comodín, sobrante no pelea (sin puntos gratis).
class Ronda {
  final int numero; // 1..rondasTotales
  final List<Enfrentamiento> enfrentamientos;
  final bool
  esRondaBase; // Deprecated: siempre false. Se mantiene por compatibilidad.
  final DateTime? fechaCreacion;

  /// IDs de partidos que recibieron bye (descanso) en esta ronda.
  /// Se mantiene por compatibilidad con derbys previos.
  final List<int> partidosBye;

  /// IDs de partidos que pelean **dos veces** en esta ronda.
  /// Máximo 1 partido por ronda. Aplicable en las primeras rondas P.L.
  /// con número impar de activos. El partido usa 2 gallos P.L. distintos
  /// en 2 enfrentamientos contra 2 rivales diferentes.
  final List<int> partidosDobles;

  const Ronda({
    required this.numero,
    required this.enfrentamientos,
    this.esRondaBase = false,
    this.fechaCreacion,
    this.partidosBye = const [],
    this.partidosDobles = const [],
  });

  /// ¿Algún partido tiene bye en esta ronda?
  bool get tieneBye => partidosBye.isNotEmpty;

  /// ¿Algún partido pelea doble en esta ronda?
  bool get tieneDoble => partidosDobles.isNotEmpty;

  /// Suma total de diferencias de peso en esta ronda.
  double get sumaDiferencias =>
      enfrentamientos.fold(0.0, (s, e) => s + e.diferenciaPeso);

  /// Cantidad de enfrentamientos.
  int get totalEnfrentamientos => enfrentamientos.length;

  /// ¿Todos los enfrentamientos tienen resultado?
  bool get completa => enfrentamientos.every((e) => e.resultado != null);

  @override
  String toString() =>
      'Ronda(#$numero, enfrentamientos=$totalEnfrentamientos, '
      'base=$esRondaBase, sumaDiff=${sumaDiferencias.toStringAsFixed(1)}g)';
}
