import '../../domain/domain.dart';

class ParGlobal {
  final Gallo a;
  final Gallo b;
  final double diff;
  ParGlobal(this.a, this.b) : diff = (a.pesoGramos - b.pesoGramos).abs();
}

class GlobalPoolMatcher {
  static List<ParGlobal> emparejarTodo({
    required List<Gallo> gallos,
    required List<Compadres> compadres,
  }) {
    if (gallos.length % 2 != 0) {
      throw Exception("El pool total de gallos debe ser par (${gallos.length}).");
    }

    bool sonCompadres(int p1, int p2) {
      for (var c in compadres) {
        if ((c.partidoIdA == p1 && c.partidoIdB == p2) ||
            (c.partidoIdA == p2 && c.partidoIdB == p1)) {
          return true;
        }
      }
      return false;
    }

    // Ordenar gallos de menor a mayor peso
    final ordenados = List<Gallo>.from(gallos)..sort((a, b) => a.pesoGramos.compareTo(b.pesoGramos));

    List<ParGlobal>? mejorMatch;
    double mejorMaxDiff = double.infinity;
    double mejorSumaDiff = double.infinity;
    int iteraciones = 0;
    const int MAX_ITER = 50000;

    // Backtracking con ventana (Window)
    void bt(List<Gallo> disponibles, List<ParGlobal> actual, double objMaxDiff, double objSuma) {
      if (iteraciones > MAX_ITER) return;

      if (objMaxDiff > mejorMaxDiff) return;
      if (objMaxDiff == mejorMaxDiff && objSuma >= mejorSumaDiff) return;

      if (disponibles.isEmpty) {
        mejorMatch = List.from(actual);
        mejorMaxDiff = objMaxDiff;
        mejorSumaDiff = objSuma;
        return;
      }

      iteraciones++;

      final gA = disponibles[0];

      int tries = 0;
      for (int i = 1; i < disponibles.length; i++) {
        if (tries >= 6) break; // Lookahead de max 6 gallos para evitar explosión combinatoria

        final gB = disponibles[i];

        if (gA.partidoId == gB.partidoId) continue;
        if (sonCompadres(gA.partidoId, gB.partidoId)) continue;

        tries++;

        double diff = (gA.pesoGramos - gB.pesoGramos).abs();
        double newMax = diff > objMaxDiff ? diff : objMaxDiff;
        double newSuma = objSuma + diff;

        if (newMax > mejorMaxDiff) continue;

        final nextDisp = List<Gallo>.from(disponibles);
        nextDisp.removeAt(i);
        nextDisp.removeAt(0);

        actual.add(ParGlobal(gA, gB));
        bt(nextDisp, actual, newMax, newSuma);
        actual.removeLast();
      }
    }

    // Ejecutar Backtracking Minimax 1D
    bt(ordenados, [], 0.0, 0.0);

    // Si falló por restricciones muy severas en el último par (greedy fallback)
    if (mejorMatch == null) {
      mejorMatch = _fallbackGreedy(ordenados, sonCompadres);
    }

    return mejorMatch!;
  }

  static List<ParGlobal> _fallbackGreedy(List<Gallo> ordenados, bool Function(int, int) invalidos) {
    List<ParGlobal> pares = [];
    List<Gallo> disp = List.from(ordenados);

    while (disp.isNotEmpty) {
      if (disp.length == 1) break;

      Gallo a = disp.removeAt(0);
      int bestIdx = -1;
      double bestDiff = double.infinity;

      for (int i = 0; i < disp.length; i++) {
        Gallo b = disp[i];
        if (a.partidoId == b.partidoId) continue;
        if (invalidos(a.partidoId, b.partidoId)) continue;

        double diff = (a.pesoGramos - b.pesoGramos).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          bestIdx = i;
        }
      }

      if (bestIdx != -1) {
        Gallo b = disp.removeAt(bestIdx);
        pares.add(ParGlobal(a, b));
      } else {
        // Forza el emparejamiento, aunque sea del mismo partido, para que no crashee
        Gallo b = disp.removeAt(0);
        pares.add(ParGlobal(a, b));
      }
    }
    return pares;
  }
}
