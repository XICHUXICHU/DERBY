import 'gallo.dart';

/// Resultado de un enfrentamiento individual en una ronda.
class Enfrentamiento {
  final int id;
  final int rondaNumero;
  final Gallo galloA;
  final Gallo? galloB;
  final double diferenciaPeso; // |pesoA - pesoB|
  final ResultadoPelea? resultado;
  final bool esManual; // Identifica si la pelea fue armada a mano

  const Enfrentamiento({
    required this.id,
    required this.rondaNumero,
    required this.galloA,
    this.galloB,
    required this.diferenciaPeso,
    this.resultado,
    this.esManual = false,
  });

  /// Verifica que los gallos no sean del mismo partido y existan.
  bool get esValido {
    if (galloB == null) return false;
    return galloA.partidoId != galloB!.partidoId;
  }

  Enfrentamiento conResultado(ResultadoPelea resultado) {
    return Enfrentamiento(
      id: id,
      rondaNumero: rondaNumero,
      galloA: galloA,
      galloB: galloB,
      diferenciaPeso: diferenciaPeso,
      resultado: resultado,
      esManual: esManual,
    );
  }

  @override
  String toString() =>
      'Enfrentamiento(ronda=$rondaNumero, '
      '${galloA.anillo} vs ${galloB?.anillo ?? 'HUECO'}, '
      'diff=${diferenciaPeso}g, resultado=$resultado, manual=$esManual)';
}

/// Resultado posible de una pelea.
enum ResultadoPelea {
  ganoA,    // Ganó gallo A
  ganoB,    // Ganó gallo B
  empate,   // Empate (tablas)
  noPeleada, // No se peleó (walkover, etc.)
}
