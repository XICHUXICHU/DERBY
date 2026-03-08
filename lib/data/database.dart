import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Derbys,
  Partidos,
  Gallos,
  CompadresTable,
  Rondas,
  Enfrentamientos,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor para testing con base de datos en memoria.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Habilitar claves foráneas
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Futuras migraciones aquí
        },
        beforeOpen: (details) async {
          // Siempre habilitar claves foráneas
          await customStatement('PRAGMA foreign_keys = ON');
          // WAL mode para mejor rendimiento concurrente
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'derby2.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
