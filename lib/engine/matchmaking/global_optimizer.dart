import 'dart:math';
import '../derby_engine.dart';
import '../../domain/domain.dart';

class ParGlobal {
  final Gallo galloA;
  final Gallo galloB;
  double get diferencia => (galloA.pesoGramos - galloB.pesoGramos).abs().toDouble();

  ParGlobal(this.galloA, this.galloB);
}

class ResultadoGlobal {
  final Map<int, List<Gallo>> asignacion;
  final Map<int, List<ParGlobal>> matchings;
  final double maxDiferencia;
  final double sumaTotal;

  ResultadoGlobal({
    required this.asignacion,
    required this.matchings,
    this.maxDiferencia = 0.0,
    this.sumaTotal = 0.0,
  });
}

class GlobalMatchingOptimizer {
  final double diferenciaMaxPeso;
  final List<Compadres> compadres;
  final bool permitirRepeticiones;

  GlobalMatchingOptimizer({
    required this.compadres,
    required this.diferenciaMaxPeso,
    this.permitirRepeticiones = false,
  });

  bool _sonCompadres(int partido1, int partido2) {
    for (var c in compadres) {
      if ((c.partidoIdA == partido1 && c.partidoIdB == partido2) ||
          (c.partidoIdA == partido2 && c.partidoIdB == partido1)) {
        return true;
      }
    }
    return false;
  }

  ResultadoGlobal optimizar({
    required List<Gallo> gallosPL,
    required Set<int> partidosActivos,
    required int numRondasPL,
    int? partidoDobleId,
    int? rondaDobleIndex,
    Map<int, int>? partidosBye,
  }) {
    // 1. Agrupar gallos por partido y ordenarlos por peso (más ligero a más pesado)
    Map<int, List<Gallo>> gallosPorPartido = {};
    for (var g in gallosPL) {
      gallosPorPartido.putIfAbsent(g.partidoId, () => []).add(g);
    }
    
    for (var pid in gallosPorPartido.keys) {
      gallosPorPartido[pid]!.sort((a, b) => a.pesoGramos.compareTo(b.pesoGramos));
    }

    // 2. Distribuir a los gallos en las rondas basándose en su rango de peso
    // Ronda 0 tendrá a los más ligeros, Ronda 1 a los medianos, etc.
    Map<int, List<Gallo>> rondasPools = {for (int i = 0; i < numRondasPL; i++) i: []};
    
    for (var pid in partidosActivos) {
      if (!gallosPorPartido.containsKey(pid)) continue;
      var gl = gallosPorPartido[pid]!;
      for (int i = 0; i < gl.length; i++) {
        // En caso de que haya más gallos que rondas (raro), se cicla, pero normalmente i < numRondasPL
        rondasPools[i % numRondasPL]!.add(gl[i]);
      }
    }

    // 3. En cada ronda, emparejar localmente a los gallos
    Map<int, List<ParGlobal>> matchings = {};
    double mD = 0.0;
    double sT = 0.0;

    for (int r = 0; r < numRondasPL; r++) {
      var pool = rondasPools[r]!;
      pool.sort((a, b) => a.pesoGramos.compareTo(b.pesoGramos));
      
      List<ParGlobal> rondaPares = _emparejarPoolLocal(pool);
      matchings[r] = rondaPares;
      
      for (var p in rondaPares) {
        sT += p.diferencia;
        if (p.diferencia > mD) mD = p.diferencia;
      }
    }

    // Retornamos el resultado
    return ResultadoGlobal(
      asignacion: {},
      matchings: matchings,
      maxDiferencia: mD,
      sumaTotal: sT,
    );
  }

