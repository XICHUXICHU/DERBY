import '../../domain/entities/gallo.dart';
import '../../domain/entities/partido.dart';
import '../../domain/entities/compadre.dart';
import '../../domain/entities/ronda.dart';
import '../../domain/entities/sorteo_resultado.dart';
import '../../engine/derby_engine.dart';

/// Caso de uso: Generar el sorteo (emparejamiento) de una ronda.
///
/// Orquesta el DerbyEngine con los datos necesarios.
/// No contiene lógica algorítmica — eso vive en engine/.
class GenerarSorteo {
  final DerbyEngine _engine;

  const GenerarSorteo(this._engine);

  /// Genera la ronda [rondaNumero] del derby.
  ///
  /// Recibe entidades de dominio puras.
  /// Retorna una [Ronda] con enfrentamientos generados.
  Ronda ejecutar({
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    required List<Ronda> rondasPrevias,
    required int rondaNumero,
    int? galloBasePromovidoId,
    int? partidoDoblePreferidoId,
  }) {
    List<Gallo> gallosEfectivos = gallos;
    if (galloBasePromovidoId != null) {
      gallosEfectivos = gallos.map((g) {
        if (g.id == galloBasePromovidoId) {
          return g.copyWith(esBase: false);
        }
        return g;
      }).toList();
    }

    return _engine.generarRonda(
      partidos: partidos,
      gallos: gallosEfectivos,
      compadres: compadres,
      rondasPrevias: rondasPrevias,
      rondaNumero: rondaNumero,
      partidoDoblePreferidoId: partidoDoblePreferidoId,
    );
  }

  /// Genera SOLO las primeras rondas P.L. (primer bloque).
  ///
  /// Para un derby de 4 rondas: genera rondas 1 y 2 (PL) solamente.
  /// Las rondas posteriores se generan incrementalmente después de
  /// registrar resultados, para que la eliminación y el comodín funcionen.
  ///
  /// [numRondasIniciales]: cuántas rondas PL generar (default: min(2, PL total)).
  List<Ronda> ejecutarPrimerBloque({
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    int? numRondasIniciales,
    int? partidoDoblePreferidoId,
    int? galloBasePromovidoId,
  }) {
    List<Gallo> gallosEfectivos = gallos;
    if (galloBasePromovidoId != null) {
      gallosEfectivos = gallos.map((g) {
        if (g.id == galloBasePromovidoId) {
          return g.copyWith(esBase: false);
        }
        return g;
      }).toList();
    }

    final totalPL = _engine.config.rondasTotales - 1;
    final nRondas = numRondasIniciales ?? (totalPL >= 2 ? 2 : totalPL);
    if (nRondas <= 0) return [];

    final numPartidosActivos = partidos
        .where(
          (p) =>
              p.estado == EstadoPartido.activo && !p.eliminado && !p.esComodin,
        )
        .length;
    final esImpar = numPartidosActivos % 2 != 0;

    // Para impar, usar flujo secuencial (cada ronda decide su doble pelea
    // con un partido distinto). La optimización global solo maneja par.
    if (!esImpar) {
      try {
        return _engine.generarSorteoPLGlobal(
          partidos: partidos,
          gallos: gallosEfectivos,
          compadres: compadres,
          numRondasOverride: nRondas,
        );
      } catch (e) {
        print('⚠️ Optimización global falló ($e), usando flujo secuencial...');
      }
    }

    // Flujo secuencial (impar, o fallback si global falló)
    final rondasGeneradas = <Ronda>[];
    for (var i = 1; i <= nRondas; i++) {
      final ronda = _engine.generarRonda(
        partidos: partidos,
        gallos: gallosEfectivos,
        compadres: compadres,
        rondasPrevias: rondasGeneradas,
        rondaNumero: i,
        partidoDoblePreferidoId: partidoDoblePreferidoId,
      );
      rondasGeneradas.add(ronda);
    }
    return rondasGeneradas;
  }

