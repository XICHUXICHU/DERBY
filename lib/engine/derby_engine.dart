import '../domain/domain.dart';
import 'matchmaking/graph_builder.dart';
import 'matchmaking/matching_solver.dart';
import 'matchmaking/constraint_validator.dart';
import 'matchmaking/global_optimizer.dart';
import 'elimination/elimination_service.dart';

/// Configuración del derby.
class DerbyConfig {
  final int rondasTotales;
  final int puntosVictoria;
  final int puntosEmpate;
  final int puntosDerrota;
  final int posicionesPremio; // Cuántos partidos entran en zona de premio

  /// Rango de peso aceptado para gallos P.L. (gramos).
  final double pesoMinimo;
  final double pesoMaximo;

  /// Peso específico del gallo base (gramos). 0 = sin restricción.
  final double pesoGalloBase;

  /// En derbys de peso libre, ¿se pueden repetir contrincantes?
  final bool permitirRepeticiones;

  /// Diferencia máxima de peso permitida en peleas P.L. (gramos). 0 = sin límite.
  final double diferenciaMaxPeso;

  /// Validación estricta: si true, falla si no hay solución completa.
  final bool validacionEstricta;

  const DerbyConfig({
    this.rondasTotales = 4,
    this.puntosVictoria = 1,
    this.puntosEmpate = 0,
    this.puntosDerrota = 0,
    this.posicionesPremio = 3,
    this.pesoMinimo = 1800.0,
    this.pesoMaximo = 2500.0,
    this.pesoGalloBase = 0.0,
    this.permitirRepeticiones = false,
    this.diferenciaMaxPeso = 80.0,
    this.validacionEstricta = true,
  });
}

/// Motor principal del derby.
///
/// Orquesta todos los componentes del engine:
/// - GraphBuilder: construye el grafo de enfrentamientos.
/// - MatchingSolver: resuelve el matching.
/// - ConstraintValidator: valida restricciones.
/// - EliminationService: calcula eliminaciones matemáticas.
///
/// Puro Dart. No depende de Flutter ni Drift.
class DerbyEngine {
  final DerbyConfig config;
  final ConstraintValidator _validator;
  final MatchingSolver _solver;
  final EliminationService _eliminationService;

  DerbyEngine({required this.config, required List<Compadres> compadres})
    : _validator = ConstraintValidator(compadres: compadres),
      _solver = MatchingSolver(),
      _eliminationService = EliminationService();

  /// Valida que todos los partidos están completos antes de iniciar.
  List<String> validarDerby(List<Partido> partidos, List<Gallo> gallos) {
    final errores = <String>[];

    if (partidos.length < 2) {
      errores.add('Se necesitan al menos 2 partidos para un derby.');
    }

    // Número impar no es error: se aplica sistema de "bye" (descanso).

    for (final partido in partidos) {
      errores.addAll(_validator.validarPartido(partido, gallos));
    }

    // Verificar anillos únicos
    final anillos = <String>{};
    for (final g in gallos) {
      if (!anillos.add(g.anillo)) {
        errores.add('Anillo duplicado: ${g.anillo}');
      }
    }

    // Validar pesos contra la configuración del derby
    for (final g in gallos) {
      if (g.esBase) {
        // Gallo base: validar contra pesoGalloBase si está configurado
        if (config.pesoGalloBase > 0 && g.pesoGramos != config.pesoGalloBase) {
          errores.add(
            'Gallo base ${g.anillo} pesa ${g.pesoGramos}g, '
            'debe pesar ${config.pesoGalloBase}g.',
          );
        }
      } else {
        // Gallo P.L.: validar contra rango de peso
        if (g.pesoGramos < config.pesoMinimo) {
          errores.add(
            'Gallo ${g.anillo} pesa ${g.pesoGramos}g, '
            'mínimo aceptado: ${config.pesoMinimo}g.',
          );
        }
        if (g.pesoGramos > config.pesoMaximo) {
          errores.add(
            'Gallo ${g.anillo} pesa ${g.pesoGramos}g, '
            'máximo aceptado: ${config.pesoMaximo}g.',
          );
        }
      }
    }

    return errores;
  }

