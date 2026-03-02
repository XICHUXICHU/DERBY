import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../domain/domain.dart' as domain;

/// Repositorio para operaciones CRUD de Gallos.
class GalloRepository {
  final AppDatabase _db;

  GalloRepository(this._db);

  /// Crear un nuevo gallo.
  Future<int> crear({
    required int partidoId,
    required String anillo,
    required double pesoGramos,
    bool esBase = false,
    String? color,
    String? observaciones,
  }) {
    return _db.into(_db.gallos).insert(GallosCompanion.insert(
      partidoId: partidoId,
      anillo: anillo,
      pesoGramos: pesoGramos,
      esBase: Value(esBase),
      color: Value(color),
      observaciones: Value(observaciones),
    ));
  }

  /// Obtener gallos de un partido.
  Future<List<GalloEntry>> listarPorPartido(int partidoId) {
    return (_db.select(_db.gallos)
          ..where((g) => g.partidoId.equals(partidoId))
          ..orderBy([(g) => OrderingTerm.asc(g.pesoGramos)]))
        .get();
  }

  /// Obtener todos los gallos de un derby (mediante los partidos).
  Future<List<GalloEntry>> listarPorDerby(int derbyId) async {
    final query = _db.select(_db.gallos).join([
      innerJoin(
        _db.partidos,
        _db.partidos.id.equalsExp(_db.gallos.partidoId),
      ),
    ])
      ..where(_db.partidos.derbyId.equals(derbyId))
      ..orderBy([OrderingTerm.asc(_db.gallos.pesoGramos)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(_db.gallos)).toList();
  }

  /// Obtener gallo por ID.
  Future<GalloEntry?> obtenerPorId(int id) {
    return (_db.select(_db.gallos)..where((g) => g.id.equals(id)))
        .getSingleOrNull();
  }

  /// Obtener gallo por anillo.
  Future<GalloEntry?> obtenerPorAnillo(String anillo) {
    return (_db.select(_db.gallos)..where((g) => g.anillo.equals(anillo)))
        .getSingleOrNull();
  }

  /// Actualizar gallo.
  Future<int> actualizar({
    required int id,
    String? anillo,
    double? pesoGramos,
    bool? esBase,
    String? color,
    String? observaciones,
  }) {
    return (_db.update(_db.gallos)..where((g) => g.id.equals(id))).write(
      GallosCompanion(
        anillo: anillo != null ? Value(anillo) : const Value.absent(),
        pesoGramos:
            pesoGramos != null ? Value(pesoGramos) : const Value.absent(),
        esBase: esBase != null ? Value(esBase) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
        observaciones:
            observaciones != null ? Value(observaciones) : const Value.absent(),
      ),
    );
  }

  /// Eliminar gallo.
  Future<int> eliminar(int id) {
    return (_db.delete(_db.gallos)..where((g) => g.id.equals(id))).go();
  }

  /// Contar gallos de un partido.
  Future<int> contarPorPartido(int partidoId) async {
    final count = _db.gallos.id.count();
    final query = _db.selectOnly(_db.gallos)
      ..addColumns([count])
      ..where(_db.gallos.partidoId.equals(partidoId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Convertir Drift GalloEntry a dominio.
  domain.Gallo toDomain(GalloEntry g) {
    return domain.Gallo(
      id: g.id,
      partidoId: g.partidoId,
      anillo: g.anillo,
      pesoGramos: g.pesoGramos,
      esBase: g.esBase,
      color: g.color,
      observaciones: g.observaciones,
    );
  }
}
