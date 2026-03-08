import '../../domain/domain.dart';
import 'graph_builder.dart';
import 'matching_solver.dart';

/// Resultado del optimizador global multi-ronda.
class ResultadoGlobal {
  /// Gallos asignados a cada ronda: rondaIndex (0-based) → lista de gallos.
  final Map<int, List<Gallo>> asignacion;

  /// Matching resuelto por ronda: rondaIndex (0-based) → pares.
  final Map<int, List<ParEmparejado>> matchings;

  /// La peor (máxima) diferencia de peso en cualquier pelea.
  final double maxDiferencia;

  /// Suma total de todas las diferencias.
  final double sumaTotal;

  const ResultadoGlobal({
    required this.asignacion,
    required this.matchings,
    required this.maxDiferencia,
    required this.sumaTotal,
  });
}

/// Optimizador global multi-ronda para minimizar la diferencia máxima
/// individual (minimax) en todo el sorteo P.L.
///
/// Fases:
/// 1. Pre-asignación de gallos a rondas por peso (balanceo)
/// 2. Matching minimax por ronda
/// 3. Mejora local via swap entre rondas
///
/// Puro Dart. No depende de Flutter ni Drift.
class GlobalMatchingOptimizer {
  /// Diferencia máxima de peso permitida (g). 0 = sin límite.
  final double diferenciaMaxPeso;

  /// Relaciones de compadres.
  final List<Compadres> compadres;

  /// ¿Se permiten repetir contrincantes entre rondas?
  final bool permitirRepeticiones;

  /// Máximo de iteraciones de mejora local.
  static const int _maxSwapIteraciones = 2000;

  /// Máximo de iteraciones de backtracking minimax por ronda.
  static const int _maxBtIteraciones = 500000;

  /// Umbral de partidos por ronda: con más partidos se usa greedy en vez de
  /// backtracking (el backtracking es exponencial en el número de pares).
  static const int _umbralBtPartidos = 16;

  GlobalMatchingOptimizer({
    required this.compadres,
    this.diferenciaMaxPeso = 0.0,
    this.permitirRepeticiones = false,
  });

  /// Genera la asignación global óptima de gallos PL a rondas.
  ///
  /// [gallosPL]: todos los gallos PL de todos los partidos (no base).
  /// [partidosActivos]: IDs de partidos que participan.
  /// [numRondasPL]: número de rondas PL (típicamente rondasTotales - 1).
  /// [partidoDobleId]: si hay impar, el id del partido que pelea doble, o null.
  /// [rondaDobleIndex]: ronda 0-based donde se aplica la doble pelea, or -1.
  /// [partidosBye]: mapa de rondaIndex → partidoId que tiene BYE en esa ronda.
  ///
  /// Retorna [ResultadoGlobal] con la asignación y matchings resueltos.
  ResultadoGlobal optimizar({
    required List<Gallo> gallosPL,
    required Set<int> partidosActivos,
    required int numRondasPL,
    int? partidoDobleId,
    int rondaDobleIndex = -1,
    Map<int, int> partidosBye = const {},
  }) {
    // ── Fase 1: Pre-asignación de gallos a rondas ──
    final asignacion = _asignarGallosARondas(
      gallosPL: gallosPL,
      partidosActivos: partidosActivos,
      numRondasPL: numRondasPL,
      partidoDobleId: partidoDobleId,
      rondaDobleIndex: rondaDobleIndex,
      partidosBye: partidosBye,
    );

    // ── Fase 2: Matching minimax por ronda ──
    var matchings = _resolverMatchingsPorRonda(
      asignacion: asignacion,
      partidosActivos: partidosActivos,
      numRondasPL: numRondasPL,
      partidoDobleId: partidoDobleId,
      rondaDobleIndex: rondaDobleIndex,
      partidosBye: partidosBye,
    );

    // ── Fase 3: Mejora local (swap entre rondas) ──
    final resultado = _mejoraLocal(
      asignacion: asignacion,
      matchings: matchings,
      gallosPL: gallosPL,
      partidosActivos: partidosActivos,
      numRondasPL: numRondasPL,
      partidoDobleId: partidoDobleId,
      rondaDobleIndex: rondaDobleIndex,
      partidosBye: partidosBye,
    );

    return resultado;
  }

  // ═══════════════════════════════════════════════════════
  //  FASE 1: Pre-asignación de gallos a rondas
  // ═══════════════════════════════════════════════════════