  /// Genera el emparejamiento para la siguiente ronda.
  ///
  /// [partidos]: todos los partidos.
  /// [gallos]: todos los gallos.
  /// [compadres]: relaciones de compadres.
  /// [rondasPrevias]: rondas ya jugadas.
  /// [rondaNumero]: número de la ronda a generar (1-4).
  ///
  /// Retorna la [Ronda] generada con sus enfrentamientos.
  Ronda generarRonda({
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    required List<Ronda> rondasPrevias,
    required int rondaNumero,
  }) {
    // 1. Determinar gallos ya peleados
    final gallosYaPeleados = <int>{};
    final enfrentamientosPrevios = <(int, int)>{};

    for (final ronda in rondasPrevias) {
      for (final e in ronda.enfrentamientos) {
        gallosYaPeleados.add(e.galloA.id);
        gallosYaPeleados.add(e.galloB.id);

        final pA = e.galloA.partidoId;
        final pB = e.galloB.partidoId;
        final a = pA < pB ? pA : pB;
        final b = pA < pB ? pB : pA;
        enfrentamientosPrevios.add((a, b));
      }
    }

    // 2. Calcular eliminaciones matemáticas
    final rondasRestantes = config.rondasTotales - rondaNumero + 1;
    final eliminados = _eliminationService.partidosEliminados(
      partidos: partidos,
      rondasRestantes: rondasRestantes,
      puntosVictoria: config.puntosVictoria,
      posicionesPremio: config.posicionesPremio,
    );

    // 3. Filtrar partidos activos (no eliminados, no comodines).
    // Los comodines se incorporan solo en CASO B (rondas 3+ con impar).
    final bool esRondaBase = rondaNumero == config.rondasTotales;
    final partidosActivosBase = partidos
        .where(
          (p) =>
              p.estado == EstadoPartido.activo &&
              !p.eliminado &&
              !p.esComodin &&
              !eliminados.contains(p.id),
        )
        .map((p) => p.id)
        .toSet();

    // 3b. Excluir partidos sin gallos disponibles para este tipo de ronda.
    // Esto ocurre cuando un partido usó todos sus gallos P.L. en doble
    // peleas de rondas anteriores.
    final partidosActivos = partidosActivosBase.where((pid) {
      return gallos.any(
        (g) =>
            g.partidoId == pid &&
            !gallosYaPeleados.contains(g.id) &&
            (esRondaBase ? g.esBase : !g.esBase),
      );
    }).toSet();

    print('\n── generarRonda($rondaNumero) ──');
    print(
      '  Partidos activos: ${partidosActivos.length} → IDs: $partidosActivos',
    );
    if (partidosActivosBase.length != partidosActivos.length) {
      final excluidos = partidosActivosBase.difference(partidosActivos);
      print('  Excluidos por falta de gallos: $excluidos');
    }
    print('  Eliminados por engine: $eliminados');
    print('  Gallos ya peleados: ${gallosYaPeleados.length} IDs');
    print('  Enfrentamientos previos partido↔partido: $enfrentamientosPrevios');

    if (partidosActivos.length < 2) {
      print('  ⛔ Menos de 2 partidos activos!');
      throw MatchingImposibleException(
        rondaNumero: rondaNumero,
        gallosDisponibles: 0,
        restriccionesActivas: 0,
        detalle: 'Menos de 2 partidos activos.',
      );
    }

    // 3c. Manejo de número impar de partidos activos.
    //
    // Regla del juez (NO BYE):
    // - Rondas 1-2 (P.L.): un partido pelea DOBLE (2 gallos distintos
    //   contra 2 rivales). Ambas peleas cuentan normal.
    // - Rondas 3+ (P.L.) con impar post-eliminación: se requiere un
    //   partido COMODÍN registrado por el usuario.
    // - Ronda base: si hay impar, el sobrante no pelea (sin victorias gratis).
    final bool esImpar = partidosActivos.length % 2 != 0;
    final bool esRondaDoblePelea = rondaNumero <= 2; // Rondas 1 y 2

    print(
      '  esImpar=$esImpar, esRondaBase=$esRondaBase, esRondaDoblePelea=$esRondaDoblePelea',
    );

    if (esImpar && !esRondaBase) {
      // ── CASO A: Doble pelea (rondas 1-2) ──────────────────────
      if (esRondaDoblePelea) {
        print('  → CASO A: Intentando doble pelea (ronda $rondaNumero)');
        return _intentarDoblePelea(
          gallos: gallos,
          compadres: compadres,
          partidosActivos: partidosActivos,
          gallosYaPeleados: gallosYaPeleados,
          enfrentamientosPrevios: enfrentamientosPrevios,
          rondaNumero: rondaNumero,
          rondasPrevias: rondasPrevias,
        );
      }

      // ── CASO B: Comodín (rondas 3+, impar post-eliminación) ───
      // Regla del juez: se requiere un partido COMODÍN. NO BYE.
      print('  → CASO B: Buscando comodín (ronda $rondaNumero)');
      final comodinActivo = partidos.firstWhere(
        (p) => p.esComodin && p.estado == EstadoPartido.activo && !p.eliminado,
        orElse: () => const Partido(id: -1, nombre: ''),
      );
      print(
        '  Comodín encontrado: ${comodinActivo.id != -1 ? comodinActivo.nombre : "NINGUNO"}',
      );

      if (comodinActivo.id != -1 &&
          !partidosActivos.contains(comodinActivo.id)) {
        // Agregar comodín al set de activos para emparejar
        final activosConComodin = Set<int>.of(partidosActivos)
          ..add(comodinActivo.id);

        return _intentarMatching(
          gallos: gallos,
          compadres: compadres,
          partidosActivos: activosConComodin,
          gallosYaPeleados: gallosYaPeleados,
          enfrentamientosPrevios: enfrentamientosPrevios,
          rondaNumero: rondaNumero,
          esRondaBase: false,
          partidosBye: const [],
          partidosDobles: const [],
        );
      }

      // ── CASO C: Sin comodín → intentar doble pelea (si hay candidatos) ─
      print('  → CASO C: Sin comodín, intentando doble pelea en ronda $rondaNumero');
      try {
        return _intentarDoblePelea(
          gallos: gallos,
          compadres: compadres,
          partidosActivos: partidosActivos,
          gallosYaPeleados: gallosYaPeleados,
          enfrentamientosPrevios: enfrentamientosPrevios,
          rondaNumero: rondaNumero,
          rondasPrevias: rondasPrevias,
        );
      } on DerbyException catch (e) {
        print('  Doble pelea en R$rondaNumero falló: $e');
      }

      // ── CASO D: Un partido no participa (sin victoria automática) ──
      // Similar a ronda base: matching con los partidos par, el sobrante
      // simplemente no pelea (NO recibe puntos gratis — no es BYE).
      print('  → CASO D: Un partido no participa (sin victoria, sin BYE)');
      return _intentarMatching(
        gallos: gallos,
        compadres: compadres,
        partidosActivos: partidosActivos,
        gallosYaPeleados: gallosYaPeleados,
        enfrentamientosPrevios: enfrentamientosPrevios,
        rondaNumero: rondaNumero,
        esRondaBase: false,
        partidosBye: const [],
        partidosDobles: const [],
        permitirSobrante: true,
      );
    }

    // Número par: matching directo sin bye ni dobles.
    return _intentarMatching(
      gallos: gallos,
      compadres: compadres,
      partidosActivos: partidosActivos,
      gallosYaPeleados: gallosYaPeleados,
      enfrentamientosPrevios: enfrentamientosPrevios,
      rondaNumero: rondaNumero,
      esRondaBase: esRondaBase,
      partidosBye: const [],
      partidosDobles: const [],
    );
  }

