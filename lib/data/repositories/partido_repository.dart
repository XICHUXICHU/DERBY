import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../domain/domain.dart' as domain;

/// Repositorio para operaciones CRUD de Partidos.
class PartidoRepository {
  final AppDatabase _db;

  PartidoRepository(this._db);

  /// Crear un nuevo partido.
  Future<int> crear({
    required int derbyId,
    required String nombre,
    String? responsable,
    String? telefono,
    bool depositoPagado = false,
    double depositoCantidad = 0.0,
    bool esComodin = false,
  }) {
    return _db
        .into(_db.partidos)
        .insert(
          PartidosCompanion.insert(
            derbyId: derbyId,
            nombre: nombre,
            responsable: Value(responsable),
            telefono: Value(telefono),
            depositoPagado: Value(depositoPagado),
            depositoCantidad: Value(depositoCantidad),
            esComodin: Value(esComodin),
          ),
        );
  }

  /// Obtener partidos de un derby.
  Future<List<Partido>> listarPorDerby(int derbyId) {
    return (_db.select(_db.partidos)
          ..where((p) => p.derbyId.equals(derbyId))
          ..orderBy([(p) => OrderingTerm.asc(p.nombre)]))
        .get();
  }

  /// Obtener partido por ID.
  Future<Partido?> obtenerPorId(int id) {
    return (_db.select(
      _db.partidos,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Actualizar puntos de un partido.
  Future<int> actualizarPuntos(int id, int puntos) {
    return (_db.update(_db.partidos)..where((p) => p.id.equals(id))).write(
      PartidosCompanion(puntos: Value(puntos)),
    );
  }

  /// Marcar partido como eliminado.
  Future<int> marcarEliminado(int id) {
    return (_db.update(_db.partidos)..where((p) => p.id.equals(id))).write(
      const PartidosCompanion(
        eliminado: Value(true),
        estado: Value('eliminado'),
      ),
    );
  }

  /// Actualizar datos del partido.
  Future<int> actualizar({
    required int id,
    String? nombre,
    String? responsable,
    String? telefono,
    bool? depositoPagado,
    double? depositoCantidad,
  }) {
    return (_db.update(_db.partidos)..where((p) => p.id.equals(id))).write(
      PartidosCompanion(
        nombre: nombre != null ? Value(nombre) : const Value.absent(),
        responsable: responsable != null
            ? Value(responsable)
            : const Value.absent(),
        telefono: telefono != null ? Value(telefono) : const Value.absent(),
        depositoPagado: depositoPagado != null
            ? Value(depositoPagado)
            : const Value.absent(),
        depositoCantidad: depositoCantidad != null
            ? Value(depositoCantidad)
            : const Value.absent(),
      ),
    );
  }

  /// Eliminar partido, sus gallos, compadres y enfrentamientos asociados.
  Future<void> eliminar(int id) async {
    await _db.transaction(() async {
      // 1. Obtener IDs de gallos del partido
      final gallosDelPartido = await (_db.select(
        _db.gallos,
      )..where((g) => g.partidoId.equals(id))).get();
      final galloIds = gallosDelPartido.map((g) => g.id).toSet();

      // 2. Eliminar enfrentamientos donde participe algún gallo de este partido
      if (galloIds.isNotEmpty) {
        await (_db.delete(_db.enfrentamientos)..where(
              (e) => e.galloAId.isIn(galloIds) | e.galloBId.isIn(galloIds),
            ))
            .go();
      }

      // 3. Eliminar compadres que referencian este partido
      await (_db.delete(
        _db.compadresTable,
      )..where((c) => c.partidoIdA.equals(id) | c.partidoIdB.equals(id))).go();

      // 4. Eliminar gallos del partido
      await (_db.delete(_db.gallos)..where((g) => g.partidoId.equals(id))).go();

      // 5. Eliminar el partido
      await (_db.delete(_db.partidos)..where((p) => p.id.equals(id))).go();
    });
  }

  /// Convertir Drift Partido a dominio.
  domain.Partido toDomain(Partido p) {
    return domain.Partido(
      id: p.id,
      nombre: p.nombre,
      responsable: p.responsable,
      telefono: p.telefono,
      estado: _parseEstado(p.estado),
      puntos: p.puntos,
      eliminado: p.eliminado,
      depositoPagado: p.depositoPagado,
      depositoCantidad: p.depositoCantidad,
      esComodin: p.esComodin,
    );
  }

  domain.EstadoPartido _parseEstado(String estado) {
    switch (estado) {
      case 'activo':
        return domain.EstadoPartido.activo;
      case 'eliminado':
        return domain.EstadoPartido.eliminado;
      case 'descalificado':
        return domain.EstadoPartido.descalificado;
      default:
        return domain.EstadoPartido.activo;
    }
  }
}
