/// Value Object: Peso de un gallo.
///
/// Encapsula la lógica de peso en gramos con validación.
/// Inmutable, sin dependencias externas.
class Peso {
  final double gramos;

  const Peso(this.gramos);

  /// Peso mínimo aceptable (en gramos).
  static const double minimo = 1500.0;

  /// Peso máximo aceptable (en gramos).
  static const double maximo = 3500.0;

  /// Valida que el peso esté en rango aceptable.
  bool get esValido => gramos >= minimo && gramos <= maximo;

  /// Diferencia absoluta con otro peso.
  double diferenciaAbsoluta(Peso otro) => (gramos - otro.gramos).abs();

  /// Peso en kilogramos.
  double get kilogramos => gramos / 1000.0;

  /// Peso en libras (aproximado).
  double get libras => gramos / 453.592;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Peso && runtimeType == other.runtimeType && gramos == other.gramos;

  @override
  int get hashCode => gramos.hashCode;

  @override
  String toString() => '${gramos.toStringAsFixed(0)}g';
}