  /// Intenta generar matching con un partido que pelea doble.
  ///
  /// El partido doble usa 2 gallos P.L. distintos en 2 enfrentamientos
  /// contra 2 rivales diferentes. Ambas peleas cuentan normal.
  Ronda _intentarDoblePelea({
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    required Set<int> partidosActivos,
    required Set<int> gallosYaPeleados,
    required Set<(int, int)> enfrentamientosPrevios,
    required int rondaNumero,
    required List<Ronda> rondasPrevias,
  }) {
    print('\n  ── _intentarDoblePelea (ronda $rondaNumero) ──');
    // Contar dobles previas para cada partido
    final doblesPrevios = <int, int>{};
    for (final r in rondasPrevias) {
      for (final did in r.partidosDobles) {
        doblesPrevios[did] = (doblesPrevios[did] ?? 0) + 1;
      }
    }
    print('  Dobles previas: $doblesPrevios');

    // Contar gallos P.L. disponibles por partido
    final gallosPLPorPartido = <int, int>{};
    for (final g in gallos) {
      if (g.esBase) continue;
      if (!partidosActivos.contains(g.partidoId)) continue;
      if (gallosYaPeleados.contains(g.id)) continue;
      gallosPLPorPartido[g.partidoId] =
          (gallosPLPorPartido[g.partidoId] ?? 0) + 1;
    }
    print('  Gallos P.L. disponibles por partido: $gallosPLPorPartido');

    // Candidatos: partidos con al menos 2 gallos P.L. disponibles.
    // Ordenar: menos dobles previas primero, desempate por ID más alto.
    final candidatos =
        partidosActivos
            .where((pid) => (gallosPLPorPartido[pid] ?? 0) >= 2)
            .toList()
          ..sort((a, b) {
            final cmp = (doblesPrevios[a] ?? 0).compareTo(
              doblesPrevios[b] ?? 0,
            );
            return cmp != 0 ? cmp : b.compareTo(a);
          });
    print('  Candidatos doble (>=2 PL disponibles): $candidatos');
    if (candidatos.isEmpty) {
      print('  ⚠️ NINGÚN candidato doble! Todos tienen <2 PL disponibles');
    }

    Exception? ultimoError;
    for (final dobleId in candidatos) {
      // Sin BYE: cada ronda futura excluye partidos sin gallos
      // automáticamente, así que no necesitamos chequeo de
      // sustentabilidad global. Cada ronda maneja su propia paridad.
      print('  Intentando doble pelea con partido $dobleId...');
      try {
        final ronda = _intentarMatchingConDoble(
          gallos: gallos,
          compadres: compadres,
          partidosActivos: partidosActivos,
          gallosYaPeleados: gallosYaPeleados,
          enfrentamientosPrevios: enfrentamientosPrevios,
          rondaNumero: rondaNumero,
          partidoDobleId: dobleId,
        );
        print('  ✅ Doble pelea exitosa con partido $dobleId');
        return ronda;
      } on DerbyException catch (e) {
        print(
          '  ❌ Doble con $dobleId falló: ${e is MatchingImposibleException ? e.detalle : e}',
        );
        ultimoError = e;
        continue;
      }
    }

    // Ningún candidato doble funcionó (regla del juez: NO BYE fallback)
    print('  ⛔ Ningún candidato doble funcionó');
    throw ultimoError ??
        MatchingImposibleException(
          rondaNumero: rondaNumero,
          gallosDisponibles: 0,
          restriccionesActivas: 0,
          detalle:
              'No se encontró partido para doble pelea en ronda $rondaNumero.',
        );
  }

