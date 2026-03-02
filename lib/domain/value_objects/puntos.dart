/// Value Object: Puntos de un partido.
///
/// Encapsula el puntaje con lógica de cálculo.
/// Inmutable, sin dependencias externas.
class Puntos {
  final int valor;

  const Puntos(this.valor);

  static const Puntos cero = Puntos(0);

  /// Suma puntos.
  Puntos operator +(Puntos otros) => Puntos(valor + otros.valor);

  /// Resta puntos.
  Puntos operator -(Puntos otros) => Puntos(valor - otros.valor);

  /// Comparar.
  bool operator >(Puntos otros) => valor > otros.valor;
  bool operator <(Puntos otros) => valor < otros.valor;
  bool operator >=(Puntos otros) => valor >= otros.valor;
  bool operator <=(Puntos otros) => valor <= otros.valor;

  /// Puntos máximos posibles dados victoria por ronda.
  Puntos maximoPosible(int rondasRestantes, int puntosVictoria) =>
      Puntos(valor + (rondasRestantes * puntosVictoria));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Puntos && runtimeType == other.runtimeType && valor == other.valor;

  @override
  int get hashCode => valor.hashCode;

  @override
  String toString() => '$valor pts';
}
