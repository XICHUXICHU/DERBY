import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../domain/domain.dart' as domain;

/// Repositorio para rondas y enfrentamientos.
class RondaRepository {
  final AppDatabase _db;

  RondaRepository(this._db);

  /// Crear ronda con sus enfrentamientos (en transacción).
  Future<int> crearRondaConEnfrentamientos({
    required int derbyId,
    required int numero,
    required bool esRondaBase,
    required List<domain.Enfrentamiento> enfrentamientos,
    List<int> partidosBye = const [],
    List<int> partidosDobles = const [],
  }) async {
    return _db.transaction(() async {
      // Insertar ronda
      final byeStr = partidosBye.join(',');
      final doblesStr = partidosDobles.join(',');
      final rondaId = await _db
          .into(_db.rondas)
          .insert(
            RondasCompanion.insert(
              derbyId: derbyId,
              numero: numero,
              esRondaBase: Value(esRondaBase),
              byePartidos: Value(byeStr),
              doblesPartidos: Value(doblesStr),
            ),
          );

      // Insertar enfrentamientos
      for (final e in enfrentamientos) {
        await _db
            .into(_db.enfrentamientos)
            .insert(
              EnfrentamientosCompanion.insert(
                rondaId: rondaId,
                galloAId: e.galloA.id,
                galloBId: e.galloB.id,
                diferenciaPeso: e.diferenciaPeso,
              ),
            );
      }

      return rondaId;
    });
  }

  /// Obtener rondas de un derby.
  Future<List<Ronda>> listarPorDerby(int derbyId) {
    return (_db.select(_db.rondas)
          ..where((r) => r.derbyId.equals(derbyId))
          ..orderBy([(r) => OrderingTerm.asc(r.numero)]))
        .get();
  }

  /// Obtener enfrentamientos de una ronda.
  Future<List<Enfrentamiento>> listarEnfrentamientos(int rondaId) {
    return (_db.select(
      _db.enfrentamientos,
    )..where((e) => e.rondaId.equals(rondaId))).get();
  }

  /// Registrar resultado de un enfrentamiento.
  Future<int> registrarResultado(int enfrentamientoId, String resultado) {
    return (_db.update(_db.enfrentamientos)
          ..where((e) => e.id.equals(enfrentamientoId)))
        .write(EnfrentamientosCompanion(resultado: Value(resultado)));
  }

  /// Registra o actualiza un enfrentamiento explícito en la base de datos
  Future<void> registrarEnfrentamientoManual({
    required int rondaId,
    required int galloAId,
    required int galloBId,
    required double diferenciaPeso,
  }) async {
    await _db
        .into(_db.enfrentamientos)
        .insert(
          EnfrentamientosCompanion.insert(
            rondaId: rondaId,
            galloAId: galloAId,
            galloBId: galloBId,
            diferenciaPeso: diferenciaPeso,
          ),
        );
  }

  /// Eliminar enfrentamiento específico de la Base de Datos.
  Future<void> eliminarEnfrentamiento(int enfrentamientoId) async {
    await (_db.delete(
      _db.enfrentamientos,
    )..where((e) => e.id.equals(enfrentamientoId))).go();
  }

  /// Eliminar todas las rondas y enfrentamientos de un derby.
  Future<void> eliminarPorDerby(int derbyId) async {
    await _db.transaction(() async {
      final rondas = await listarPorDerby(derbyId);
      for (final ronda in rondas) {
        await (_db.delete(
          _db.enfrentamientos,
        )..where((e) => e.rondaId.equals(ronda.id))).go();
      }
      await (_db.delete(
        _db.rondas,
      )..where((r) => r.derbyId.equals(derbyId))).go();
    });
  }