  /// Genera matching donde [partidoDobleId] pelea dos veces con 2 gallos P.L. distintos.
  Ronda _intentarMatchingConDoble({
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    required Set<int> partidosActivos,
    required Set<int> gallosYaPeleados,
    required Set<(int, int)> enfrentamientosPrevios,
    required int rondaNumero,
    required int partidoDobleId,
  }) {
    // Todos los partidos participan (incluido el doble).
    // El partido doble necesita 2 gallos y 2 rivales.

    // Obtener gallos P.L. disponibles del partido doble
    final gallosDoble =
        gallos
            .where(
              (g) =>
                  g.partidoId == partidoDobleId &&
                  !g.esBase &&
                  !gallosYaPeleados.contains(g.id),
            )
            .toList()
          ..sort((a, b) => a.pesoGramos.compareTo(b.pesoGramos));

    print('    ── _intentarMatchingConDoble (doble=$partidoDobleId) ──');
    print(
      '    Gallos doble: ${gallosDoble.map((g) => "${g.anillo}(${g.pesoGramos}g)").toList()}',
    );

    if (gallosDoble.length < 2) {
      throw MatchingImposibleException(
        rondaNumero: rondaNumero,
        gallosDisponibles: gallosDoble.length,
        restriccionesActivas: 0,
        detalle:
            'Partido $partidoDobleId no tiene 2 gallos P.L. disponibles para doble pelea.',
      );
    }

    // Seleccionar gallos disponibles de los otros partidos
    final gallosOtros = gallos.where((g) {
      if (g.partidoId == partidoDobleId) return false;
      if (!partidosActivos.contains(g.partidoId)) return false;
      if (gallosYaPeleados.contains(g.id)) return false;
      return !g.esBase;
    }).toList();

    // Construir grafo para matching normal (sin el partido doble)
    final graphBuilder = GraphBuilder(
      compadres: compadres,
      gallosUsados: gallosYaPeleados,
      enfrentamientosPrevios: enfrentamientosPrevios,
      diferenciaMaxPeso: config.diferenciaMaxPeso,
      esRondaBase: false,
    );

    // Necesitamos emparejar los otros partidos entre sí, dejando 2 sin emparejar
    // que serán los rivales del partido doble.
    // Pero esto es complejo... Mejor enfoque: construir matching completo
    // donde el partido doble aparece como 2 "slots".

    // Estrategia: crear 2 partidos virtuales para el doble, resolver,
    // luego reasignar.

    // Alternativa más simple y confiable:
    // 1. Generar TODAS las aristas válidas incluyendo las del doble
    // 2. Resolver matching donde el doble puede aparecer en 2 pares

    final todosGallos = [...gallosOtros, ...gallosDoble];
    final todasAristas = graphBuilder.construirGrafo(todosGallos);

    print('    Gallos otros partidos: ${gallosOtros.length}');
    for (final pid in partidosActivos.where((p) => p != partidoDobleId)) {
      final gs = gallosOtros.where((g) => g.partidoId == pid);
      print(
        '      P$pid: ${gs.map((g) => "${g.anillo}(${g.pesoGramos}g)").toList()}',
      );
    }
    print('    Total gallos para grafo: ${todosGallos.length}');
    print('    Aristas válidas: ${todasAristas.length}');
    if (todasAristas.length <= 30) {
      for (final a in todasAristas) {
        print(
          '      ${a.galloA.anillo}(P${a.galloA.partidoId},${a.galloA.pesoGramos}g) vs '
          '${a.galloB.anillo}(P${a.galloB.partidoId},${a.galloB.pesoGramos}g) diff=${a.peso}g',
        );
      }
    } else {
      print('      (demasiadas para mostrar, primeras 10:)');
      for (final a in todasAristas.take(10)) {
        print(
          '      ${a.galloA.anillo}(P${a.galloA.partidoId},${a.galloA.pesoGramos}g) vs '
          '${a.galloB.anillo}(P${a.galloB.partidoId},${a.galloB.pesoGramos}g) diff=${a.peso}g',
        );
      }
    }

    // Resolver con matching especial que permite al partido doble 2 apariciones
    print('    Resolviendo _solverDoble...');
    final resultado = _solverDoble(
      aristas: todasAristas,
      partidosActivos: partidosActivos,
      partidoDobleId: partidoDobleId,
      rondaNumero: rondaNumero,
    );

    // Construir enfrentamientos
    final enfrentamientos = <Enfrentamiento>[];
    for (var i = 0; i < resultado.pares.length; i++) {
      final par = resultado.pares[i];
      enfrentamientos.add(
        Enfrentamiento(
          id: i + 1,
          rondaNumero: rondaNumero,
          galloA: par.galloA,
          galloB: par.galloB,
          diferenciaPeso: par.diferencia,
        ),
      );
    }

    // Validar
    final errores = _validator.validarCompleto(
      enfrentamientos: enfrentamientos,
      rondaNumero: rondaNumero,
      esRondaBase: false,
      gallosYaPeleados: gallosYaPeleados,
    );

    if (errores.isNotEmpty && config.validacionEstricta) {
      print('    ❌ Validación doble falló: ${errores.join("; ")}');
      throw MatchingImposibleException(
        rondaNumero: rondaNumero,
        gallosDisponibles: todosGallos.length,
        restriccionesActivas: errores.length,
        detalle: 'Validación con doble pelea falló: ${errores.join("; ")}',
      );
    }

    return Ronda(
      numero: rondaNumero,
      enfrentamientos: enfrentamientos,
      esRondaBase: false,
      fechaCreacion: DateTime.now(),
      partidosBye: const [],
      partidosDobles: [partidoDobleId],
    );
  }

