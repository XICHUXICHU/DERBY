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
  final int puntosVictoria;       // Puntos por victoria (default: 1)
  final int puntosEmpate;         // Puntos por empate (default: 0)
  final int puntosDerrota;        // Puntos por derrota (default: 0)
  final EstadoDerby estado;

  const Derby({
    required this.id,
    required this.nombre,
    required this.fechaCreacion,
    required this.partidos,
    this.rondas = const [],
    this.rondasTotales = 4,
    this.puntosVictoria = 1,
    this.puntosEmpate = 0,
    this.puntosDerrota = 0,
    this.estado = EstadoDerby.configuracion,
  });

  int get rondaActual => rondas.length;
  int get rondasRestantes => rondasTotales - rondaActual;
  bool get finalizado => rondaActual >= rondasTotales;

  List<Partido> get partidosActivos =>
      partidos.where((p) => p.estado == EstadoPartido.activo && !p.eliminado).toList();

  @override
  String toString() =>
      'Derby(id=$id, nombre=$nombre, ronda=${rondaActual}/$rondasTotales, '
      'partidos=${partidos.length}, activos=${partidosActivos.length})';
}

enum EstadoDerby {
  configuracion,  // Registrando partidos y gallos
  enCurso,        // Peleas activas
  finalizado,     // Todas las rondas completadas
}
