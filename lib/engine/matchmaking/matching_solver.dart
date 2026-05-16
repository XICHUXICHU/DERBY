import '../../domain/domain.dart';
import 'graph_builder.dart';

/// Par emparejado: dos gallos que se enfrentarán.
class ParEmparejado {
  final Gallo galloA;
  final Gallo galloB;
  final double diferencia;

  const ParEmparejado({
    required this.galloA,
    required this.galloB,
    required this.diferencia,
  });

  @override
  String toString() =>
      'Par(${galloA.anillo} vs ${galloB.anillo}, diff=${diferencia.toStringAsFixed(1)}g)';
}

/// Resultado del solver de matching.
class ResultadoMatching {
  final List<ParEmparejado> pares;
  final double sumaTotal;
  final List<int>
  partidosSinEmparejar; // IDs de partidos que no pudieron emparejarse
  final bool usaRepeticiones; // true si tuvo que repetir contrincantes

  const ResultadoMatching({
    required this.pares,
    required this.sumaTotal,
    this.partidosSinEmparejar = const [],
    this.usaRepeticiones = false,
  });

  bool get esCompleto => partidosSinEmparejar.isEmpty;

  @override
  String toString() =>
      'Matching(pares=${pares.length}, suma=${sumaTotal.toStringAsFixed(1)}g, '
      'completo=$esCompleto, repeticiones=$usaRepeticiones)';
}

/// Solver de matching mínimo para enfrentamientos de gallos.
///
/// Implementa:
/// 1. Greedy inicial (aristas ordenadas por peso)
/// 2. Backtracking con poda para encontrar solución óptima
/// 3. Validación final de restricciones
///
/// Puro Dart. No depende de Flutter ni Drift.
class MatchingSolver {
  /// Umbral de partidos para usar backtracking completo vs greedy.
  /// Con >20 partidos el backtracking puede ser lento.
  static const int _umbralBacktracking = 20;

  /// Límite de iteraciones para backtracking (evitar loops infinitos).
  static const int _maxIteraciones = 500000;

  /// Resuelve el matching para una ronda.
  ///
  /// [gallosDisponibles]: gallos que pueden pelear en esta ronda.
  /// [partidosActivos]: IDs de partidos que deben ser emparejados.
  /// [graphBuilder]: constructor de grafo con restricciones cargadas.
  /// [permitirRepeticiones]: si true, usa directamente todas las aristas
  ///   (incluye repetir contrincantes previos) sin intentar Fase 1 primero.
  ///
  /// Lanza [MatchingImposibleException] si no existe solución.
  ResultadoMatching resolver({
    required List<Gallo> gallosDisponibles,
    required Set<int> partidosActivos,
    required GraphBuilder graphBuilder,
    required int rondaNumero,
    bool permitirRepeticiones = false,
  }) {
    if (gallosDisponibles.isEmpty) {
      throw MatchingImposibleException(
        rondaNumero: rondaNumero,
        gallosDisponibles: 0,
        restriccionesActivas: 0,
        detalle: 'No hay gallos disponibles.',
      );
    }

    // Agrupar gallos por partido
    final gallosPorPartido = <int, List<Gallo>>{};
    for (final g in gallosDisponibles) {
      gallosPorPartido.putIfAbsent(g.partidoId, () => []).add(g);
    }

    // Verificar que cada partido activo tenga al menos 1 gallo disponible
    final partidosSinGallo = <int>[];
    for (final pid in partidosActivos) {
      if (!gallosPorPartido.containsKey(pid) ||
          gallosPorPartido[pid]!.isEmpty) {
        partidosSinGallo.add(pid);
      }
    }

    // Si se permiten repeticiones, seguir al flujo 2-fases normal.
    // La fase 1 intenta sin repetir; la fase 2 agrega respaldo con
    // penalización. Esto minimiza repeticiones incluso cuando están
    // permitidas como fallback.

    // Fase 1: Intentar con aristas preferidas (sin repetir contrincantes)
    final grafoPriorizado = graphBuilder.construirGrafoPriorizado(
      gallosDisponibles,
    );

    var resultado = _resolverConAristas(
      aristas: grafoPriorizado.preferidas,
      partidosActivos: partidosActivos,
      gallosPorPartido: gallosPorPartido,
      rondaNumero: rondaNumero,
    );

    if (resultado.esCompleto) {
      return resultado;
    }

    // Fase 2: Incluir aristas de respaldo (permite repetir contrincantes)
    // Ordenar por costoTotal: respaldo lleva penalización que las empuja al final.
    final todasAristas = [
      ...grafoPriorizado.preferidas,
      ...grafoPriorizado.respaldo,
    ];
    todasAristas.sort((a, b) => a.costoTotal.compareTo(b.costoTotal));

    resultado = _resolverConAristas(
      aristas: todasAristas,
      partidosActivos: partidosActivos,
      gallosPorPartido: gallosPorPartido,
      rondaNumero: rondaNumero,
    );

    if (resultado.pares.isNotEmpty) {
      return ResultadoMatching(
        pares: resultado.pares,
        sumaTotal: resultado.sumaTotal,
        partidosSinEmparejar: resultado.partidosSinEmparejar,
        usaRepeticiones: true,
      );
    }
    
    // Devolvemos el resultado con fallos, donde todos no fueron emparejados.
    return ResultadoMatching(
        pares: [],
        sumaTotal: 0.0,
        partidosSinEmparejar: partidosActivos.toList(),
        usaRepeticiones: true,
    );

  }

