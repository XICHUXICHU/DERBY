/// Modelo puro de dominio: Gallo
/// No depende de Flutter ni Drift.
class Gallo {
  final int id;
  final int partidoId;
  final String anillo;       // Identificador único del gallo (anillo/banda)
  final double pesoGramos;   // Peso en gramos para máxima precisión
  final bool esBase;         // true = gallo base (pelea en ronda 4)
  final String? color;
  final String? observaciones;

  const Gallo({
    required this.id,
    required this.partidoId,
    required this.anillo,
    required this.pesoGramos,
    required this.esBase,
    this.color,
    this.observaciones,
  });

  /// Diferencia absoluta de peso con otro gallo, en gramos.
  double diferenciaAbsoluta(Gallo otro) =>
      (pesoGramos - otro.pesoGramos).abs();

  Gallo copyWith({
    int? id,
    int? partidoId,
    String? anillo,
    double? pesoGramos,
    bool? esBase,
    String? color,
    String? observaciones,
  }) {
    return Gallo(
      id: id ?? this.id,
      partidoId: partidoId ?? this.partidoId,
      anillo: anillo ?? this.anillo,
      pesoGramos: pesoGramos ?? this.pesoGramos,
      esBase: esBase ?? this.esBase,
      color: color ?? this.color,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gallo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Gallo(id=$id, partido=$partidoId, anillo=$anillo, '
      'peso=${pesoGramos}g, base=$esBase)';
}