  /// Solver especial que permite a un partido aparecer en 2 pares.
  ///
  /// Usa backtracking: cada partido normal aparece máx 1 vez,
  /// [partidoDobleId] aparece exactamente 2 veces con 2 gallos distintos.
  ResultadoMatching _solverDoble({
    required List<AristaGrafo> aristas,
    required Set<int> partidosActivos,
    required int partidoDobleId,
    required int rondaNumero,
  }) {
    final totalPares = (partidosActivos.length + 1) ~/ 2;
    print(
      '    _solverDoble: totalPares=$totalPares, aristas=${aristas.length}, dobleId=$partidoDobleId',
    );
    // El doble consume 2 slots, los demás 1 cada uno.
    // Total slots = partidosActivos.length + 1 (el doble cuenta doble)
    // Total pares = (partidosActivos.length + 1) / 2

    List<ParEmparejado>? mejorSolucion;
    var mejorCosto = double.infinity;
    var iteraciones = 0;
    const maxIter = 500000;

    void buscar(
      int indiceArista,
      List<ParEmparejado> pares,
      Map<int, int> vecesUsado, // partidoId → veces emparejado
      Set<int> gallosUsados,
      double costo,
    ) {
      iteraciones++;
      if (iteraciones > maxIter) return;

      if (pares.length == totalPares) {
        // Verificar que el doble aparece exactamente 2 veces
        if ((vecesUsado[partidoDobleId] ?? 0) == 2 && costo < mejorCosto) {
          mejorCosto = costo;
          mejorSolucion = List.of(pares);
        }
        return;
      }

      if (costo >= mejorCosto) return;
      final restantes = aristas.length - indiceArista;
      if (restantes < totalPares - pares.length) return;

      for (var i = indiceArista; i < aristas.length; i++) {
        final ar = aristas[i];
        final pA = ar.galloA.partidoId;
        final pB = ar.galloB.partidoId;
        final usosA = vecesUsado[pA] ?? 0;
        final usosB = vecesUsado[pB] ?? 0;

        // Límite: doble puede 2, los demás máx 1
        final limA = pA == partidoDobleId ? 2 : 1;
        final limB = pB == partidoDobleId ? 2 : 1;
        if (usosA >= limA || usosB >= limB) continue;

        // No reutilizar gallos
        if (gallosUsados.contains(ar.galloA.id) ||
            gallosUsados.contains(ar.galloB.id))
          continue;

        if (!partidosActivos.contains(pA) && pA != partidoDobleId) continue;
        if (!partidosActivos.contains(pB) && pB != partidoDobleId) continue;

        if (costo + ar.peso >= mejorCosto) continue;

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

        buscar(i + 1, pares, vecesUsado, gallosUsados, costo + ar.peso);

        pares.removeLast();
        vecesUsado[pA] = usosA;
        vecesUsado[pB] = usosB;
        gallosUsados.remove(ar.galloA.id);
        gallosUsados.remove(ar.galloB.id);
      }
    }

    buscar(0, [], {}, {}, 0.0);

    print(
      '    _solverDoble: iteraciones=$iteraciones, solución=${mejorSolucion != null ? "SÍ (costo=$mejorCosto)" : "NO"}',
    );
    if (mejorSolucion != null) {
      for (final p in mejorSolucion!) {
        print(
          '      ${p.galloA.anillo}(P${p.galloA.partidoId}) vs ${p.galloB.anillo}(P${p.galloB.partidoId}) diff=${p.diferencia}g',
        );
      }
      return ResultadoMatching(pares: mejorSolucion!, sumaTotal: mejorCosto);
    }

    print('    ❌ _solverDoble: No se encontró matching válido');
    throw MatchingImposibleException(
      rondaNumero: rondaNumero,
      gallosDisponibles: aristas.length,
      restriccionesActivas: 0,
      detalle:
          'No se encontró matching válido con doble pelea para partido $partidoDobleId.',
    );
  }

