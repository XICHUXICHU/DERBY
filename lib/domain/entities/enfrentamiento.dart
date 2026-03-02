import 'gallo.dart';

/// Resultado de un enfrentamiento individual en una ronda.
class Enfrentamiento {
  final int id;
  final int rondaNumero;
  final Gallo galloA;
  final Gallo galloB;
  final double diferenciaPeso; // |pesoA - pesoB|
  final ResultadoPelea? resultado;

  const Enfrentamiento({
    required this.id,
    required this.rondaNumero,
    required this.galloA,
    required this.galloB,
    required this.diferenciaPeso,
    this.resultado,
  });

  /// Verifica que los gallos no sean del mismo partido.
  bool get esValido => galloA.partidoId != galloB.partidoId;

  Enfrentamiento conResultado(ResultadoPelea resultado) {
    return Enfrentamiento(
      id: id,
      rondaNumero: rondaNumero,
      galloA: galloA,
      galloB: galloB,
      diferenciaPeso: diferenciaPeso,
      resultado: resultado,
    );
  }

  @override
  String toString() =>
      'Enfrentamiento(ronda=$rondaNumero, '
      '${galloA.anillo} vs ${galloB.anillo}, '
      'diff=${diferenciaPeso}g, resultado=$resultado)';
}

/// Resultado posible de una pelea.
enum ResultadoPelea {
  ganoA,    // Ganó gallo A
  ganoB,    // Ganó gallo B
  empate,   // Empate (tablas)
  noPeleada, // No se peleó (walkover, etc.)
}
