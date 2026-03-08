import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/tables.dart';

part 'app_database.g.dart';

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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(partidos, partidos.depositoPagado);
            await m.addColumn(partidos, partidos.depositoCantidad);
          }
          if (from < 3) {
            await m.addColumn(derbys, derbys.pesoMinimo);
            await m.addColumn(derbys, derbys.pesoMaximo);
            await m.addColumn(derbys, derbys.pesoGalloBase);
            await m.addColumn(derbys, derbys.permitirRepeticiones);
          }
          if (from < 4) {
            await m.addColumn(derbys, derbys.diferenciaMaxPeso);
            await m.addColumn(derbys, derbys.validacionEstricta);
          }
          if (from < 5) {
            await m.addColumn(rondas, rondas.byePartidos);
          }
          if (from < 6) {
            await m.addColumn(partidos, partidos.esComodin);
            await m.addColumn(rondas, rondas.doblesPartidos);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
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