  /// Intenta generar matching para un conjunto de partidos activos.
  ///
  /// Encapsula pasos 4-9 del algoritmo. Lanza si no hay solución.
  Ronda _intentarMatching({
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    required Set<int> partidosActivos,
    required Set<int> gallosYaPeleados,
    required Set<(int, int)> enfrentamientosPrevios,
    required int rondaNumero,
    required bool esRondaBase,
    required List<int> partidosBye,
    required List<int> partidosDobles,
    bool permitirSobrante = false,
  }) {
    // 4. Seleccionar gallos disponibles según ronda
    final gallosDisponibles = gallos.where((g) {
      if (!partidosActivos.contains(g.partidoId)) return false;
      if (gallosYaPeleados.contains(g.id)) return false;
      if (esRondaBase) return g.esBase; // Ronda final: solo gallos base
      return !g.esBase; // Rondas 1-3: solo gallos libres
    }).toList();

    print(
      '    _intentarMatching(ronda=$rondaNumero, esBase=$esRondaBase, bye=$partidosBye)',
    );
    print(
      '    Gallos disponibles: ${gallosDisponibles.length}, partidos activos: ${partidosActivos.length}',
    );

    // 5. Construir grafo
    final graphBuilder = GraphBuilder(
      compadres: compadres,
      gallosUsados: gallosYaPeleados,
      enfrentamientosPrevios: enfrentamientosPrevios,
      diferenciaMaxPeso: config.diferenciaMaxPeso,
      esRondaBase: esRondaBase,
    );

    // 6. Resolver matching
    print('    Resolviendo matching normal...');
    final resultado = _solver.resolver(
      gallosDisponibles: gallosDisponibles,
      partidosActivos: partidosActivos,
      graphBuilder: graphBuilder,
      rondaNumero: rondaNumero,
      permitirRepeticiones: config.permitirRepeticiones,
    );

    print(
      '    Matching result: ${resultado.pares.length} pares, sinEmparejar=${resultado.partidosSinEmparejar}',
    );
    for (final p in resultado.pares) {
      print(
        '      ${p.galloA.anillo}(P${p.galloA.partidoId}) vs ${p.galloB.anillo}(P${p.galloB.partidoId}) diff=${p.diferencia}g',
      );
    }

    // 7. Construir enfrentamientos
    final enfrentamientos = <Enfrentamiento>[];
    for (var i = 0; i < resultado.pares.length; i++) {
      final par = resultado.pares[i];
      enfrentamientos.add(
        Enfrentamiento(
          id: i + 1,
          rondaNumero: rondaNumero,
          galloA: par.galloA,
          galloB: par.galloB,
          diferenciaPeso: par.diferencia,
        ),
      );
    }

    // 8. Validar resultado final
    final errores = _validator.validarCompleto(
      enfrentamientos: enfrentamientos,
      rondaNumero: rondaNumero,
      esRondaBase: esRondaBase,
      gallosYaPeleados: gallosYaPeleados,
    );

    if (errores.isNotEmpty) {
      print('    ❌ Validación matching falló: ${errores.join("; ")}');
      throw MatchingImposibleException(
        rondaNumero: rondaNumero,
        gallosDisponibles: gallosDisponibles.length,
        restriccionesActivas: errores.length,
        detalle: 'Validación falló: ${errores.join("; ")}',
      );
    }

    // 9. Verificar que no haya partidos sin emparejar
    //    Ronda base con impar: tolerar 1 sobrante (no hay bye, simplemente
    //    no pelea). En rondas P.L. sin comodín/doble: también tolerar
    //    si permitirSobrante=true (el partido no recibe puntos gratis).
    if (resultado.partidosSinEmparejar.isNotEmpty) {
      final tolerarSobrante =
          (esRondaBase || permitirSobrante) &&
          partidosActivos.length.isOdd &&
          resultado.partidosSinEmparejar.length == 1;
      if (!tolerarSobrante) {
        throw RondaIncompletaException(
          partidosSinEmparejar: resultado.partidosSinEmparejar.length,
          idsNoEmparejados: resultado.partidosSinEmparejar,
        );
      }
    }

    return Ronda(
      numero: rondaNumero,
      enfrentamientos: enfrentamientos,
      esRondaBase: esRondaBase,
      fechaCreacion: DateTime.now(),
      partidosBye: partidosBye,
      partidosDobles: partidosDobles,
    );
  }

