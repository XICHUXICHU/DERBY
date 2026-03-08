import 'enfrentamiento.dart';

/// Representa una ronda completa del derby.
/// Contiene N/2 enfrentamientos (donde N = partidos activos).
class Ronda {
  final int numero;               // 1..4
  final List<Enfrentamiento> enfrentamientos;
  final bool esRondaBase;         // true si es ronda 4 (gallos base)
  final DateTime? fechaCreacion;

  const Ronda({
    required this.numero,
    required this.enfrentamientos,
    this.esRondaBase = false,
    this.fechaCreacion,
  });

  /// Suma total de diferencias de peso en esta ronda.
  double get sumaDiferencias =>
      enfrentamientos.fold(0.0, (s, e) => s + e.diferenciaPeso);

  /// Cantidad de enfrentamientos.
  int get totalEnfrentamientos => enfrentamientos.length;

  /// ¿Todos los enfrentamientos tienen resultado?
  bool get completa =>
      enfrentamientos.every((e) => e.resultado != null);

  @override
  String toString() =>
      'Ronda(#$numero, enfrentamientos=$totalEnfrentamientos, '
      'base=$esRondaBase, sumaDiff=${sumaDiferencias.toStringAsFixed(1)}g)';
}
