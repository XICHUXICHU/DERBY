import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../domain/domain.dart' as domain;

/// Repositorio para relaciones de compadres.
class CompadresRepository {
  final AppDatabase _db;

  CompadresRepository(this._db);

  /// Crear relación de compadres.
  Future<int> crear({
    required int derbyId,
    required int partidoIdA,
    required int partidoIdB,
    String? motivo,
  }) {
    return _db.into(_db.compadresTable).insert(CompadresTableCompanion.insert(
      derbyId: derbyId,
      partidoIdA: partidoIdA,
      partidoIdB: partidoIdB,
      motivo: Value(motivo),
    ));
  }

  /// Listar compadres de un derby.
  Future<List<CompadreEntry>> listarPorDerby(int derbyId) {
    return (_db.select(_db.compadresTable)
          ..where((c) => c.derbyId.equals(derbyId)))
        .get();
  }

  /// Verificar si dos partidos son compadres.
  Future<bool> sonCompadres(int derbyId, int partidoA, int partidoB) async {
    final query = _db.select(_db.compadresTable)
      ..where((c) =>
          c.derbyId.equals(derbyId) &
          ((c.partidoIdA.equals(partidoA) & c.partidoIdB.equals(partidoB)) |
              (c.partidoIdA.equals(partidoB) & c.partidoIdB.equals(partidoA))));
    final result = await query.get();
    return result.isNotEmpty;
  }

  /// Eliminar relación de compadres.
  Future<int> eliminar(int id) {
    return (_db.delete(_db.compadresTable)..where((c) => c.id.equals(id))).go();
  }

  /// Convertir a dominio.
  domain.Compadres toDomain(CompadreEntry c) {
    return domain.Compadres(
      id: c.id,
      partidoIdA: c.partidoIdA,
      partidoIdB: c.partidoIdB,
      motivo: c.motivo,
    );
  }
}