  /// Genera TODAS las rondas P.L. de una sola vez usando optimización global
  /// multi-ronda con criterio minimax (minimizar la diferencia máxima individual).
  ///
  /// La ronda base (última) NO se incluye — se genera aparte con [generarRonda].
  ///
  /// Retorna lista de [Ronda] numeradas 1..numRondasPL.
  /// Lanza si no encuentra solución viable.
  List<Ronda> generarSorteoPLGlobal({
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    int? numRondasOverride,
  }) {
    final numRondasPL = numRondasOverride ?? (config.rondasTotales - 1); // last round = base
    if (numRondasPL <= 0) return [];

    // Filter active partidos
    final partidosActivos = partidos
        .where((p) => p.estado == EstadoPartido.activo && !p.eliminado)
        .map((p) => p.id)
        .toSet();

    if (partidosActivos.length < 2) {
      throw MatchingImposibleException(
        rondaNumero: 1,
        gallosDisponibles: 0,
        restriccionesActivas: 0,
        detalle: 'Menos de 2 partidos activos para optimización global.',
      );
    }

    // Collect PL gallos
    final gallosPL = gallos
        .where((g) => !g.esBase && (partidosActivos.contains(g.partidoId)))
        .toList();

    final esImpar = partidosActivos.length % 2 != 0;

    // ── Decidir estrategia de impar upfront ──
    // Regla del juez: NO BYE. Para impar, usar flujo secuencial
    // con doble pelea por ronda. La optimización global solo maneja par.
    if (esImpar) {
      throw MatchingImposibleException(
        rondaNumero: 1,
        gallosDisponibles: gallosPL.length,
        restriccionesActivas: 0,
        detalle:
            'Optimización global no soporta número impar de partidos. '
            'Use flujo secuencial con doble pelea.',
      );
    }

    // Par: no necesita doble ni BYE
    const int? partidoDobleId = null;
    const int rondaDobleIndex = -1;
    final partidosBye = <int, int>{};
    final allPLGallos = gallosPL.toList();

    print('\n══ generarSorteoPLGlobal ══');
    print('  Partidos activos: ${partidosActivos.length}');
    print('  Gallos PL: ${allPLGallos.length}');
    print('  Rondas PL: $numRondasPL');
    print('  Impar: $esImpar');
    print('  Doble: pid=$partidoDobleId, rondaIdx=$rondaDobleIndex');
    print('  BYEs: $partidosBye');

    // ── Run global optimizer ──
    final optimizer = GlobalMatchingOptimizer(
      compadres: compadres,
      diferenciaMaxPeso: config.diferenciaMaxPeso,
      permitirRepeticiones: config.permitirRepeticiones,
    );

    final resultado = optimizer.optimizar(
      gallosPL: allPLGallos,
      partidosActivos: partidosActivos,
      numRondasPL: numRondasPL,
      partidoDobleId: partidoDobleId,
      rondaDobleIndex: rondaDobleIndex,
      partidosBye: partidosBye,
    );

    print(
      '  Global result: maxDiff=${resultado.maxDiferencia.toStringAsFixed(1)}g, '
      'sumaTotal=${resultado.sumaTotal.toStringAsFixed(1)}g',
    );

    // ── Convert to Ronda objects ──
    final rondas = <Ronda>[];
    for (var r = 0; r < numRondasPL; r++) {
      final pares = resultado.matchings[r] ?? [];
      final enfrentamientos = <Enfrentamiento>[];
      for (var i = 0; i < pares.length; i++) {
        final par = pares[i];
        enfrentamientos.add(
          Enfrentamiento(
            id: i + 1,
            rondaNumero: r + 1, // 1-based
            galloA: par.galloA,
            galloB: par.galloB,
            diferenciaPeso: par.diferencia,
          ),
        );
      }

      final isDoble = r == rondaDobleIndex && partidoDobleId != null;
      final byeId = partidosBye[r];

      rondas.add(
        Ronda(
          numero: r + 1,
          enfrentamientos: enfrentamientos,
          esRondaBase: false,
          fechaCreacion: DateTime.now(),
          partidosBye: byeId != null ? [byeId] : const [],
          partidosDobles: isDoble ? [partidoDobleId] : const [],
        ),
      );

      print(
        '  Ronda ${r + 1}: ${enfrentamientos.length} peleas'
        '${isDoble ? " (doble P$partidoDobleId)" : ""}'
        '${byeId != null ? " (BYE P$byeId)" : ""}',
      );
      for (final e in enfrentamientos) {
        print(
          '    ${e.galloA.anillo}(P${e.galloA.partidoId},${e.galloA.pesoGramos}g) vs '
          '${e.galloB.anillo}(P${e.galloB.partidoId},${e.galloB.pesoGramos}g) '
          'diff=${e.diferenciaPeso.toStringAsFixed(0)}g',
        );
      }
    }

    return rondas;
  }