  /// Asigna gallos PL a rondas buscando equilibrar pesos por ronda.
  ///
  /// Estrategia: para cada partido, ordenar sus gallos PL por peso.
  /// Luego asignar a rondas de forma que cada ronda tenga pesos
  /// similares globalmente (= menor varianza intra-ronda).
  ///
  /// Restricción: cada partido tiene exactamente 1 gallo por ronda PL,
  /// EXCEPTO el partido doble que tiene 2 en la ronda de doble pelea
  /// y 0/1 en las demás según cuántos gallos tenga.
  Map<int, List<Gallo>> _asignarGallosARondas({
    required List<Gallo> gallosPL,
    required Set<int> partidosActivos,
    required int numRondasPL,
    int? partidoDobleId,
    int rondaDobleIndex = -1,
    Map<int, int> partidosBye = const {},
  }) {
    // Agrupar gallos por partido
    final gallosPorPartido = <int, List<Gallo>>{};
    for (final g in gallosPL) {
      if (!partidosActivos.contains(g.partidoId) &&
          g.partidoId != partidoDobleId) {
        continue;
      }
      gallosPorPartido.putIfAbsent(g.partidoId, () => []).add(g);
    }
    // Ordenar cada partido's gallos por peso
    for (final lista in gallosPorPartido.values) {
      lista.sort((a, b) => a.pesoGramos.compareTo(b.pesoGramos));
    }

    // Inicializar asignación: rondaIndex → gallos
    final asignacion = <int, List<Gallo>>{};
    for (var r = 0; r < numRondasPL; r++) {
      asignacion[r] = [];
    }

    // Para partido doble: asignar 2 gallos a rondaDoble, 1 a otra ronda
    // Para todos los demás: asignar 1 gallo por ronda
    //
    // Estrategia: generar todas las permutaciones posibles es costoso para
    // >20 partidos. En su lugar, usamos una heurística de "balanced interleave":
    //
    // 1. Ordenar partidos por su rango de pesos (max - min) descendente
    //    (los partidos con mayor rango se asignan primero, tienen más impacto)
    // 2. Para cada partido, probar las permutaciones de sus gallos a rondas
    //    y elegir la que minimiza la varianza máxima intra-ronda.

    // Partidos con BYE: un partido con BYE en ronda R no pelea en R.
    // Necesitamos saber qué rondas peleó cada partido.
    final byeRondas =
        <int, Set<int>>{}; // partidoId → set of rondaIndex with BYE
    for (final entry in partidosBye.entries) {
      byeRondas.putIfAbsent(entry.value, () => {}).add(entry.key);
    }

    // Determinar qué rondas pelea cada partido
    final rondasPorPartido = <int, List<int>>{}; // partidoId → ronda indices
    for (final pid in {
      ...partidosActivos,
      if (partidoDobleId != null) partidoDobleId,
    }) {
      final rondas = <int>[];
      for (var r = 0; r < numRondasPL; r++) {
        // Skip if this partido has BYE in round r
        if (partidosBye[r] == pid) continue;
        rondas.add(r);
      }
      rondasPorPartido[pid] = rondas;
    }

    // Doble pelea: el partido doble pelea en la ronda doble + sus otras rondas
    // En la ronda doble, usa 2 gallos. En las otras, 1 cada una.
    // Total gallos PL del doble: si hay 3 PL y pelea doble en 1 ronda + normal en K-1,
    // usa 2 + (K-1) = K+1 gallos. Con 3 PL y 3 rondas PL: 2+1 o 2+2... depende.

    // Sort partidos: those with most weight range first (they benefit most from
    // smart placement)
    final partidoIds = gallosPorPartido.keys.toList();
    partidoIds.sort((a, b) {
      final gallosA = gallosPorPartido[a]!;
      final gallosB = gallosPorPartido[b]!;
      final rangoA = gallosA.last.pesoGramos - gallosA.first.pesoGramos;
      final rangoB = gallosB.last.pesoGramos - gallosB.first.pesoGramos;
      return rangoB.compareTo(rangoA); // descending range
    });

    // Assign each partido's gallos to rounds using best-fit
    for (final pid in partidoIds) {
      final gallos = gallosPorPartido[pid]!;
      final rondas = rondasPorPartido[pid];
      if (rondas == null || rondas.isEmpty) continue;

      if (pid == partidoDobleId && rondaDobleIndex >= 0) {
        // Doble pelea: need 2 gallos in dobleRonda, 1 in each other
        _asignarPartidoDoble(
          gallos: gallos,
          rondas: rondas,
          rondaDobleIndex: rondaDobleIndex,
          asignacion: asignacion,
        );
      } else {
        // Normal: 1 gallo per round
        _asignarPartidoNormal(
          gallos: gallos,
          rondas: rondas,
          asignacion: asignacion,
        );
      }
    }

    return asignacion;
  }

  /// Asigna gallos de un partido normal (1 por ronda) buscando
  /// minimizar la varianza de peso intra-ronda.
  void _asignarPartidoNormal({
    required List<Gallo> gallos,
    required List<int> rondas,
    required Map<int, List<Gallo>> asignacion,
  }) {
    // gallos are sorted by weight asc. rondas are the round indices this
    // partido must fight in.
    // We need to assign exactly 1 gallo to each ronda.
    // If gallos.length < rondas.length, some rounds won't have this partido
    // (shouldn't happen with 3 PL and 3 PL rounds, but handle gracefully).

    final numToAssign = gallos.length < rondas.length
        ? gallos.length
        : rondas.length;

    if (numToAssign <= 0) return;

    // For small counts (3 gallos, 3 rounds), try all permutations
    if (numToAssign <= 5) {
      _asignarConPermutaciones(
        gallos: gallos.sublist(0, numToAssign),
        rondas: rondas.sublist(0, numToAssign),
        asignacion: asignacion,
        gallosPorRonda: 1,
      );
    } else {
      // Fallback: sort rounds by current average weight, assign lightest gallo
      // to round with heaviest average, etc. (balance interleave)
      _asignarBalanceado(
        gallos: gallos.sublist(0, numToAssign),
        rondas: rondas.sublist(0, numToAssign),
        asignacion: asignacion,
      );
    }
  }