  List<ParGlobal> _emparejarPoolLocal(List<Gallo> disponibles) {
    List<ParGlobal> matchings = [];
    List<Gallo> tempPool = List.from(disponibles);

    while (tempPool.length >= 2) {
      Gallo gA = tempPool[0];
      int bestIndex = -1;
      double minDiff = double.infinity;

      for (int i = 1; i < tempPool.length; i++) {
        Gallo gB = tempPool[i];
        if (!_sonCompadres(gA.partidoId, gB.partidoId)) {
          double diff = (gA.pesoGramos - gB.pesoGramos).abs().toDouble();
          if (diff < minDiff && diff <= diferenciaMaxPeso) {
            minDiff = diff;
            bestIndex = i;
          }
        }
      }

      if (bestIndex != -1) {
        matchings.add(ParGlobal(gA, tempPool[bestIndex]));
        tempPool.removeAt(bestIndex);
        tempPool.removeAt(0);
      } else {
        // Si nadie cumple la condición (compadres o peso excesivo), tratar de forzar el emparejamiento con el siguiente
        matchings.add(ParGlobal(gA, tempPool[1]));
        tempPool.removeAt(1);
        tempPool.removeAt(0);
      }
    }

    // Optimización local (Simulated Annealing simple) para mejorar la ronda
    const int maxIter = 5000;
    Random rnd = Random(12345);

    for (int iter = 0; iter < maxIter; iter++) {
      int maxDiffIdx = -1;
      double maxDiff = -1;
      for (int i = 0; i < matchings.length; i++) {
        double d = matchings[i].diferencia;
        if (d > maxDiff) {
          maxDiff = d;
          maxDiffIdx = i;
        }
      }

      if (maxDiffIdx == -1 || matchings.length < 2) break;

      int swapIdx = rnd.nextInt(matchings.length);
      if (swapIdx == maxDiffIdx) continue;

      ParGlobal p1 = matchings[maxDiffIdx];
      ParGlobal p2 = matchings[swapIdx];

      double curDiff = p1.diferencia + p2.diferencia;

      // Try swap 1: A1-A2, B1-B2
      double diff1 = (p1.galloA.pesoGramos - p2.galloA.pesoGramos).abs() +
                     (p1.galloB.pesoGramos - p2.galloB.pesoGramos).abs();
      // Try swap 2: A1-B2, B1-A2
      double diff2 = (p1.galloA.pesoGramos - p2.galloB.pesoGramos).abs() +
                     (p1.galloB.pesoGramos - p2.galloA.pesoGramos).abs();

      bool comp1A = _sonCompadres(p1.galloA.partidoId, p2.galloA.partidoId);
      bool comp1B = _sonCompadres(p1.galloB.partidoId, p2.galloB.partidoId);
      bool comp2A = _sonCompadres(p1.galloA.partidoId, p2.galloB.partidoId);
      bool comp2B = _sonCompadres(p1.galloB.partidoId, p2.galloA.partidoId);

      bool swap1Valido = !comp1A && !comp1B;
      bool swap2Valido = !comp2A && !comp2B;

      if (swap1Valido && swap2Valido) {
        if (diff1 < curDiff && diff1 <= diff2) {
          matchings[maxDiffIdx] = ParGlobal(p1.galloA, p2.galloA);
          matchings[swapIdx] = ParGlobal(p1.galloB, p2.galloB);
        } else if (diff2 < curDiff) {
          matchings[maxDiffIdx] = ParGlobal(p1.galloA, p2.galloB);
          matchings[swapIdx] = ParGlobal(p1.galloB, p2.galloA);
        }
      } else if (swap1Valido && diff1 < curDiff) {
        matchings[maxDiffIdx] = ParGlobal(p1.galloA, p2.galloA);
        matchings[swapIdx] = ParGlobal(p1.galloB, p2.galloB);
      } else if (swap2Valido && diff2 < curDiff) {
        matchings[maxDiffIdx] = ParGlobal(p1.galloA, p2.galloB);
        matchings[swapIdx] = ParGlobal(p1.galloB, p2.galloA);
      }
    }

    return matchings;
  }
}
