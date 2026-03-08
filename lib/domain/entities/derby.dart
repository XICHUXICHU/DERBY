import 'partido.dart';
import 'ronda.dart';

/// Estado completo de un derby.
class Derby {
  final int id;
  final String nombre;
  final DateTime fechaCreacion;
  final List<Partido> partidos;
  final List<Ronda> rondas;
  final int rondasTotales;        // Normalmente 4
  final int puntosVictoria;       // Puntos por victoria (default: 2)
  final int puntosEmpate;         // Puntos por tablas (default: 1)
  final int puntosDerrota;        // Puntos por derrota (default: 0)
  final double pesoMinimo;        // Peso mínimo P.L. (gramos)
  final double pesoMaximo;        // Peso máximo P.L. (gramos)
  final double pesoGalloBase;     // Peso gallo base (0 = sin restricción)
  final bool permitirRepeticiones; // Repetir contrincantes en peso libre
  final double diferenciaMaxPeso;  // Dif. máx. peso P.L. (0 = sin límite)
  final bool validacionEstricta;   // Falla si no hay solución completa
  final EstadoDerby estado;

  const Derby({
    required this.id,
    required this.nombre,
    required this.fechaCreacion,
    required this.partidos,
    this.rondas = const [],
    this.rondasTotales = 4,
    this.puntosVictoria = 2,
    this.puntosEmpate = 1,
    this.puntosDerrota = 0,
    this.pesoMinimo = 1800.0,
    this.pesoMaximo = 2500.0,
    this.pesoGalloBase = 0.0,
    this.permitirRepeticiones = false,
    this.diferenciaMaxPeso = 80.0,
    this.validacionEstricta = true,
    this.estado = EstadoDerby.configuracion,
  });

  int get rondaActual => rondas.length;
  int get rondasRestantes => rondasTotales - rondaActual;
  bool get finalizado => rondaActual >= rondasTotales;

  List<Partido> get partidosActivos =>
      partidos.where((p) => p.estado == EstadoPartido.activo && !p.eliminado).toList();

  @override
  String toString() =>
      'Derby(id=$id, nombre=$nombre, ronda=$rondaActual/$rondasTotales, '
      'partidos=${partidos.length}, activos=${partidosActivos.length})';
}

enum EstadoDerby {
  configuracion,  // Registrando partidos y gallos
  enCurso,        // Peleas activas
  finalizado,     // Todas las rondas completadas
}
