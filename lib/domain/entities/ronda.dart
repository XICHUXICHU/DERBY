import 'enfrentamiento.dart';

/// Representa una ronda completa del derby.
/// Contiene N/2 enfrentamientos (donde N = partidos activos).
///
/// Si hay número impar de partidos activos:
/// - Rondas 1-2 (P.L.): un partido pelea **dos veces** con 2 gallos
///   distintos contra 2 rivales diferentes (doble pelea).
/// - Rondas 3+ con impar post-eliminación: un partido **comodín**
///   registrado por el usuario completa los enfrentamientos.
/// - Ronda base: si hay impar, el sobrante no pelea (sin puntos gratis).
class Ronda {
  final int numero; // 1..4
  final List<Enfrentamiento> enfrentamientos;
  final bool esRondaBase; // true si es ronda 4 (gallos base)
  final DateTime? fechaCreacion;

  /// IDs de partidos que recibieron bye (descanso) en esta ronda.
  /// Se mantiene por compatibilidad con derbys previos.
  final List<int> partidosBye;

  /// IDs de partidos que pelean **dos veces** en esta ronda.
  /// Aplicable solo en rondas 1-2 (P.L.) con número impar de activos.
  /// El partido usa 2 gallos P.L. distintos en 2 enfrentamientos.
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