  /// Resuelve con un conjunto dado de aristas.
  ResultadoMatching _resolverConAristas({
    required List<AristaGrafo> aristas,
    required Set<int> partidosActivos,
    required Map<int, List<Gallo>> gallosPorPartido,
    required int rondaNumero,
  }) {
    final numPartidos = partidosActivos.length;

    // Si hay pocos partidos, usar backtracking para solución óptima
    if (numPartidos <= _umbralBacktracking) {
      final resultado = _backtracking(
        aristas: aristas,
        partidosActivos: partidosActivos,
        totalPares: numPartidos ~/ 2,
      );
      if (resultado != null) {
        return resultado;
      }
    }

    // Greedy + augmenting-path repair para derbys grandes
    return _greedyConReparacion(
      aristas: aristas,
      partidosActivos: partidosActivos,
    );
  }

  /// Algoritmo greedy: toma aristas por peso ascendente.
  ResultadoMatching _greedy({
    required List<AristaGrafo> aristas,
    required Set<int> partidosActivos,
  }) {
    final pares = <ParEmparejado>[];
    final partidosEmparejados = <int>{};
    final gallosUsadosEnRonda = <int>{};
    var sumaTotal = 0.0;

    for (final arista in aristas) {
      final pA = arista.galloA.partidoId;
      final pB = arista.galloB.partidoId;

      // Verificar que ambos partidos son activos y no emparejados aún
      if (!partidosActivos.contains(pA) || !partidosActivos.contains(pB)) {
        continue;
      }
      if (partidosEmparejados.contains(pA) ||
          partidosEmparejados.contains(pB)) {
        continue;
      }
      // Verificar gallos no usados en esta ronda
      if (gallosUsadosEnRonda.contains(arista.galloA.id) ||
          gallosUsadosEnRonda.contains(arista.galloB.id)) {
        continue;
      }

      pares.add(
        ParEmparejado(
          galloA: arista.galloA,
          galloB: arista.galloB,
          diferencia: arista.peso,
        ),
      );
      partidosEmparejados.add(pA);
      partidosEmparejados.add(pB);
      gallosUsadosEnRonda.add(arista.galloA.id);
      gallosUsadosEnRonda.add(arista.galloB.id);
      sumaTotal += arista.peso;
    }

    final sinEmparejar = partidosActivos
        .where((p) => !partidosEmparejados.contains(p))
        .toList();

    return ResultadoMatching(
      pares: pares,
      sumaTotal: sumaTotal,
      partidosSinEmparejar: sinEmparejar,
    );
  }

