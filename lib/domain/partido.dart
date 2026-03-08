/// Modelo puro de dominio: Partido
/// Un partido tiene exactamente 4 gallos: 3 libres + 1 base.
class Partido {
  final int id;
  final String nombre;
  final String? responsable;    // Nombre del dueño/gallero
  final String? telefono;
  final EstadoPartido estado;
  final int puntos;             // Puntos acumulados
  final bool eliminado;         // True si fue eliminado matemáticamente

  const Partido({
    required this.id,
    required this.nombre,
    this.responsable,
    this.telefono,
    this.estado = EstadoPartido.activo,
    this.puntos = 0,
    this.eliminado = false,
  });

  /// Puntos máximos posibles = rondas restantes × puntosVictoria
  int puntosMaximosPosibles(int rondasRestantes, int puntosVictoria) =>
      puntos + (rondasRestantes * puntosVictoria);

  Partido copyWith({
    int? id,
    String? nombre,
    String? responsable,
    String? telefono,
    EstadoPartido? estado,
    int? puntos,
    bool? eliminado,
  }) {
    return Partido(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      responsable: responsable ?? this.responsable,
      telefono: telefono ?? this.telefono,
      estado: estado ?? this.estado,
      puntos: puntos ?? this.puntos,
      eliminado: eliminado ?? this.eliminado,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Partido && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Partido(id=$id, nombre=$nombre, puntos=$puntos, '
      'eliminado=$eliminado)';
}

enum EstadoPartido {
  activo,
  eliminado,
  descalificado,
}