  /// Obtener rondas de un derby con enfrentamientos hidratados (domain entities).
  ///
  /// Carga cada ronda, sus enfrentamientos, y los gallos asociados,
  /// retornando objetos [domain.Ronda] listos para usar en la UI.
  Future<List<domain.Ronda>> listarHidratadasPorDerby(int derbyId) async {
    final rondas = await listarPorDerby(derbyId);
    final resultado = <domain.Ronda>[];

    for (final ronda in rondas) {
      final enfrentamientosDb = await listarEnfrentamientos(ronda.id);
      final domEnfrentamientos = <domain.Enfrentamiento>[];

      for (final e in enfrentamientosDb) {
        final galloA = await (_db.select(
          _db.gallos,
        )..where((g) => g.id.equals(e.galloAId))).getSingleOrNull();
        final galloB = await (_db.select(
          _db.gallos,
        )..where((g) => g.id.equals(e.galloBId))).getSingleOrNull();

        if (galloA != null && galloB != null) {
          domEnfrentamientos.add(
            domain.Enfrentamiento(
              id: e.id,
              rondaNumero: ronda.numero,
              galloA: domain.Gallo(
                id: galloA.id,
                partidoId: galloA.partidoId,
                anillo: galloA.anillo,
                pesoGramos: galloA.pesoGramos,
                esBase: galloA.esBase,
                color: galloA.color,
                observaciones: galloA.observaciones,
              ),
              galloB: domain.Gallo(
                id: galloB.id,
                partidoId: galloB.partidoId,
                anillo: galloB.anillo,
                pesoGramos: galloB.pesoGramos,
                esBase: galloB.esBase,
                color: galloB.color,
                observaciones: galloB.observaciones,
              ),
              diferenciaPeso: e.diferenciaPeso,
              resultado: e.resultado != null
                  ? _parseResultado(e.resultado!)
                  : null,
            ),
          );
        }
      }

      // Parse bye partidos
      final byeIds = ronda.byePartidos.isNotEmpty
          ? ronda.byePartidos
                .split(',')
                .where((s) => s.isNotEmpty)
                .map(int.parse)
                .toList()
          : <int>[];

      // Parse dobles partidos
      final doblesIds = ronda.doblesPartidos.isNotEmpty
          ? ronda.doblesPartidos
                .split(',')
                .where((s) => s.isNotEmpty)
                .map(int.parse)
                .toList()
          : <int>[];

      resultado.add(
        domain.Ronda(
          numero: ronda.numero,
          enfrentamientos: domEnfrentamientos,
          esRondaBase: ronda.esRondaBase,
          fechaCreacion: ronda.fechaCreacion,
          partidosBye: byeIds,
          partidosDobles: doblesIds,
        ),
      );
    }

    return resultado;
  }

  /// Convierte string de DB a enum.
  domain.ResultadoPelea _parseResultado(String resultado) {
    switch (resultado) {
      case 'ganoA':
        return domain.ResultadoPelea.ganoA;
      case 'ganoB':
        return domain.ResultadoPelea.ganoB;
      case 'empate':
        return domain.ResultadoPelea.empate;
      case 'noPeleada':
        return domain.ResultadoPelea.noPeleada;
      default:
        return domain.ResultadoPelea.noPeleada;
    }
  }

  /// Obtener todos los IDs de gallos que ya pelearon en un derby.
  Future<Set<int>> gallosYaPeleados(int derbyId) async {
    final rondas = await listarPorDerby(derbyId);
    final galloIds = <int>{};

    for (final ronda in rondas) {
      final enfrentamientos = await listarEnfrentamientos(ronda.id);
      for (final e in enfrentamientos) {
        galloIds.add(e.galloAId);
        galloIds.add(e.galloBId);
      }
    }

    return galloIds;
  }

  /// Obtener enfrentamientos previos como pares de partidos.
  /// Requiere join con gallos para obtener partidoId.
  Future<Set<(int, int)>> enfrentamientosPrevios(int derbyId) async {
    final rondas = await listarPorDerby(derbyId);
    final pares = <(int, int)>{};

    for (final ronda in rondas) {
      // Obtenemos enfrentamientos y luego los gallos
      final enfrentamientos = await listarEnfrentamientos(ronda.id);
      for (final e in enfrentamientos) {
        // Necesitamos los partidoIds desde la tabla de gallos
        final galloA = await (_db.select(
          _db.gallos,
        )..where((g) => g.id.equals(e.galloAId))).getSingleOrNull();
        final galloB = await (_db.select(
          _db.gallos,
        )..where((g) => g.id.equals(e.galloBId))).getSingleOrNull();
        if (galloA != null && galloB != null) {
          final a = galloA.partidoId < galloB.partidoId
              ? galloA.partidoId
              : galloB.partidoId;
          final b = galloA.partidoId < galloB.partidoId
              ? galloB.partidoId
              : galloA.partidoId;
          pares.add((a, b));
        }
      }
    }

    return pares;
  }
}
