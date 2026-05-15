/// Excepciones controladas del motor de derby.

/// Base para todas las excepciones del derby.
abstract class DerbyException implements Exception {
  final String mensaje;
  final String? detalle;

  const DerbyException(this.mensaje, [this.detalle]);

  @override
  String toString() => '$runtimeType: $mensaje${detalle != null ? ' ($detalle)' : ''}';
}

/// No se puede encontrar un matching válido.
class MatchingImposibleException extends DerbyException {
  final int rondaNumero;
  final int gallosDisponibles;
  final int restriccionesActivas;

  const MatchingImposibleException({
    required this.rondaNumero,
    required this.gallosDisponibles,
    required this.restriccionesActivas,
    String? detalle,
  }) : super('No se puede generar matching válido para ronda $rondaNumero', detalle);
}

/// Violación de restricción de compadres.
class CompadresVioladosException extends DerbyException {
  final int partidoA;
  final int partidoB;

  const CompadresVioladosException({
    required this.partidoA,
    required this.partidoB,
  }) : super('Partidos $partidoA y $partidoB son compadres y no pueden enfrentarse');
}

/// Violación de integridad: gallo ya peleó.
class GalloYaPeleoException extends DerbyException {
  final int galloId;
  final int rondaAnterior;

  const GalloYaPeleoException({
    required this.galloId,
    required this.rondaAnterior,
  }) : super('Gallo $galloId ya peleó en ronda $rondaAnterior');
}

/// Partido no tiene gallos suficientes.
class PartidoIncompleto extends DerbyException {
  final int partidoId;
  final int gallosRegistrados;

  const PartidoIncompleto({
    required this.partidoId,
    required this.gallosRegistrados,
  }) : super('Partido $partidoId tiene solo $gallosRegistrados gallos (necesita 4)');
}

/// No hay solución que cubra todos los partidos activos.
class RondaIncompletaException extends DerbyException {
  final int partidosSinEmparejar;
  final List<int> idsNoEmparejados;

  const RondaIncompletaException({
    required this.partidosSinEmparejar,
    required this.idsNoEmparejados,
    String? detalle,
  }) : super('$partidosSinEmparejar partidos no pudieron emparejarse', detalle);
}

/// Validación de datos de entrada.
class ValidacionException extends DerbyException {
  const ValidacionException(String mensaje, [String? detalle])
      : super(mensaje, detalle);
}