  /// Asigna gallos del partido doble: 2 gallos en rondaDoble, 1 en las demás.
  void _asignarPartidoDoble({
    required List<Gallo> gallos,
    required List<int> rondas,
    required int rondaDobleIndex,
    required Map<int, List<Gallo>> asignacion,
  }) {
    // Separate rounds: the doble round + normal rounds
    final normalRondas = rondas.where((r) => r != rondaDobleIndex).toList();

    // We need 2 gallos for doble + 1 per normal round
    final available = gallos.length;

    if (available < 2) {
      // Not enough gallos for doble, bail
      for (var i = 0; i < gallos.length && i < rondas.length; i++) {
        asignacion[rondas[i]]!.add(gallos[i]);
      }
      return;
    }

    // Try all ways to pick 2 gallos for the doble round, rest for normal rounds
    // With 3 gallos: C(3,2) = 3 combinations × permutations of remaining
    double bestMaxDiff = double.infinity;
    List<Gallo>? bestDobleGallos;
    List<(int, Gallo)>? bestNormalAssign; // (rondaIndex, gallo)

    final combos = _combinaciones(gallos, 2);
    for (final dobleGallos in combos) {
      final restantes = gallos.where((g) => !dobleGallos.contains(g)).toList();

      // Assign restantes to normalRondas
      final nToAssign = restantes.length < normalRondas.length
          ? restantes.length
          : normalRondas.length;
      if (nToAssign == 0 && normalRondas.isEmpty) {
        // Only the doble round
        final maxDiff = _calcMaxDiffConAsignacion(
          asignacion,
          rondaDobleIndex,
          dobleGallos,
        );
        if (maxDiff < bestMaxDiff) {
          bestMaxDiff = maxDiff;
          bestDobleGallos = dobleGallos;
          bestNormalAssign = [];
        }
        continue;
      }

      // Try permutations of restantes across normal rounds
      final perms = nToAssign <= 5
          ? _permutaciones(restantes.sublist(0, nToAssign))
          : [restantes.sublist(0, nToAssign)]; // fallback: no permutation

      for (final perm in perms) {
        // Calculate max variance impact
        var maxDiff = _calcMaxDiffConAsignacion(
          asignacion,
          rondaDobleIndex,
          dobleGallos,
        );
        for (var i = 0; i < perm.length && i < normalRondas.length; i++) {
          final d = _calcMaxDiffConAsignacion(asignacion, normalRondas[i], [
            perm[i],
          ]);
          if (d > maxDiff) maxDiff = d;
        }

        if (maxDiff < bestMaxDiff) {
          bestMaxDiff = maxDiff;
          bestDobleGallos = dobleGallos;
          bestNormalAssign = [];
          for (var i = 0; i < perm.length && i < normalRondas.length; i++) {
            bestNormalAssign.add((normalRondas[i], perm[i]));
          }
        }
      }
    }

    // Apply best assignment
    if (bestDobleGallos != null) {
      asignacion[rondaDobleIndex]!.addAll(bestDobleGallos);
      for (final entry in bestNormalAssign ?? <(int, Gallo)>[]) {
        asignacion[entry.$1]!.add(entry.$2);
      }
    } else {
      // Fallback: just assign sequentially
      if (rondas.contains(rondaDobleIndex) && gallos.length >= 2) {
        asignacion[rondaDobleIndex]!.add(gallos[0]);
        asignacion[rondaDobleIndex]!.add(gallos[1]);
        var gi = 2;
        for (final r in normalRondas) {
          if (gi >= gallos.length) break;
          asignacion[r]!.add(gallos[gi++]);
        }
      }
    }
  }

  /// Calcula la máxima diferencia de peso dentro de una ronda
  /// si le agregas [newGallos] a los que ya están.
  double _calcMaxDiffConAsignacion(
    Map<int, List<Gallo>> asignacion,
    int rondaIndex,
    List<Gallo> newGallos,
  ) {
    final existentes = asignacion[rondaIndex] ?? [];
    final todos = [...existentes, ...newGallos];
    if (todos.length < 2) return 0;

    // Max diff within this round's gallos (rough estimate of potential fight diff)
    var maxDiff = 0.0;
    for (var i = 0; i < todos.length; i++) {
      for (var j = i + 1; j < todos.length; j++) {
        if (todos[i].partidoId == todos[j].partidoId) continue;
        final d = todos[i].diferenciaAbsoluta(todos[j]);
        if (d > maxDiff) maxDiff = d;
      }
    }
    return maxDiff;
  }

  /// Prueba todas las permutaciones de gallos a rondas y elige la que
  /// minimiza la varianza máxima de peso intra-ronda.
  void _asignarConPermutaciones({
    required List<Gallo> gallos,
    required List<int> rondas,
    required Map<int, List<Gallo>> asignacion,
    int gallosPorRonda = 1,
  }) {
    final perms = _permutaciones(gallos);
    double bestScore = double.infinity;
    List<Gallo>? bestPerm;

    for (final perm in perms) {
      var maxDiff = 0.0;
      for (var i = 0; i < rondas.length && i < perm.length; i++) {
        final d = _calcMaxDiffConAsignacion(asignacion, rondas[i], [perm[i]]);
        if (d > maxDiff) maxDiff = d;
      }
      if (maxDiff < bestScore) {
        bestScore = maxDiff;
        bestPerm = perm;
      }
    }

    if (bestPerm != null) {
      for (var i = 0; i < rondas.length && i < bestPerm.length; i++) {
        asignacion[rondas[i]]!.add(bestPerm[i]);
      }
    }
  }

