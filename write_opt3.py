import base64

content = """
import 'dart:math';
import '../../domain/entities/gallo.dart';
import '../../domain/entities/compadres.dart';

class ParGlobal {
  final Gallo galloA;
  final Gallo galloB;
  ParGlobal(this.galloA, this.galloB);

  double get diferencia => (galloA.pesoGramos - galloB.pesoGramos).abs();
}

class ResultadoGlobal {
  final Map<int, List<Gallo>> asignacion;
  final Map<int, List<ParGlobal>> matchings;
  final double maxDiferencia;
  final double sumaTotal;
  
  const ResultadoGlobal({
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
    required this.diferenciaMaxPeso,
    required this.compadres,
    this.permitirRepeticiones = false,
  });

  bool _sonCompadres(int partidoId1, int partidoId2) {
    if (partidoId1 == partidoId2) return true;
    for (var c in compadres) {
      if ((c.frente1Id == partidoId1 && c.frente2Id == partidoId2) ||
          (c.frente1Id == partidoId2 && c.frente2Id == partidoId1)) {
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
    List<Gallo> pool = List.from(gallosPL);
    pool.sort((a, b) => a.pesoGramos.compareTo(b.pesoGramos));

    List<ParGlobal> emparejamientos = _emparejarPoolGlobal(pool);

    return _distribuirEnRondas(emparejamientos, numRondasPL);
  }

  List<ParGlobal> _emparejarPoolGlobal(List<Gallo> disponibles) {
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
        tempPool.removeAt(0);
      }
    }

    const int maxIter = 10000;
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

      if (maxDiff <= 55) break; 
      
      int swapIdx = rnd.nextInt(matchings.length);
      if (swapIdx == maxDiffIdx) continue;

      ParGlobal p1 = matchings[maxDiffIdx];
      ParGlobal p2 = matchings[swapIdx];

      ParGlobal pA = ParGlobal(p1.galloA, p2.galloA);
      ParGlobal pB = ParGlobal(p1.galloB, p2.galloB);

      if (!_sonCompadres(pA.galloA.partidoId, pA.galloB.partidoId) && 
          !_sonCompadres(pB.galloA.partidoId, pB.galloB.partidoId)) {
        double newMax = pA.diferencia > pB.diferencia ? pA.diferencia : pB.diferencia;
        double oldMax = p1.diferencia > p2.diferencia ? p1.diferencia : p2.diferencia;
        
        if (newMax < oldMax) {
          matchings[maxDiffIdx] = pA;
          matchings[swapIdx] = pB;
        }
      }
    }

    return matchings;
  }

  ResultadoGlobal _distribuirEnRondas(List<ParGlobal> pares, int limit) {
    Map<int, List<ParGlobal>> result = {};
    Map<int, List<Gallo>> asignacionVacia = {};
    
    double mD = 0.0;
    double sT = 0.0;

    for (int i = 0; i < pares.length; i++) {
      int column = i % limit;
      if (!result.containsKey(column)) {
        result[column] = [];
      }
      result[column]!.add(pares[i]);
      
      double d = pares[i].diferencia;
      sT += d;
      if (d > mD) mD = d;
    }
    
    return ResultadoGlobal(asignacion: asignacionVacia, matchings: result, maxDiferencia: mD, sumaTotal: sT);
  }
}
"""

with open('lib/engine/matchmaking/global_optimizer.dart', 'wb') as f:
    f.write(content.encode('utf-8'))