  /// Greedy seguido de reparación por caminos aumentantes (augmenting paths)
  /// para maximizar la cardinalidad del matching.
  ///
  /// El greedy puro puede dejar partidos varados por restricciones de peso;
  /// la reparación intenta reasignar emparejamientos para acomodar a los
  /// partidos sobrantes.
  ResultadoMatching _greedyConReparacion({
    required List<AristaGrafo> aristas,
    required Set<int> partidosActivos,
  }) {
    final totalPares = partidosActivos.length ~/ 2;
    if (totalPares == 0) {
      return ResultadoMatching(
        pares: const [],
        sumaTotal: 0,
        partidosSinEmparejar: partidosActivos.toList(),
      );
    }

    // Paso 1: Greedy inicial
    final matchPid = <int, int>{};
    final matchArista = <int, AristaGrafo>{};

    for (final a in aristas) {
      final pA = a.galloA.partidoId;
      final pB = a.galloB.partidoId;
      if (!partidosActivos.contains(pA) || !partidosActivos.contains(pB)) {
        continue;
      }
      if (matchPid.containsKey(pA) || matchPid.containsKey(pB)) continue;
      matchPid[pA] = pB;
      matchPid[pB] = pA;
      matchArista[pA] = a;
      matchArista[pB] = a;
    }

    final unmatched = partidosActivos
        .where((p) => !matchPid.containsKey(p))
        .toList();

    if (unmatched.length <= (partidosActivos.length.isOdd ? 1 : 0)) {
      return _buildResultadoDesdeMatch(matchPid, matchArista, partidosActivos);
    }

    // Paso 2: Adyacencia por partidos (mejor arista por par)
    final mejorAristaPar = <(int, int), AristaGrafo>{};
    for (final a in aristas) {
      final pA = a.galloA.partidoId;
      final pB = a.galloB.partidoId;
      if (!partidosActivos.contains(pA) || !partidosActivos.contains(pB)) {
        continue;
      }
      final key = pA < pB ? (pA, pB) : (pB, pA);
      if (!mejorAristaPar.containsKey(key) ||
          a.peso < mejorAristaPar[key]!.peso) {
        mejorAristaPar[key] = a;
      }
    }

    final adj = <int, List<int>>{};
    for (final pid in partidosActivos) {
      adj[pid] = [];
    }
    for (final key in mejorAristaPar.keys) {
      adj[key.$1]!.add(key.$2);
      adj[key.$2]!.add(key.$1);
    }

    // Paso 3: Caminos aumentantes (BFS)
    for (final start in unmatched) {
      if (matchPid.containsKey(start)) continue;

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
          final w = matchPid[v]!;
          if (!visited.contains(w)) {
            visited.add(w);
            parent[w] = v;
            queue.add(w);
          }
        }
      }