  /// Genera TODAS las rondas del derby de una sola vez.
  ///
  /// Usa optimización global minimax para las rondas P.L. (minimiza la
  /// diferencia máxima individual entre gallos). La ronda base (última)
  /// se genera con el método secuencial estándar.
  ///
  /// Si la optimización global falla, cae al flujo secuencial como respaldo.
  List<Ronda> ejecutarTodas({
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    int? partidoDoblePreferidoId,
    int? galloBasePromovidoId,
  }) {
    List<Gallo> gallosEfectivos = gallos;

    // Si se promovió un gallo base, tratarlo como P.L. (esBase = false)
    if (galloBasePromovidoId != null) {
      gallosEfectivos = gallos.map((g) {
        if (g.id == galloBasePromovidoId) {
          return g.copyWith(esBase: false);
        }
        return g;
      }).toList();
      print('🐓 Gallo base promovido a P.L. para cuadrar peleas (ID: $galloBasePromovidoId)');
    }

    final rondasGeneradas = <Ronda>[];

    // ── Intentar optimización global para rondas P.L. ──
    try {
      final rondasPL = _engine.generarSorteoPLGlobal(
        partidos: partidos,
        gallos: gallosEfectivos,
        compadres: compadres,
      );
      rondasGeneradas.addAll(rondasPL);

      // Generar ronda base (última) con método secuencial
      if (_engine.config.rondasTotales > 1) {
        final rondaBase = _engine.generarRonda(
          partidos: partidos,
          gallos: gallosEfectivos,
          compadres: compadres,
          rondasPrevias: rondasGeneradas,
          rondaNumero: _engine.config.rondasTotales,
          partidoDoblePreferidoId: partidoDoblePreferidoId,
        );
        rondasGeneradas.add(rondaBase);
      }

      return rondasGeneradas;
    } catch (e) {
      // Fallback: flujo secuencial original
      print('⚠️ Optimización global falló ($e), usando flujo secuencial...');
    }

    // ── Fallback secuencial (ronda por ronda) ──
    rondasGeneradas.clear();
    for (var i = 1; i <= _engine.config.rondasTotales; i++) {
        final ronda = _engine.generarRonda(
          partidos: partidos,
          gallos: gallosEfectivos,
          compadres: compadres,
          rondasPrevias: rondasGeneradas,
          rondaNumero: i,
          // Usar el partido doble preferido en la primera oportunidad de doble pelea
          partidoDoblePreferidoId: partidoDoblePreferidoId,
        );
      rondasGeneradas.add(ronda);
    }

    return rondasGeneradas;
  }

  /// Genera todas las rondas y construye el resultado visual (Hoja de Estilo).
  ///
  /// [nombreDerby]: nombre del derby para el encabezado.
  /// Retorna un [SorteoResultado] con la vista por partido.
  SorteoResultado ejecutarConResultado({
    required String nombreDerby,
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
  }) {
    final rondas = ejecutarTodas(
      partidos: partidos,
      gallos: gallos,
      compadres: compadres,
    );

    return construirResultadoVisual(
      nombreDerby: nombreDerby,
      partidos: partidos,
      rondas: rondas,
    );
  }

