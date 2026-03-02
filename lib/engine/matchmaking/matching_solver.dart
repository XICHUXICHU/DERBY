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

    // Si se permiten repeticiones, usar todas las aristas directamente.
    if (permitirRepeticiones) {
      final todasAristas = graphBuilder.construirGrafo(gallosDisponibles);

      final resultado = _resolverConAristas(
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

      throw MatchingImposibleException(
        rondaNumero: rondaNumero,
        gallosDisponibles: gallosDisponibles.length,
        restriccionesActivas: todasAristas.length,
        detalle: 'No se encontró matching válido (repeticiones permitidas).',
      );
    }

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
    final todasAristas = [
      ...grafoPriorizado.preferidas,
      ...grafoPriorizado.respaldo,
    ];
    todasAristas.sort((a, b) => a.peso.compareTo(b.peso));

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

    throw MatchingImposibleException(
      rondaNumero: rondaNumero,
      gallosDisponibles: gallosDisponibles.length,
      restriccionesActivas: todasAristas.length,
      detalle: 'No se encontró matching válido ni con repeticiones.',
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

    // Greedy como respaldo o para derbys grandes
    return _greedy(aristas: aristas, partidosActivos: partidosActivos);
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
      aristas.sort((a, b) => a.peso.compareTo(b.peso));
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

        final newMax = arista.peso > maxDiffActual
            ? arista.peso
            : maxDiffActual;
        if (newMax >= mejorMaxDiff) continue;

        paresActuales.add(
          ParEmparejado(
            galloA: arista.galloA,
            galloB: arista.galloB,
            diferencia: arista.peso,
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
          sumaActual + arista.peso,
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
      return ResultadoMatching(pares: mejorSolucion!, sumaTotal: mejorSuma);
    }
    return null;
  }

  /// Backtracking con poda: busca matching perfecto de costo mínimo.
  ///
  /// Explora aristas en orden de peso, intentando emparejar
  /// exactamente [totalPares] partidos.
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

      // ¿Solución completa?
      if (paresActuales.length == totalPares) {
        if (costoActual < mejorCosto) {
          mejorCosto = costoActual;
          mejorSolucion = List.of(paresActuales);
        }
        return;
      }

      // Poda: ¿quedan suficientes aristas?
      final paresRestantes = totalPares - paresActuales.length;
      final aristasRestantes = aristas.length - indiceArista;
      if (aristasRestantes < paresRestantes) return;

      // Poda por costo: si el costo actual ya supera al mejor, cortar
      if (costoActual >= mejorCosto) return;

      for (var i = indiceArista; i < aristas.length; i++) {
        final arista = aristas[i];
        final pA = arista.galloA.partidoId;
        final pB = arista.galloB.partidoId;

        // Verificar disponibilidad
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

        // Poda: cota inferior optimista
        // El mejor caso restante es 0 diferencia para todos los pares restantes
        // (ya usamos el costo actual como cota)
        if (costoActual + arista.peso >= mejorCosto) continue;

        // Tomar esta arista
        paresActuales.add(
          ParEmparejado(
            galloA: arista.galloA,
            galloB: arista.galloB,
            diferencia: arista.peso,
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
          costoActual + arista.peso,
        );

        // Deshacer
        paresActuales.removeLast();
        partidosUsados.remove(pA);
        partidosUsados.remove(pB);
        gallosUsados.remove(arista.galloA.id);
        gallosUsados.remove(arista.galloB.id);
      }
    }

    buscar(0, [], {}, {}, 0.0);

    if (mejorSolucion != null) {
      return ResultadoMatching(pares: mejorSolucion!, sumaTotal: mejorCosto);
    }

    return null;
  }
}
