import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Repositorio para operaciones CRUD de Derbys.
class DerbyRepository {
  final AppDatabase _db;

  DerbyRepository(this._db);

  /// Crear un nuevo derby con su configuración completa.
  Future<int> crear({
    required String nombre,
    int rondasTotales = 4,
    int puntosVictoria = 1,
    int puntosEmpate = 0,
    int puntosDerrota = 0,
    int posicionesPremio = 3,
    double pesoMinimo = 1800.0,
    double pesoMaximo = 2500.0,
    double pesoGalloBase = 0.0,
    bool permitirRepeticiones = false,
    double diferenciaMaxPeso = 80.0,
    bool validacionEstricta = true,
  }) {
    return _db.into(_db.derbys).insert(DerbysCompanion.insert(
      nombre: nombre,
      rondasTotales: Value(rondasTotales),
      puntosVictoria: Value(puntosVictoria),
      puntosEmpate: Value(puntosEmpate),
      puntosDerrota: Value(puntosDerrota),
      posicionesPremio: Value(posicionesPremio),
      pesoMinimo: Value(pesoMinimo),
      pesoMaximo: Value(pesoMaximo),
      pesoGalloBase: Value(pesoGalloBase),
      permitirRepeticiones: Value(permitirRepeticiones),
      diferenciaMaxPeso: Value(diferenciaMaxPeso),
      validacionEstricta: Value(validacionEstricta),
    ));
  }

  /// Obtener derby por ID.
  Future<Derby?> obtenerPorId(int id) {
    return (_db.select(_db.derbys)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
  }

  /// Listar todos los derbys.
  Future<List<Derby>> listarTodos() {
    return _db.select(_db.derbys).get();
  }

  /// Actualizar estado del derby.
  Future<int> actualizarEstado(int id, String estado) {
    return (_db.update(_db.derbys)..where((d) => d.id.equals(id)))
        .write(DerbysCompanion(estado: Value(estado)));
  }

  /// Actualizar la configuración completa de un derby.
  Future<int> actualizarConfig({
    required int id,
    required String nombre,
    required int rondasTotales,
    required int puntosVictoria,
    required int puntosEmpate,
    required int puntosDerrota,
    required int posicionesPremio,
    required double pesoMinimo,
    required double pesoMaximo,
    required double pesoGalloBase,
    required bool permitirRepeticiones,
    required double diferenciaMaxPeso,
    required bool validacionEstricta,
  }) {
    return (_db.update(_db.derbys)..where((d) => d.id.equals(id))).write(
      DerbysCompanion(
        nombre: Value(nombre),
        rondasTotales: Value(rondasTotales),
        puntosVictoria: Value(puntosVictoria),
        puntosEmpate: Value(puntosEmpate),
        puntosDerrota: Value(puntosDerrota),
        posicionesPremio: Value(posicionesPremio),
        pesoMinimo: Value(pesoMinimo),
        pesoMaximo: Value(pesoMaximo),
        pesoGalloBase: Value(pesoGalloBase),
        permitirRepeticiones: Value(permitirRepeticiones),
        diferenciaMaxPeso: Value(diferenciaMaxPeso),
        validacionEstricta: Value(validacionEstricta),
      ),
    );
  }

  /// Eliminar derby y todos sus datos relacionados (en transacción).
  Future<void> eliminar(int id) async {
    await _db.transaction(() async {
      // Obtener rondas del derby para eliminar enfrentamientos
      final rondas = await (_db.select(_db.rondas)
            ..where((r) => r.derbyId.equals(id)))
          .get();
      for (final ronda in rondas) {
        await (_db.delete(_db.enfrentamientos)
              ..where((e) => e.rondaId.equals(ronda.id)))
            .go();
      }
      // Eliminar rondas
      await (_db.delete(_db.rondas)..where((r) => r.derbyId.equals(id))).go();
      // Eliminar compadres
      await (_db.delete(_db.compadresTable)
            ..where((c) => c.derbyId.equals(id)))
          .go();
      // Obtener partidos para eliminar gallos
      final partidos = await (_db.select(_db.partidos)
            ..where((p) => p.derbyId.equals(id)))
          .get();
      for (final partido in partidos) {
        await (_db.delete(_db.gallos)
              ..where((g) => g.partidoId.equals(partido.id)))
            .go();
      }
      // Eliminar partidos
      await (_db.delete(_db.partidos)..where((p) => p.derbyId.equals(id))).go();
      // Eliminar derby
      await (_db.delete(_db.derbys)..where((d) => d.id.equals(id))).go();
    });
  }
}