      if (freeEnd != null) {
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
          cur = parent[prev]!;
        }
      }
    }

    return _buildResultadoDesdeMatch(matchPid, matchArista, partidosActivos);
  }

  /// Convierte mapa de matching a [ResultadoMatching].
  ResultadoMatching _buildResultadoDesdeMatch(
    Map<int, int> matchPid,
    Map<int, AristaGrafo> matchArista,
    Set<int> partidosActivos,
  ) {
    final pares = <ParEmparejado>[];
    final seen = <int>{};
    var sumaTotal = 0.0;
    for (final pid in partidosActivos) {
      if (seen.contains(pid) || !matchPid.containsKey(pid)) continue;
      final partner = matchPid[pid]!;
      seen.add(pid);
      seen.add(partner);
      final a = matchArista[pid]!;
      pares.add(
        ParEmparejado(galloA: a.galloA, galloB: a.galloB, diferencia: a.peso),
      );
      sumaTotal += a.peso;
    }
    final sinEmparejar = partidosActivos
        .where((p) => !seen.contains(p))
        .toList();
    return ResultadoMatching(
      pares: pares,
      sumaTotal: sumaTotal,
      partidosSinEmparejar: sinEmparejar,
    );
  }

  /// Resuelve el matching para una ronda con objetivo **minimax**:
  /// minimiza la diferencia MÁXIMA individual, desempatando por suma total.
  ///
  /// Misma interfaz que [resolver], pero cambia el criterio de optimidad.
  ResultadoMatching resolverMinimax({
    required List<Gallo> gallosDisponibles,
    required Set<int> partidosActivos,
    required GraphBuilder graphBuilder,
    required int rondaNumero,
    bool permitirRepeticiones = false,
  }) {
    if (gallosDisponibles.isEmpty) {
      throw MatchingImposibleException(
        rondaNumero: rondaNumero,
        gallosDisponibles: 0,
        restriccionesActivas: 0,
        detalle: 'No hay gallos disponibles.',
      );
    }

    final gallosPorPartido = <int, List<Gallo>>{};
    for (final g in gallosDisponibles) {
      gallosPorPartido.putIfAbsent(g.partidoId, () => []).add(g);
    }

    List<AristaGrafo> aristas;
    if (permitirRepeticiones) {
      aristas = graphBuilder.construirGrafo(gallosDisponibles);
    } else {
      final priorizadas = graphBuilder.construirGrafoPriorizado(
        gallosDisponibles,
      );
      aristas = [...priorizadas.preferidas, ...priorizadas.respaldo];
      aristas.sort((a, b) => a.costoTotal.compareTo(b.costoTotal));
    }

    final numPartidos = partidosActivos.length;
    if (numPartidos <= _umbralBacktracking) {
      final resultado = _backtrackingMinimax(
        aristas: aristas,
        partidosActivos: partidosActivos,
        totalPares: numPartidos ~/ 2,
      );
      if (resultado != null) return resultado;
    }

    // Greedy fallback
    return _greedy(aristas: aristas, partidosActivos: partidosActivos);
  }

  /// Backtracking minimax: busca matching que minimiza la diferencia MÁXIMA.
  /// Usa [costoTotal] para ordering/pruning para desfavorecer repeticiones,
  /// pero el criterio minimax se basa en [peso] (diferencia real).
  ResultadoMatching? _backtrackingMinimax({
    required List<AristaGrafo> aristas,
    required Set<int> partidosActivos,
    required int totalPares,
  }) {
    if (totalPares == 0) {
      return const ResultadoMatching(pares: [], sumaTotal: 0);
    }

    List<ParEmparejado>? mejorSolucion;
    var mejorMaxDiff = double.infinity;
    var mejorSuma = double.infinity;
    var iteraciones = 0;

    void buscar(
      int indiceArista,
      List<ParEmparejado> paresActuales,
      Set<int> partidosUsados,
      Set<int> gallosUsados,
      double maxDiffActual,
      double sumaActual,
    ) {
      iteraciones++;
      if (iteraciones > _maxIteraciones) return;

      if (paresActuales.length == totalPares) {
        if (maxDiffActual < mejorMaxDiff ||
            (maxDiffActual == mejorMaxDiff && sumaActual < mejorSuma)) {
          mejorMaxDiff = maxDiffActual;
          mejorSuma = sumaActual;
          mejorSolucion = List.of(paresActuales);
        }
        return;
      }

      final paresRestantes = totalPares - paresActuales.length;
      final aristasRestantes = aristas.length - indiceArista;
      if (aristasRestantes < paresRestantes) return;

      for (var i = indiceArista; i < aristas.length; i++) {
        final arista = aristas[i];
        final pA = arista.galloA.partidoId;
        final pB = arista.galloB.partidoId;

        if (partidosUsados.contains(pA) || partidosUsados.contains(pB)) {
          continue;
        }
        if (gallosUsados.contains(arista.galloA.id) ||
            gallosUsados.contains(arista.galloB.id)) {
          continue;
        }
        if (!partidosActivos.contains(pA) || !partidosActivos.contains(pB)) {
          continue;
        }

        // Minimax usa peso real para el criterio, costoTotal para desempate
        final newMax = arista.peso > maxDiffActual
            ? arista.peso
            : maxDiffActual;
        if (newMax > mejorMaxDiff) continue;
        if (newMax == mejorMaxDiff &&
            sumaActual + arista.costoTotal >= mejorSuma) {
          continue;
        }

        paresActuales.add(
          ParEmparejado(
            galloA: arista.galloA,
            galloB: arista.galloB,
            diferencia: arista.peso, // peso REAL para display
          ),
        );
        partidosUsados.add(pA);
        partidosUsados.add(pB);
        gallosUsados.add(arista.galloA.id);
        gallosUsados.add(arista.galloB.id);

        buscar(
          i + 1,
          paresActuales,
          partidosUsados,
          gallosUsados,
          newMax,
          sumaActual + arista.costoTotal,
        );

        paresActuales.removeLast();
        partidosUsados.remove(pA);
        partidosUsados.remove(pB);
        gallosUsados.remove(arista.galloA.id);
        gallosUsados.remove(arista.galloB.id);
      }
    }

    buscar(0, [], {}, {}, 0.0, 0.0);

    if (mejorSolucion != null) {
      final sumaReal = mejorSolucion!.fold(
        0.0,
        (sum, p) => sum + p.diferencia,
      );
      return ResultadoMatching(pares: mejorSolucion!, sumaTotal: sumaReal);
    }
    return null;
  }

  /// Backtracking con poda: busca matching perfecto de costo mínimo.
  ///
  /// Explora aristas en orden de costoTotal (peso + penalización),
  /// intentando emparejar exactamente [totalPares] partidos.
  /// Usa [costoTotal] para optimización (penaliza repeticiones),
  /// y [peso] para el diff real en el resultado.
  ResultadoMatching? _backtracking({
    required List<AristaGrafo> aristas,
    required Set<int> partidosActivos,
    required int totalPares,
  }) {
    if (totalPares == 0) {
      return const ResultadoMatching(pares: [], sumaTotal: 0);
    }

    List<ParEmparejado>? mejorSolucion;
    var mejorCosto = double.infinity;
    var iteraciones = 0;

    void buscar(
      int indiceArista,
      List<ParEmparejado> paresActuales,
      Set<int> partidosUsados,
      Set<int> gallosUsados,
      double costoActual,
    ) {
      iteraciones++;
      if (iteraciones > _maxIteraciones) return;

      if (paresActuales.length == totalPares) {
        if (costoActual < mejorCosto) {
          mejorCosto = costoActual;
          mejorSolucion = List.of(paresActuales);
        }
        return;
      }

      final paresRestantes = totalPares - paresActuales.length;
      final aristasRestantes = aristas.length - indiceArista;
      if (aristasRestantes < paresRestantes) return;

      if (costoActual >= mejorCosto) return;

      for (var i = indiceArista; i < aristas.length; i++) {
        final arista = aristas[i];
        final pA = arista.galloA.partidoId;
        final pB = arista.galloB.partidoId;

        if (partidosUsados.contains(pA) || partidosUsados.contains(pB)) {
          continue;
        }
        if (gallosUsados.contains(arista.galloA.id) ||
            gallosUsados.contains(arista.galloB.id)) {
          continue;
        }
        if (!partidosActivos.contains(pA) || !partidosActivos.contains(pB)) {
          continue;
        }

        // Usar costoTotal (peso + penalización) para poda y optimización
        if (costoActual + arista.costoTotal >= mejorCosto) continue;

        paresActuales.add(
          ParEmparejado(
            galloA: arista.galloA,
            galloB: arista.galloB,
            diferencia: arista.peso, // peso REAL para display
          ),
        );
        partidosUsados.add(pA);
        partidosUsados.add(pB);
        gallosUsados.add(arista.galloA.id);
        gallosUsados.add(arista.galloB.id);

        buscar(
          i + 1,
          paresActuales,
          partidosUsados,
          gallosUsados,
          costoActual + arista.costoTotal,
        );

        paresActuales.removeLast();
        partidosUsados.remove(pA);
        partidosUsados.remove(pB);
        gallosUsados.remove(arista.galloA.id);
        gallosUsados.remove(arista.galloB.id);
      }
    }

    buscar(0, [], {}, {}, 0.0);

    if (mejorSolucion != null) {
      // Calcular suma real (sin penalizaciones) para display
      final sumaReal = mejorSolucion!.fold(
        0.0,
        (sum, p) => sum + p.diferencia,
      );
      return ResultadoMatching(pares: mejorSolucion!, sumaTotal: sumaReal);
    }

    return null;
  }
}
