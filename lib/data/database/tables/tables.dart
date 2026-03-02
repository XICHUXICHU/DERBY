import 'package:drift/drift.dart';

/// Tabla de Derbys.
class Derbys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().withLength(min: 1, max: 100)();
  DateTimeColumn get fechaCreacion =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get rondasTotales => integer().withDefault(const Constant(4))();
  IntColumn get puntosVictoria => integer().withDefault(const Constant(1))();
  IntColumn get puntosEmpate => integer().withDefault(const Constant(0))();
  IntColumn get puntosDerrota => integer().withDefault(const Constant(0))();
  IntColumn get posicionesPremio => integer().withDefault(const Constant(3))();
  TextColumn get estado =>
      text().withDefault(const Constant('configuracion'))();

  // ── Configuración de pesos (v3) ──
  /// Peso mínimo aceptado para gallos P.L. (gramos).
  RealColumn get pesoMinimo => real().withDefault(const Constant(1800.0))();

  /// Peso máximo aceptado para gallos P.L. (gramos).
  RealColumn get pesoMaximo => real().withDefault(const Constant(2500.0))();

  /// Peso específico del gallo base (gramos). 0 = sin restricción.
  RealColumn get pesoGalloBase => real().withDefault(const Constant(0.0))();

  /// En derbys de peso libre, ¿se pueden repetir contrincantes?
  BoolColumn get permitirRepeticiones =>
      boolean().withDefault(const Constant(false))();

  /// Diferencia máxima de peso permitida en peleas P.L. (gramos). 0 = sin límite.
  RealColumn get diferenciaMaxPeso =>
      real().withDefault(const Constant(80.0))();

  /// Validación estricta: si true, lanza error si no hay solución completa.
  BoolColumn get validacionEstricta =>
      boolean().withDefault(const Constant(true))();
}

/// Tabla de Partidos.
class Partidos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get derbyId => integer().references(Derbys, #id)();
  TextColumn get nombre => text().withLength(min: 1, max: 100)();
  TextColumn get responsable => text().nullable()();
  TextColumn get telefono => text().nullable()();
  TextColumn get estado => text().withDefault(const Constant('activo'))();
  IntColumn get puntos => integer().withDefault(const Constant(0))();
  BoolColumn get eliminado => boolean().withDefault(const Constant(false))();
  BoolColumn get depositoPagado =>
      boolean().withDefault(const Constant(false))();
  RealColumn get depositoCantidad => real().withDefault(const Constant(0.0))();

  /// True si es un partido comodín (entra cuando hay impar post-eliminación).
  BoolColumn get esComodin => boolean().withDefault(const Constant(false))();
}

/// Tabla de Gallos.
@DataClassName('GalloEntry')
class Gallos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get partidoId => integer().references(Partidos, #id)();
  TextColumn get anillo => text().unique()();
  RealColumn get pesoGramos => real()();
  BoolColumn get esBase => boolean().withDefault(const Constant(false))();
  TextColumn get color => text().nullable()();
  TextColumn get observaciones => text().nullable()();
}

/// Tabla de Compadres (relaciones prohibidas entre partidos).
@DataClassName('CompadreEntry')
class CompadresTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get derbyId => integer().references(Derbys, #id)();
  IntColumn get partidoIdA => integer().references(Partidos, #id)();
  IntColumn get partidoIdB => integer().references(Partidos, #id)();
  TextColumn get motivo => text().nullable()();

  @override
  String get tableName => 'compadres';
}

/// Tabla de Rondas.
class Rondas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get derbyId => integer().references(Derbys, #id)();
  IntColumn get numero => integer()();
  BoolColumn get esRondaBase => boolean().withDefault(const Constant(false))();
  DateTimeColumn get fechaCreacion =>
      dateTime().withDefault(currentDateAndTime)();

  /// IDs de partidos con BYE, separados por comas. Ejemplo: "3,7".
  TextColumn get byePartidos => text().withDefault(const Constant(''))();

  /// IDs de partidos con doble pelea, separados por comas. Ejemplo: "5".
  TextColumn get doblesPartidos => text().withDefault(const Constant(''))();
}

/// Tabla de Enfrentamientos.
class Enfrentamientos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get rondaId => integer().references(Rondas, #id)();
  IntColumn get galloAId => integer().references(Gallos, #id)();
  IntColumn get galloBId => integer().references(Gallos, #id)();
  RealColumn get diferenciaPeso => real()();
  TextColumn get resultado =>
      text().nullable()(); // ganoA, ganoB, empate, noPeleada
}
