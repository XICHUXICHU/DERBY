import 'package:flutter_test/flutter_test.dart';
import 'package:derby2_flutter/data/database.dart';
import 'package:derby2_flutter/data/repositories/ronda_repository.dart';

void main() {
  test('Test db', () async {
    final db = AppDatabase.forTesting();
    final repo = RondaRepository(db);

    try {
      await repo.listarHidratadasPorDerby(1);
    } catch (e, stack) {
      print('Exception: $e');
      print('Stack: $stack');
    }
  });
}
