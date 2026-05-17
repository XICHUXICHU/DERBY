import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:derby2_flutter/data/database.dart';

void main() {
  test('Test drift query', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await (db.select(db.enfrentamientos)..where((e) => e.id.equals(null as dynamic))).getSingleOrNull();
    } catch(e, s) {
      print('CRASH: $e\n$s');
    }
  });
}