  /// Construye la vista tabular por partido a partir de rondas ya generadas.
  ///
  /// Mapea cada enfrentamiento a la perspectiva de cada partido:
  /// - anilloPropio: el gallo de ESE partido
  /// - anilloRival: el gallo del otro partido
  /// - filaPartidoRival: posición 1-based del rival en la tabla general
  SorteoResultado construirResultadoVisual({
    required String nombreDerby,
    required List<Partido> partidos,
    required List<Ronda> rondas,
    List<Compadres> compadres = const [],
  }) {
    // Mapa de partidoId → fila (1-based, orden de la lista de partidos)
    final filaMap = <int, int>{};
    final nombreMap = <int, String>{};
    for (var i = 0; i < partidos.length; i++) {
      filaMap[partidos[i].id] = i + 1;
      nombreMap[partidos[i].id] = partidos[i].nombre;
    }

    // Para cada partido, recopilar su resultado por ronda
    final resultadosPorPartido = <int, List<RondaResultado>>{};
    for (final p in partidos) {
      resultadosPorPartido[p.id] = [];
    }

    for (final ronda in rondas) {
      // Determinar partido(s) doble en esta ronda
      final dobleIds = ronda.partidosDobles.toSet();

      for (final e in ronda.enfrentamientos) {
        final idA = e.galloA.partidoId;
        final idB = e.galloB.partidoId;

        // Perspectiva del partido A
        resultadosPorPartido[idA]?.add(
          RondaResultado(
            numeroRonda: ronda.numero,
            anilloPropio: e.galloA.anillo,
            anilloRival: e.galloB.anillo,
            filaPartidoRival: filaMap[idB] ?? 0,
            nombrePartidoRival: nombreMap[idB] ?? '?',
            pesoPropio: e.galloA.pesoGramos,
            pesoRival: e.galloB.pesoGramos,
            esDoble: dobleIds.contains(idA),
          ),
        );

        // Perspectiva del partido B
        resultadosPorPartido[idB]?.add(
          RondaResultado(
            numeroRonda: ronda.numero,
            anilloPropio: e.galloB.anillo,
            anilloRival: e.galloA.anillo,
            filaPartidoRival: filaMap[idA] ?? 0,
            nombrePartidoRival: nombreMap[idA] ?? '?',
            pesoPropio: e.galloB.pesoGramos,
            pesoRival: e.galloA.pesoGramos,
            esDoble: dobleIds.contains(idB),
          ),
        );
      }

      // Bye: partidos que descansan esta ronda (legacy / fallback)
      for (final byeId in ronda.partidosBye) {
        resultadosPorPartido[byeId]?.add(
          RondaResultado(numeroRonda: ronda.numero, esBye: true),
        );
      }
    }

    // Construir mapa de compadres: partidoId → lista de filas compadres
    final compadresFilasMap = <int, List<int>>{};
    for (final c in compadres) {
      final filaA = filaMap[c.partidoIdA];
      final filaB = filaMap[c.partidoIdB];
      if (filaA != null && filaB != null) {
        compadresFilasMap.putIfAbsent(c.partidoIdA, () => []).add(filaB);
        compadresFilasMap.putIfAbsent(c.partidoIdB, () => []).add(filaA);
      }
    }

    // Construir lista de PartidoResultado, ordenados por fila
    final partidosResultado = <PartidoResultado>[];
    for (final p in partidos) {
      final rondas = resultadosPorPartido[p.id] ?? [];
      // Ordenar por número de ronda
      rondas.sort((a, b) => a.numeroRonda.compareTo(b.numeroRonda));

      final cFilas = compadresFilasMap[p.id] ?? [];
      cFilas.sort();

      partidosResultado.add(
        PartidoResultado(
          partidoId: p.id,
          nombrePartido: p.nombre,
          fila: filaMap[p.id] ?? 0,
          rondas: rondas,
          compadresFilas: cFilas,
        ),
      );
    }

    // Recopilar advertencias
    final advertencias = <String>[];

    // Advertencias de doble pelea
    final dobleCount = <int, int>{};
    for (final r in rondas) {
      for (final did in r.partidosDobles) {
        dobleCount[did] = (dobleCount[did] ?? 0) + 1;
      }
    }
    if (dobleCount.isNotEmpty) {
      advertencias.add(
        'Número impar de partidos. '
        'Se aplicó doble pelea (1 partido pelea 2 veces con 2 gallos distintos).',
      );
      for (final entry in dobleCount.entries) {
        final nombre = nombreMap[entry.key] ?? '?';
        advertencias.add(
          'Partido "$nombre" pelea doble en ${entry.value} ronda(s).',
        );
      }
    }

    // Advertencias de byes (legacy — NO se generan nuevos BYEs)
    if (partidos.length.isOdd) {
      final byeCount = <int, int>{};
      for (final r in rondas) {
        for (final bid in r.partidosBye) {
          byeCount[bid] = (byeCount[bid] ?? 0) + 1;
        }
      }
      if (byeCount.isNotEmpty) {
        advertencias.add(
          'Sorteo legacy con BYE detectado (sin victoria automática).',
        );
        for (final entry in byeCount.entries) {
          final nombre = nombreMap[entry.key] ?? '?';
          advertencias.add('Partido "$nombre" recibió ${entry.value} bye(s).');
        }
      }
    }

    return SorteoResultado(
      nombreDerby: nombreDerby,
      fecha: DateTime.now(),
      rondasGeneradas: rondas.length,
      partidos: partidosResultado,
      advertencias: advertencias,
    );
  }

  /// Valida que el derby esté listo para iniciar.
  List<String> validar({
    required List<Partido> partidos,
    required List<Gallo> gallos,
  }) {
    return _engine.validarDerby(partidos, gallos);
  }

  static int calcularRondasPL(List<Partido> partidos, List<Gallo> gallos) {
    if (partidos.isEmpty) return 0;
    final activos = partidos
        .where(
          (p) =>
              p.estado == EstadoPartido.activo && !p.eliminado && !p.esComodin,
        )
        .map((p) => p.id)
        .toSet();
    if (activos.isEmpty) return 0;

    final conteos = <int, int>{};
    for (var p in activos) {
      conteos[p] = 0;
    }
    for (var g in gallos) {
      if (!g.esBase && activos.contains(g.partidoId)) {
        conteos[g.partidoId] = (conteos[g.partidoId] ?? 0) + 1;
      }
    }

    if (conteos.values.isEmpty) return 0;
    int maxPL = conteos.values.reduce((a, b) => a > b ? a : b);
    return maxPL;
  }
}