  /// Asignación balanceada: asignar gallos a rondas compensando el peso
  /// promedio de cada ronda.
  void _asignarBalanceado({
    required List<Gallo> gallos,
    required List<int> rondas,
    required Map<int, List<Gallo>> asignacion,
  }) {
    // Sort gallos by weight desc (heaviest first — assign to lightest round)
    final sorted = List.of(gallos)
      ..sort((a, b) => b.pesoGramos.compareTo(a.pesoGramos));

    final rondaAssigned = <int>{};

    for (final g in sorted) {
      // Find the round with smallest current average peso that hasn't been
      // assigned a gallo from this partido yet
      int? bestRonda;
      double bestAvg = double.infinity;

      for (final r in rondas) {
        if (rondaAssigned.contains(r)) continue;
        // Check no gallo from same partido already in this round
        final existing = asignacion[r]!;
        if (existing.any((e) => e.partidoId == g.partidoId)) continue;

        final currentSum = existing.fold<double>(0, (s, e) => s + e.pesoGramos);
        final avg = existing.isEmpty ? 0.0 : currentSum / existing.length;

        if (avg < bestAvg || bestRonda == null) {
          bestAvg = avg;
          bestRonda = r;
        }
      }

      if (bestRonda != null) {
        asignacion[bestRonda]!.add(g);
        rondaAssigned.add(bestRonda);
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  //  FASE 2: Matching minimax por ronda
  // ═══════════════════════════════════════════════════════

  /// Resuelve matching para cada ronda con objetivo minimax.
  Map<int, List<ParEmparejado>> _resolverMatchingsPorRonda({
    required Map<int, List<Gallo>> asignacion,
    required Set<int> partidosActivos,
    required int numRondasPL,
    int? partidoDobleId,
    int rondaDobleIndex = -1,
    Map<int, int> partidosBye = const {},
  }) {
    final matchings = <int, List<ParEmparejado>>{};
    final conteoEnfrentamientos = <(int, int), int>{};

    for (var r = 0; r < numRondasPL; r++) {
      final gallosRonda = asignacion[r] ?? [];
      if (gallosRonda.isEmpty) {
        matchings[r] = [];
        continue;
      }

      // Determinar partidos activos para esta ronda
      final partidosRonda = <int>{};
      for (final g in gallosRonda) {
        partidosRonda.add(g.partidoId);
      }
      // Remove BYE partido
      if (partidosBye.containsKey(r)) {
        partidosRonda.remove(partidosBye[r]);
      }

      // Build graph — siempre pasar conteo para penalizar repeticiones.
      final graphBuilder = GraphBuilder(
        compadres: compadres,
        gallosUsados: const {},
        conteoEnfrentamientos: conteoEnfrentamientos,
        diferenciaMaxPeso: diferenciaMaxPeso,
      );

      final grafoPriorizado = graphBuilder.construirGrafoPriorizado(
        gallosRonda,
      );

      // Solve minimax
      final isDobleRonda = r == rondaDobleIndex && partidoDobleId != null;

      // Fase 1: intentar sin repetir contrincantes (aristas preferidas).
      List<ParEmparejado> pares;
      if (isDobleRonda) {
        pares = _resolverMinimaxDoble(
          aristas: grafoPriorizado.preferidas,
          partidosRonda: partidosRonda,
          partidoDobleId: partidoDobleId,
        );
      } else {
        pares = _resolverMinimax(
          aristas: grafoPriorizado.preferidas,
          partidosRonda: partidosRonda,
        );
      }

      // Fase 2: si incompleto, incluir aristas de respaldo (con penalización).
      final totalPares = isDobleRonda
          ? (partidosRonda.length + 1) ~/ 2
          : partidosRonda.length ~/ 2;
      if (pares.length < totalPares && grafoPriorizado.respaldo.isNotEmpty) {
        final todasAristas = [
          ...grafoPriorizado.preferidas,
          ...grafoPriorizado.respaldo,
        ];
        todasAristas.sort((a, b) => a.costoTotal.compareTo(b.costoTotal));
        if (isDobleRonda) {
          pares = _resolverMinimaxDoble(
            aristas: todasAristas,
            partidosRonda: partidosRonda,
            partidoDobleId: partidoDobleId,
          );
        } else {
          pares = _resolverMinimax(
            aristas: todasAristas,
            partidosRonda: partidosRonda,
          );
        }
      }

      matchings[r] = pares;

      // Track enfrentamientos for anti-repetition (con conteo)
      for (final p in pares) {
        final a = p.galloA.partidoId < p.galloB.partidoId
            ? p.galloA.partidoId
            : p.galloB.partidoId;
        final b = p.galloA.partidoId < p.galloB.partidoId
            ? p.galloB.partidoId
            : p.galloA.partidoId;
        conteoEnfrentamientos[(a, b)] =
            (conteoEnfrentamientos[(a, b)] ?? 0) + 1;
      }
    }

    return matchings;
  }

  /// Resuelve matching minimax para una ronda normal (cada partido 1 vez).
  List<ParEmparejado> _resolverMinimax({
    required List<AristaGrafo> aristas,
    required Set<int> partidosRonda,
  }) {
    final totalPares = partidosRonda.length ~/ 2;
    if (totalPares == 0) return [];

    // Sort aristas by costoTotal ascending: non-penalized (sin repetición)
    // primero, penalizadas después. Esto garantiza que el solver explore
    // soluciones sin repetir contrincantes antes de considerar repeticiones.
    final sorted = List.of(aristas)
      ..sort((a, b) => a.costoTotal.compareTo(b.costoTotal));

    // Para derbies con muchos partidos, usar greedy + reparación
    // (el backtracking es exponencial y se cuelga).
    if (partidosRonda.length > _umbralBtPartidos) {
      return _matchingGranDerby(aristas: sorted, partidosRonda: partidosRonda);
    }

    // Seedear con greedy para tener cota superior desde el inicio;
    // sin esto el backtracking explora sin poda efectiva.
    final greedySeed = _greedyFallback(
      aristas: sorted,
      partidosRonda: partidosRonda,
    );

    // Backtracking minimax: minimize the maximum diff
    List<ParEmparejado>? mejorSolucion;
    var mejorMaxDiff = double.infinity;
    var mejorSuma = double.infinity;

    if (greedySeed.length == totalPares) {
      mejorSolucion = greedySeed;
      mejorMaxDiff = greedySeed.fold<double>(
        0.0,
        (m, p) => p.diferencia > m ? p.diferencia : m,
      );
      mejorSuma = greedySeed.fold<double>(0.0, (s, p) => s + p.diferencia);
    }
    var iteraciones = 0;

    void buscar(
      int indiceArista,
      List<ParEmparejado> pares,
      Set<int> partidosUsados,
      Set<int> gallosUsados,
      double maxDiffActual,
      double sumaActual,
    ) {
      iteraciones++;
      if (iteraciones > _maxBtIteraciones) return;

      if (pares.length == totalPares) {
        // Better solution? Compare by maxDiff first, then by sum
        if (maxDiffActual < mejorMaxDiff ||
            (maxDiffActual == mejorMaxDiff && sumaActual < mejorSuma)) {
          mejorMaxDiff = maxDiffActual;
          mejorSuma = sumaActual;
          mejorSolucion = List.of(pares);
        }
        return;
      }

      final restantes = sorted.length - indiceArista;
      if (restantes < totalPares - pares.length) return;

      for (var i = indiceArista; i < sorted.length; i++) {
        final ar = sorted[i];
        final pA = ar.galloA.partidoId;
        final pB = ar.galloB.partidoId;

        if (partidosUsados.contains(pA) || partidosUsados.contains(pB)) {
          continue;
        }
        if (gallosUsados.contains(ar.galloA.id) ||
            gallosUsados.contains(ar.galloB.id)) {
          continue;
        }
        if (!partidosRonda.contains(pA) || !partidosRonda.contains(pB)) {
          continue;
        }

        // Pruning: this edge's weight is the new potential max
        final newMax = ar.peso > maxDiffActual ? ar.peso : maxDiffActual;

        // If this edge already exceeds best known maxDiff, skip
        if (newMax >= mejorMaxDiff) continue;

        pares.add(
          ParEmparejado(
            galloA: ar.galloA,
            galloB: ar.galloB,
            diferencia: ar.peso,
          ),
        );
        partidosUsados.add(pA);
        partidosUsados.add(pB);
        gallosUsados.add(ar.galloA.id);
        gallosUsados.add(ar.galloB.id);

        buscar(
          i + 1,
          pares,
          partidosUsados,
          gallosUsados,
          newMax,
          sumaActual + ar.peso,
        );

        pares.removeLast();
        partidosUsados.remove(pA);
        partidosUsados.remove(pB);
        gallosUsados.remove(ar.galloA.id);
        gallosUsados.remove(ar.galloB.id);
      }
    }

    buscar(0, [], {}, {}, 0.0, 0.0);

    if (mejorSolucion != null) return mejorSolucion!;

    // Fallback: greedy by weight (already sorted asc)
    return _greedyFallback(aristas: sorted, partidosRonda: partidosRonda);
  }

  /// Resuelve matching minimax para una ronda con doble pelea.
  List<ParEmparejado> _resolverMinimaxDoble({
    required List<AristaGrafo> aristas,
    required Set<int> partidosRonda,
    required int partidoDobleId,
  }) {
    // totalPares: doble adds 1 extra pair
    final totalPares = (partidosRonda.length + 1) ~/ 2;
    if (totalPares == 0) return [];

    // Sort by costoTotal: sin repetición primero, penalizadas después.
    final sorted = List.of(aristas)
      ..sort((a, b) => a.costoTotal.compareTo(b.costoTotal));

    // Para derbies grandes, usar greedy directamente.
    if (partidosRonda.length > _umbralBtPartidos) {
      return _greedyFallback(aristas: sorted, partidosRonda: partidosRonda);
    }

    List<ParEmparejado>? mejorSolucion;
    var mejorMaxDiff = double.infinity;
    var mejorSuma = double.infinity;
    var iteraciones = 0;

    void buscar(
      int indiceArista,
      List<ParEmparejado> pares,
      Map<int, int> vecesUsado,
      Set<int> gallosUsados,
      double maxDiffActual,
      double sumaActual,
    ) {
      iteraciones++;
      if (iteraciones > _maxBtIteraciones) return;

      if (pares.length == totalPares) {
        if ((vecesUsado[partidoDobleId] ?? 0) == 2 &&
            (maxDiffActual < mejorMaxDiff ||
                (maxDiffActual == mejorMaxDiff && sumaActual < mejorSuma))) {
          mejorMaxDiff = maxDiffActual;
          mejorSuma = sumaActual;
          mejorSolucion = List.of(pares);
        }
        return;
      }

      final restantes = sorted.length - indiceArista;
      if (restantes < totalPares - pares.length) return;

      for (var i = indiceArista; i < sorted.length; i++) {
        final ar = sorted[i];
        final pA = ar.galloA.partidoId;
        final pB = ar.galloB.partidoId;
        final usosA = vecesUsado[pA] ?? 0;
        final usosB = vecesUsado[pB] ?? 0;

        final limA = pA == partidoDobleId ? 2 : 1;
        final limB = pB == partidoDobleId ? 2 : 1;
        if (usosA >= limA || usosB >= limB) continue;

        if (gallosUsados.contains(ar.galloA.id) ||
            gallosUsados.contains(ar.galloB.id)) {
          continue;
        }

        if (!partidosRonda.contains(pA) && pA != partidoDobleId) continue;
        if (!partidosRonda.contains(pB) && pB != partidoDobleId) continue;

        final newMax = ar.peso > maxDiffActual ? ar.peso : maxDiffActual;
        if (newMax >= mejorMaxDiff) continue;

        pares.add(
          ParEmparejado(
            galloA: ar.galloA,
            galloB: ar.galloB,
            diferencia: ar.peso,
          ),
        );
        vecesUsado[pA] = usosA + 1;
        vecesUsado[pB] = usosB + 1;
        gallosUsados.add(ar.galloA.id);
        gallosUsados.add(ar.galloB.id);

        buscar(
          i + 1,
          pares,
          vecesUsado,
          gallosUsados,
          newMax,
          sumaActual + ar.peso,
        );

        pares.removeLast();
        vecesUsado[pA] = usosA;
        vecesUsado[pB] = usosB;
        gallosUsados.remove(ar.galloA.id);
        gallosUsados.remove(ar.galloB.id);
      }
    }

    buscar(0, [], {}, {}, 0.0, 0.0);

    if (mejorSolucion != null) return mejorSolucion!;
    return _greedyFallback(aristas: sorted, partidosRonda: partidosRonda);
  }

  /// Greedy fallback: take lowest-weight edges greedily.
  List<ParEmparejado> _greedyFallback({
    required List<AristaGrafo> aristas,
    required Set<int> partidosRonda,
  }) {
    final pares = <ParEmparejado>[];
    final usados = <int>{};
    final gallosUsados = <int>{};

    for (final ar in aristas) {
      final pA = ar.galloA.partidoId;
      final pB = ar.galloB.partidoId;
      if (usados.contains(pA) || usados.contains(pB)) continue;
      if (gallosUsados.contains(ar.galloA.id) ||
          gallosUsados.contains(ar.galloB.id)) {
        continue;
      }
      if (!partidosRonda.contains(pA) || !partidosRonda.contains(pB)) continue;

      pares.add(
        ParEmparejado(
          galloA: ar.galloA,
          galloB: ar.galloB,
          diferencia: ar.peso,
        ),
      );
      usados.add(pA);
      usados.add(pB);
      gallosUsados.add(ar.galloA.id);
      gallosUsados.add(ar.galloB.id);
    }
    return pares;
  }

  /// Matching para derbies grandes (>16 partidos): greedy seguido de
  /// reparación por caminos aumentantes (augmenting paths).
  ///
  /// Garantiza matching de máxima cardinalidad si existe matching perfecto
  /// en el grafo de partidos.
  List<ParEmparejado> _matchingGranDerby({
    required List<AristaGrafo> aristas,
    required Set<int> partidosRonda,
  }) {
    final totalPares = partidosRonda.length ~/ 2;
    if (totalPares == 0) return [];

    // ── Paso 1: Greedy para matching inicial ──
    final matchPid = <int, int>{};
    final matchArista = <int, AristaGrafo>{};

    for (final a in aristas) {
      final pA = a.galloA.partidoId;
      final pB = a.galloB.partidoId;
      if (!partidosRonda.contains(pA) || !partidosRonda.contains(pB)) continue;
      if (matchPid.containsKey(pA) || matchPid.containsKey(pB)) continue;
      matchPid[pA] = pB;
      matchPid[pB] = pA;
      matchArista[pA] = a;
      matchArista[pB] = a;
    }

    final unmatched = partidosRonda
        .where((p) => !matchPid.containsKey(p))
        .toList();
    if (unmatched.isEmpty) {
      return _buildParesDesdeMatch(matchPid, matchArista, partidosRonda);
    }

    // ── Paso 2: Construir adyacencia entre partidos ──
    // Para cada par de partidos, guardar la mejor arista (menor diff).
    final mejorAristaPar = <(int, int), AristaGrafo>{};
    for (final a in aristas) {
      final pA = a.galloA.partidoId;
      final pB = a.galloB.partidoId;
      if (!partidosRonda.contains(pA) || !partidosRonda.contains(pB)) continue;
      final key = pA < pB ? (pA, pB) : (pB, pA);
      if (!mejorAristaPar.containsKey(key) ||
          a.peso < mejorAristaPar[key]!.peso) {
        mejorAristaPar[key] = a;
      }
    }

    final adj = <int, List<int>>{};
    for (final pid in partidosRonda) {
      adj[pid] = [];
    }
    for (final key in mejorAristaPar.keys) {
      adj[key.$1]!.add(key.$2);
      adj[key.$2]!.add(key.$1);
    }

    // ── Paso 3: Caminos aumentantes para completar matching ──
    for (final start in unmatched) {
      if (matchPid.containsKey(start)) continue;

      // BFS: niveles alternan arista libre → arista emparejada
      final parent = <int, int>{};
      final visited = <int>{start};
      final queue = <int>[start];
      int? freeEnd;

      while (queue.isNotEmpty && freeEnd == null) {
        final u = queue.removeAt(0);
        for (final v in adj[u]!) {
          if (visited.contains(v)) continue;
          visited.add(v);
          parent[v] = u;
          if (!matchPid.containsKey(v)) {
            freeEnd = v;
            break;
          }
          // v emparejado → seguir arista emparejada a su partner w
          final w = matchPid[v]!;
          if (!visited.contains(w)) {
            visited.add(w);
            parent[w] = v;
            queue.add(w);
          }
        }
      }

      if (freeEnd != null) {
        // Recorrer camino aumentante y voltear emparejamientos:
        // start -(libre)→ n1 -(match)→ m1 -(libre)→ ... -(libre)→ freeEnd
        var cur = freeEnd;
        while (true) {
          final prev = parent[cur]!;
          final key = prev < cur ? (prev, cur) : (cur, prev);
          final arista = mejorAristaPar[key]!;

          matchPid[cur] = prev;
          matchPid[prev] = cur;
          matchArista[cur] = arista;
          matchArista[prev] = arista;

          if (prev == start) break;
          final prevPrev = parent[prev]!;
          cur = prevPrev;
        }
      }
    }

    return _buildParesDesdeMatch(matchPid, matchArista, partidosRonda);
  }

  /// Convierte el mapa de matching a lista de [ParEmparejado].
  List<ParEmparejado> _buildParesDesdeMatch(
    Map<int, int> matchPid,
    Map<int, AristaGrafo> matchArista,
    Set<int> partidosRonda,
  ) {
    final pares = <ParEmparejado>[];
    final seen = <int>{};
    for (final pid in partidosRonda) {
      if (seen.contains(pid) || !matchPid.containsKey(pid)) continue;
      final partner = matchPid[pid]!;
      seen.add(pid);
      seen.add(partner);
      final a = matchArista[pid]!;
      pares.add(
        ParEmparejado(galloA: a.galloA, galloB: a.galloB, diferencia: a.peso),
      );
    }
    return pares;
  }

  // ═══════════════════════════════════════════════════════
  //  FASE 3: Mejora local (swap entre rondas)
  // ═══════════════════════════════════════════════════════

  /// Mejora la solución intercambiando gallos entre rondas.
  ///
  /// Para cada par de partidos, intenta intercambiar sus gallos asignados
  /// a dos rondas diferentes. Si el re-matching de esas rondas produce
  /// un maxDiff global menor, acepta el swap.
  ResultadoGlobal _mejoraLocal({
    required Map<int, List<Gallo>> asignacion,
    required Map<int, List<ParEmparejado>> matchings,
    required List<Gallo> gallosPL,
    required Set<int> partidosActivos,
    required int numRondasPL,
    int? partidoDobleId,
    int rondaDobleIndex = -1,
    Map<int, int> partidosBye = const {},
  }) {
    // Con muchos partidos la mejora local es muy costosa (re-solves × swaps);
    // saltar directamente para derbies grandes.
    if (partidosActivos.length > _umbralBtPartidos) {
      return ResultadoGlobal(
        asignacion: asignacion,
        matchings: matchings,
        maxDiferencia: _calcGlobalMaxDiff(matchings),
        sumaTotal: _calcGlobalSum(matchings),
      );
    }

    var currentMaxDiff = _calcGlobalMaxDiff(matchings);
    var currentSum = _calcGlobalSum(matchings);
    var mejoro = true;
    var totalIter = 0;

    while (mejoro && totalIter < _maxSwapIteraciones) {
      mejoro = false;

      // Collect all partido IDs that have gallos in multiple rounds
      final partidoRondas = <int, List<int>>{}; // pid → list of ronda indices
      for (var r = 0; r < numRondasPL; r++) {
        for (final g in asignacion[r]!) {
          partidoRondas.putIfAbsent(g.partidoId, () => []).add(r);
        }
      }

      final pids = partidoRondas.keys.toList();

      for (var i = 0; i < pids.length && !mejoro; i++) {
        final pidA = pids[i];
        for (var j = i + 1; j < pids.length && !mejoro; j++) {
          final pidB = pids[j];
          totalIter++;
          if (totalIter > _maxSwapIteraciones) break;

          // Try swapping gallos between two rounds for these partidos
          final rondasA = partidoRondas[pidA]!;
          final rondasB = partidoRondas[pidB]!;

          // Find rounds where both partidos have a gallo
          final shared = rondasA.toSet().intersection(rondasB.toSet()).toList();
          if (shared.length < 2) continue;

          for (var ri = 0; ri < shared.length && !mejoro; ri++) {
            for (var rj = ri + 1; rj < shared.length && !mejoro; rj++) {
              final r1 = shared[ri];
              final r2 = shared[rj];

              // Skip doble round (too complex to swap)
              if (r1 == rondaDobleIndex || r2 == rondaDobleIndex) continue;

              // Find gallo of pidA in r1 and r2
              final galloaR1 = asignacion[r1]!
                  .where((g) => g.partidoId == pidA)
                  .firstOrNull;
              final galloaR2 = asignacion[r2]!
                  .where((g) => g.partidoId == pidA)
                  .firstOrNull;
              final gallobR1 = asignacion[r1]!
                  .where((g) => g.partidoId == pidB)
                  .firstOrNull;
              final gallobR2 = asignacion[r2]!
                  .where((g) => g.partidoId == pidB)
                  .firstOrNull;

              if (galloaR1 == null ||
                  galloaR2 == null ||
                  gallobR1 == null ||
                  gallobR2 == null) {
                continue;
              }

              // Swap: pidA's gallo in r1 goes to r2 and vice versa
              //        pidB's gallo in r1 goes to r2 and vice versa
              // Actually we swap BOTH partidos' gallos between the two rounds
              _doSwap(asignacion, r1, r2, pidA, galloaR1, galloaR2);
              _doSwap(asignacion, r1, r2, pidB, gallobR1, gallobR2);

              // Re-solve matchings for r1 and r2
              final newMatchings = Map<int, List<ParEmparejado>>.of(matchings);
              final conteoEnfPrevios = _buildConteoEnfrentamientosExcluding(
                matchings,
                {r1, r2},
              );

              for (final r in [r1, r2]) {
                final gallosRonda = asignacion[r]!;
                final partidosRonda = gallosRonda
                    .map((g) => g.partidoId)
                    .toSet();
                if (partidosBye.containsKey(r)) {
                  partidosRonda.remove(partidosBye[r]);
                }

                final gb = GraphBuilder(
                  compadres: compadres,
                  gallosUsados: const {},
                  conteoEnfrentamientos: conteoEnfPrevios,
                  diferenciaMaxPeso: diferenciaMaxPeso,
                );

                final grafoPri = gb.construirGrafoPriorizado(gallosRonda);

                // Fase 1: sin repetir
                var pares = _resolverMinimax(
                  aristas: grafoPri.preferidas,
                  partidosRonda: partidosRonda,
                );

                // Fase 2: con respaldo si incompleto
                final totalParesR = partidosRonda.length ~/ 2;
                if (pares.length < totalParesR &&
                    grafoPri.respaldo.isNotEmpty) {
                  final todasArs = [
                    ...grafoPri.preferidas,
                    ...grafoPri.respaldo,
                  ];
                  todasArs.sort((a, b) => a.costoTotal.compareTo(b.costoTotal));
                  pares = _resolverMinimax(
                    aristas: todasArs,
                    partidosRonda: partidosRonda,
                  );
                }
                newMatchings[r] = pares;

                // Update conteoEnfPrevios for next round
                for (final p in pares) {
                  final a = p.galloA.partidoId < p.galloB.partidoId
                      ? p.galloA.partidoId
                      : p.galloB.partidoId;
                  final b = p.galloA.partidoId < p.galloB.partidoId
                      ? p.galloB.partidoId
                      : p.galloA.partidoId;
                  conteoEnfPrevios[(a, b)] =
                      (conteoEnfPrevios[(a, b)] ?? 0) + 1;
                }
              }

              final newMaxDiff = _calcGlobalMaxDiff(newMatchings);
              final newSum = _calcGlobalSum(newMatchings);
              final newReps = _contarRepeticionesGlobal(newMatchings);
              final curReps = _contarRepeticionesGlobal(matchings);

              // Aceptar swap si mejora maxDiff, o a igual maxDiff reduce
              // repeticiones, o a igual maxDiff e igual repeticiones
              // reduce la suma total.
              final mejoraSolucion =
                  newMaxDiff < currentMaxDiff ||
                  (newMaxDiff == currentMaxDiff && newReps < curReps) ||
                  (newMaxDiff == currentMaxDiff &&
                      newReps == curReps &&
                      newSum < currentSum);

              if (mejoraSolucion) {
                // Accept swap
                currentMaxDiff = newMaxDiff;
                currentSum = newSum;
                matchings.clear();
                matchings.addAll(newMatchings);
                mejoro = true;
              } else {
                // Revert swap
                _doSwap(asignacion, r1, r2, pidA, galloaR2, galloaR1);
                _doSwap(asignacion, r1, r2, pidB, gallobR2, gallobR1);
              }
            }
          }
        }
      }
    }

    return ResultadoGlobal(
      asignacion: asignacion,
      matchings: matchings,
      maxDiferencia: currentMaxDiff,
      sumaTotal: currentSum,
    );
  }

  /// Swap a partido's gallo between two rounds.
  void _doSwap(
    Map<int, List<Gallo>> asignacion,
    int r1,
    int r2,
    int partidoId,
    Gallo galloR1,
    Gallo galloR2,
  ) {
    asignacion[r1]!.remove(galloR1);
    asignacion[r1]!.add(galloR2);
    asignacion[r2]!.remove(galloR2);
    asignacion[r2]!.add(galloR1);
  }

  /// Build map of enfrentamientos conteo excluding certain rounds.
  Map<(int, int), int> _buildConteoEnfrentamientosExcluding(
    Map<int, List<ParEmparejado>> matchings,
    Set<int> excludeRounds,
  ) {
    final conteo = <(int, int), int>{};
    for (final entry in matchings.entries) {
      if (excludeRounds.contains(entry.key)) continue;
      for (final p in entry.value) {
        final a = p.galloA.partidoId < p.galloB.partidoId
            ? p.galloA.partidoId
            : p.galloB.partidoId;
        final b = p.galloA.partidoId < p.galloB.partidoId
            ? p.galloB.partidoId
            : p.galloA.partidoId;
        conteo[(a, b)] = (conteo[(a, b)] ?? 0) + 1;
      }
    }
    return conteo;
  }

  // ═══════════════════════════════════════════════════════
  //  Utilidades
  // ═══════════════════════════════════════════════════════

  double _calcGlobalMaxDiff(Map<int, List<ParEmparejado>> matchings) {
    var maxDiff = 0.0;
    for (final pares in matchings.values) {
      for (final p in pares) {
        if (p.diferencia > maxDiff) maxDiff = p.diferencia;
      }
    }
    return maxDiff;
  }

  double _calcGlobalSum(Map<int, List<ParEmparejado>> matchings) {
    var sum = 0.0;
    for (final pares in matchings.values) {
      for (final p in pares) {
        sum += p.diferencia;
      }
    }
    return sum;
  }

  /// Cuenta cuántos pares de partidos se repiten entre rondas.
  int _contarRepeticionesGlobal(Map<int, List<ParEmparejado>> matchings) {
    final conteo = <(int, int), int>{};
    for (final pares in matchings.values) {
      for (final p in pares) {
        final a = p.galloA.partidoId < p.galloB.partidoId
            ? p.galloA.partidoId
            : p.galloB.partidoId;
        final b = p.galloA.partidoId < p.galloB.partidoId
            ? p.galloB.partidoId
            : p.galloA.partidoId;
        conteo[(a, b)] = (conteo[(a, b)] ?? 0) + 1;
      }
    }
    // Contar total de repeticiones (veces > 1).
    var reps = 0;
    for (final v in conteo.values) {
      if (v > 1) reps += v - 1;
    }
    return reps;
  }

  /// Generate all permutations of a list.
  List<List<Gallo>> _permutaciones(List<Gallo> items) {
    if (items.isEmpty) return [[]];
    if (items.length == 1) return [List.of(items)];

    final result = <List<Gallo>>[];
    for (var i = 0; i < items.length; i++) {
      final rest = [...items.sublist(0, i), ...items.sublist(i + 1)];
      for (final perm in _permutaciones(rest)) {
        result.add([items[i], ...perm]);
      }
    }
    return result;
  }

  /// Generate all combinations of k items from a list.
  List<List<Gallo>> _combinaciones(List<Gallo> items, int k) {
    if (k == 0) return [[]];
    if (items.length < k) return [];

    final result = <List<Gallo>>[];
    for (var i = 0; i <= items.length - k; i++) {
      final rest = items.sublist(i + 1);
      for (final combo in _combinaciones(rest, k - 1)) {
        result.add([items[i], ...combo]);
      }
    }
    return result;
  }
}
