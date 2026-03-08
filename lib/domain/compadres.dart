/// Relación de compadres: dos partidos que NO pueden enfrentarse.
/// Restricción dura e inviolable del sistema.
class Compadres {
  final int id;
  final int partidoIdA;
  final int partidoIdB;
  final String? motivo;

  const Compadres({
    required this.id,
    required this.partidoIdA,
    required this.partidoIdB,
    this.motivo,
  });

  /// Verifica si un par de partidos está bloqueado por esta relación.
  bool bloquea(int p1, int p2) =>
      (partidoIdA == p1 && partidoIdB == p2) ||
      (partidoIdA == p2 && partidoIdB == p1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Compadres && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Compadres(partido $partidoIdA <-> $partidoIdB, motivo=$motivo)';
}