  /// Calcula eliminaciones después de una ronda.
  List<AnalisisEliminacion> calcularEliminaciones({
    required List<Partido> partidos,
    required int rondasRestantes,
  }) {
    return _eliminationService.analizar(
      partidos: partidos,
      rondasRestantes: rondasRestantes,
      puntosVictoria: config.puntosVictoria,
      posicionesPremio: config.posicionesPremio,
    );
  }

  /// Actualiza puntos de partidos basado en resultado de una ronda.
  ///
  /// - Doble pelea: el partido doble recibe puntos por AMBAS peleas normalmente.
  /// - Comodín: pelea normal, pero el comodín no debería entrar en ranking de premios.
  /// - BYE: NO otorga victoria automática (según reglas del juez).
  List<Partido> actualizarPuntos(List<Partido> partidos, Ronda ronda) {
    final puntosExtra = <int, int>{};

    // NOTA: BYE ya NO otorga victoria automática. El partido simplemente
    // no pelea en esa ronda (sin puntos gratis).

    for (final e in ronda.enfrentamientos) {
      if (e.resultado == null) continue;

      switch (e.resultado!) {
        case ResultadoPelea.ganoA:
          puntosExtra[e.galloA.partidoId] =
              (puntosExtra[e.galloA.partidoId] ?? 0) + config.puntosVictoria;
          puntosExtra[e.galloB.partidoId] =
              (puntosExtra[e.galloB.partidoId] ?? 0) + config.puntosDerrota;
          break;
        case ResultadoPelea.ganoB:
          puntosExtra[e.galloB.partidoId] =
              (puntosExtra[e.galloB.partidoId] ?? 0) + config.puntosVictoria;
          puntosExtra[e.galloA.partidoId] =
              (puntosExtra[e.galloA.partidoId] ?? 0) + config.puntosDerrota;
          break;
        case ResultadoPelea.empate:
          puntosExtra[e.galloA.partidoId] =
              (puntosExtra[e.galloA.partidoId] ?? 0) + config.puntosEmpate;
          puntosExtra[e.galloB.partidoId] =
              (puntosExtra[e.galloB.partidoId] ?? 0) + config.puntosEmpate;
          break;
        case ResultadoPelea.noPeleada:
          break;
      }
    }

    return partidos.map((p) {
      final extra = puntosExtra[p.id] ?? 0;
      if (extra == 0) return p;
      return p.copyWith(puntos: p.puntos + extra);
    }).toList();
  }
}
