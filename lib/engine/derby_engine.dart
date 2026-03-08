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
  /// [skipEliminacion]: si true, no se eliminan partidos matemáticamente.
  ///   Usar true cuando se genera el sorteo completo (sin resultados aún).
  /// [gallosPermitidos]: si se proporciona, solo estos gallos pueden usarse
  ///   en esta ronda. Permite pre-distribución TUUMS-style por peso.
  ///
  /// Retorna la [Ronda] generada con sus enfrentamientos.
  Ronda generarRonda({
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    required List<Ronda> rondasPrevias,
    required int rondaNumero,
    bool skipEliminacion = false,
    Set<int>? gallosPermitidos,
    int? partidoDoblePreferidoId,
  }) {
    // 1. Determinar gallos ya peleados + conteo de enfrentamientos
    final gallosYaPeleados = <int>{};
    final conteoEnfrentamientos = <(int, int), int>{};

    for (final ronda in rondasPrevias) {
      for (final e in ronda.enfrentamientos) {
        gallosYaPeleados.add(e.galloA.id);
        gallosYaPeleados.add(e.galloB.id);

        final pA = e.galloA.partidoId;
        final pB = e.galloB.partidoId;
        final a = pA < pB ? pA : pB;
        final b = pA < pB ? pB : pA;
        conteoEnfrentamientos[(a, b)] =
            (conteoEnfrentamientos[(a, b)] ?? 0) + 1;
      }
    }

    // 1b. Pre-distribución: si se especifican gallos permitidos,
    //     tratar los demás como ya peleados para excluirlos de esta ronda.
    if (gallosPermitidos != null) {
      for (final g in gallos) {
        if (!g.esBase && !gallosPermitidos.contains(g.id)) {
          gallosYaPeleados.add(g.id);
        }
      }
    }

    // 2. Calcular eliminaciones matemáticas
    //    Se omite durante generación de sorteo completo (sin resultados
    //    registrados), ya que los puntos del DB no reflejan el estado futuro
    //    y eliminar partidos impediría que sus gallos peleen.
    final Set<int> eliminados;
    if (skipEliminacion) {
      eliminados = {};
    } else {
      final rondasRestantes = config.rondasTotales - rondaNumero + 1;
      eliminados = _eliminationService.partidosEliminados(
        partidos: partidos,
        rondasRestantes: rondasRestantes,
        puntosVictoria: config.puntosVictoria,
        posicionesPremio: config.posicionesPremio,
      );
    }

    // 3. Filtrar partidos activos (no eliminados, no comodines).
    // Los comodines se incorporan solo en CASO B (rondas 3+ con impar).
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

    // 3b. Excluir partidos sin gallos PL disponibles para esta ronda.
    // Esto ocurre cuando un partido usó todos sus gallos P.L. en doble
    // peleas de rondas anteriores.
    final partidosActivos = partidosActivosBase.where((pid) {
      return gallos.any(
        (g) =>
            g.partidoId == pid && !gallosYaPeleados.contains(g.id) && !g.esBase,
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
    if (skipEliminacion) {
      print('  Eliminación: OMITIDA (sorteo completo)');
    } else {
      print('  Eliminados por engine: $eliminados');
    }
    print('  Gallos ya peleados: ${gallosYaPeleados.length} IDs');
    print('  Enfrentamientos previos partido↔partido: $conteoEnfrentamientos');

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
    // - Si es impar y hay un partido con >=2 gallos PL disponibles,
    //   ese partido pelea DOBLE (2 gallos distintos contra 2 rivales).
    //   Se usa un partido diferente cada ronda (se rota).
    // - Si no existe candidato con >=2 gallos: se requiere comodín
    //   o un partido queda como sobrante.
    final bool esImpar = partidosActivos.length % 2 != 0;

    // Verificar si existe algún candidato para doble pelea
    // (partido con >=2 gallos PL no usados, que no haya doblado antes).
    final doblesPrevios = <int, int>{};
    for (final r in rondasPrevias) {
      for (final did in r.partidosDobles) {
        doblesPrevios[did] = (doblesPrevios[did] ?? 0) + 1;
      }
    }
    final bool hayCanditatoDoble =
        esImpar &&
        partidosActivos.any((pid) {
          final gallosPL = gallos
              .where(
                (g) =>
                    g.partidoId == pid &&
                    !g.esBase &&
                    !gallosYaPeleados.contains(g.id),
              )
              .length;
          return gallosPL >= 2;
        });
    final bool esRondaDoblePelea = esImpar && hayCanditatoDoble;

    print('  esImpar=$esImpar, esRondaDoblePelea=$esRondaDoblePelea');

    if (esImpar) {
      // ── CASO A: Doble pelea (rondas 1-2) ──────────────────────
      if (esRondaDoblePelea) {
        // Regla del juez (derby impar): usa el partido indicado por el juez,
        // o como fallback el último registrado (mayor ID).
        final preferido =
            partidoDoblePreferidoId ??
            partidosActivos.reduce((a, b) => a > b ? a : b);
        print(
          '  → CASO A: Intentando doble pelea (ronda $rondaNumero), preferencia=P$preferido',
        );
        return _intentarDoblePelea(
          gallos: gallos,
          compadres: compadres,
          partidosActivos: partidosActivos,
          gallosYaPeleados: gallosYaPeleados,
          conteoEnfrentamientos: conteoEnfrentamientos,
          rondaNumero: rondaNumero,
          rondasPrevias: rondasPrevias,
          partidoDoblePreferido: preferido,
        );
      }

      // ── CASO B: Comodín (impar sin candidato doble) ──────────
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
          conteoEnfrentamientos: conteoEnfrentamientos,
          rondaNumero: rondaNumero,
          partidosBye: const [],
          partidosDobles: const [],
        );
      }

      // ── CASO C: Sin comodín, sin candidato doble ────────────────────
      // Un partido no participa (sobrante).
      print('  → CASO C: Un partido no participa (sin victoria, sin BYE)');
      return _intentarMatching(
        gallos: gallos,
        compadres: compadres,
        partidosActivos: partidosActivos,
        gallosYaPeleados: gallosYaPeleados,
        conteoEnfrentamientos: conteoEnfrentamientos,
        rondaNumero: rondaNumero,
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
      conteoEnfrentamientos: conteoEnfrentamientos,
      rondaNumero: rondaNumero,
      partidosBye: const [],
      partidosDobles: const [],
    );
  }

  /// Intenta generar matching con un partido que pelea doble.
  ///
  /// El partido doble usa 2 gallos P.L. distintos en 2 enfrentamientos
  /// contra 2 rivales diferentes. Ambas peleas cuentan normal.
  ///
  /// [partidoDoblePreferido]: Regla del juez para derby impar — el último
  /// partido registrado (mayor ID) tiene prioridad para ser el doble.
  /// Si no puede (pocos gallos PL), se prueba con los demás candidatos.
  Ronda _intentarDoblePelea({
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    required Set<int> partidosActivos,
    required Set<int> gallosYaPeleados,
    required Map<(int, int), int> conteoEnfrentamientos,
    required int rondaNumero,
    required List<Ronda> rondasPrevias,
    int? partidoDoblePreferido,
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

    // Regla del juez (derby impar): el último partido registrado tiene
    // prioridad para doble pelea. Si es candidato válido, va primero.
    if (partidoDoblePreferido != null &&
        candidatos.contains(partidoDoblePreferido)) {
      candidatos.remove(partidoDoblePreferido);
      candidatos.insert(0, partidoDoblePreferido);
      print(
        '  Preferencia: partido $partidoDoblePreferido (último registrado) al frente',
      );
    }

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
          conteoEnfrentamientos: conteoEnfrentamientos,
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
    required Map<(int, int), int> conteoEnfrentamientos,
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
      conteoEnfrentamientos: conteoEnfrentamientos,
      diferenciaMaxPeso: config.diferenciaMaxPeso,
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

    // Construir grafo priorizado: primero aristas sin repetir contrincantes
    // previos, luego las que repiten como respaldo.
    final grafoPriorizado = graphBuilder.construirGrafoPriorizado(todosGallos);

    print('    Gallos otros partidos: ${gallosOtros.length}');
    for (final pid in partidosActivos.where((p) => p != partidoDobleId)) {
      final gs = gallosOtros.where((g) => g.partidoId == pid);
      print(
        '      P$pid: ${gs.map((g) => "${g.anillo}(${g.pesoGramos}g)").toList()}',
      );
    }
    print('    Total gallos para grafo: ${todosGallos.length}');
    print(
      '    Aristas preferidas: ${grafoPriorizado.preferidas.length}, '
      'respaldo: ${grafoPriorizado.respaldo.length}',
    );

    // Fase 1: Intentar matching doble solo con aristas preferidas
    //         (sin repetir enfrentamientos previos entre partidos)
    print('    Resolviendo _solverDoble (fase 1: sin repetir)...');
    try {
      final resultado = _solverDoble(
        aristas: grafoPriorizado.preferidas,
        partidosActivos: partidosActivos,
        partidoDobleId: partidoDobleId,
        rondaNumero: rondaNumero,
      );
      return _construirRondaDoble(
        resultado: resultado,
        rondaNumero: rondaNumero,
        partidoDobleId: partidoDobleId,
        todosGallos: todosGallos,
        gallosYaPeleados: gallosYaPeleados,
      );
    } on DerbyException catch (e) {
      print(
        '    Fase 1 doble falló: '
        '${e is MatchingImposibleException ? e.detalle : e}',
      );
    }

    // Fase 2: Incluir aristas de respaldo (permite repetir contrincantes)
    // Las aristas de respaldo ya llevan penalización incorporada.
    // Ordenar por costoTotal para que el solver priorice aristas sin repetir.
    final todasAristas = [
      ...grafoPriorizado.preferidas,
      ...grafoPriorizado.respaldo,
    ];
    todasAristas.sort((a, b) => a.costoTotal.compareTo(b.costoTotal));

    print(
      '    Resolviendo _solverDoble (fase 2: con respaldo, '
      '${todasAristas.length} aristas)...',
    );
    ResultadoMatching resultado;
    try {
      resultado = _solverDoble(
        aristas: todasAristas,
        partidosActivos: partidosActivos,
        partidoDobleId: partidoDobleId,
        rondaNumero: rondaNumero,
      );
    } catch (e) {
      if (e is MatchingImposibleException && config.diferenciaMaxPeso > 0) {
        print(
          '    ⚠️ Fase 2 doble falló. Reintentando sin límite de peso (diff mínima global)...',
        );
        final flexBuilder = GraphBuilder(
          compadres: compadres,
          gallosUsados: gallosYaPeleados,
          conteoEnfrentamientos: conteoEnfrentamientos,
          diferenciaMaxPeso: 0.0,
        );
        final flexGrafo = flexBuilder.construirGrafoPriorizado(todosGallos);
        final flexAristas = [...flexGrafo.preferidas, ...flexGrafo.respaldo];
        flexAristas.sort((a, b) => a.costoTotal.compareTo(b.costoTotal));

        resultado = _solverDoble(
          aristas: flexAristas,
          partidosActivos: partidosActivos,
          partidoDobleId: partidoDobleId,
          rondaNumero: rondaNumero,
        );
      } else {
        rethrow;
      }
    }

    return _construirRondaDoble(
      resultado: resultado,
      rondaNumero: rondaNumero,
      partidoDobleId: partidoDobleId,
      todosGallos: todosGallos,
      gallosYaPeleados: gallosYaPeleados,
    );
  }

  /// Construye la [Ronda] a partir del resultado de _solverDoble.
  Ronda _construirRondaDoble({
    required ResultadoMatching resultado,
    required int rondaNumero,
    required int partidoDobleId,
    required List<Gallo> todosGallos,
    required Set<int> gallosYaPeleados,
  }) {
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
      gallosYaPeleados: gallosYaPeleados,
      partidosDobles: [partidoDobleId],
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

    // Validar: máximo 1 partido pelea doble por ronda
    assert(
      [partidoDobleId].length <= 1,
      'Máximo 1 partido puede pelear doble por ronda',
    );

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
  ///
  /// Usa [costoTotal] (peso + penalización) para la optimización. Esto
  /// garantiza que aristas con repeticiones solo se usen como último
  /// recurso (estilo Tuums: facilidad gradual).
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

    List<ParEmparejado>? mejorSolucion;
    var mejorCosto = double.infinity;
    var iteraciones = 0;
    const maxIter = 500000;

    void buscar(
      int indiceArista,
      List<ParEmparejado> pares,
      Map<int, int> vecesUsado,
      Set<int> gallosUsados,
      double costo,
    ) {
      iteraciones++;
      if (iteraciones > maxIter) return;

      if (pares.length == totalPares) {
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

        final limA = pA == partidoDobleId ? 2 : 1;
        final limB = pB == partidoDobleId ? 2 : 1;
        if (usosA >= limA || usosB >= limB) continue;

        if (gallosUsados.contains(ar.galloA.id) ||
            gallosUsados.contains(ar.galloB.id)) {
          continue;
        }

        if (!partidosActivos.contains(pA) && pA != partidoDobleId) continue;
        if (!partidosActivos.contains(pB) && pB != partidoDobleId) continue;

        // Usar costoTotal (peso + penalización por repetición)
        if (costo + ar.costoTotal >= mejorCosto) continue;

        pares.add(
          ParEmparejado(
            galloA: ar.galloA,
            galloB: ar.galloB,
            diferencia: ar.peso, // peso REAL para display, sin penalización
          ),
        );
        vecesUsado[pA] = usosA + 1;
        vecesUsado[pB] = usosB + 1;
        gallosUsados.add(ar.galloA.id);
        gallosUsados.add(ar.galloB.id);

        buscar(i + 1, pares, vecesUsado, gallosUsados, costo + ar.costoTotal);

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
      // Calcular suma real (sin penalizaciones) para display
      final sumaReal = mejorSolucion!.fold(0.0, (sum, p) => sum + p.diferencia);
      for (final p in mejorSolucion!) {
        print(
          '      ${p.galloA.anillo}(P${p.galloA.partidoId}) vs ${p.galloB.anillo}(P${p.galloB.partidoId}) diff=${p.diferencia}g',
        );
      }
      return ResultadoMatching(pares: mejorSolucion!, sumaTotal: sumaReal);
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
    required Map<(int, int), int> conteoEnfrentamientos,
    required int rondaNumero,
    required List<int> partidosBye,
    required List<int> partidosDobles,
    bool permitirSobrante = false,
  }) {
    // 4. Seleccionar gallos PL disponibles (base nunca participa)
    final gallosDisponibles = gallos.where((g) {
      if (!partidosActivos.contains(g.partidoId)) return false;
      if (gallosYaPeleados.contains(g.id)) return false;
      return !g.esBase; // Solo gallos libres
    }).toList();

    print('    _intentarMatching(ronda=$rondaNumero, bye=$partidosBye)');
    print(
      '    Gallos disponibles: ${gallosDisponibles.length}, partidos activos: ${partidosActivos.length}',
    );

    // 5. Construir grafo
    final graphBuilder = GraphBuilder(
      compadres: compadres,
      gallosUsados: gallosYaPeleados,
      conteoEnfrentamientos: conteoEnfrentamientos,
      diferenciaMaxPeso: config.diferenciaMaxPeso,
    );

    // 6. Resolver matching
    print('    Resolviendo matching normal...');
    ResultadoMatching resultado;
    try {
      resultado = _solver.resolver(
        gallosDisponibles: gallosDisponibles,
        partidosActivos: partidosActivos,
        graphBuilder: graphBuilder,
        rondaNumero: rondaNumero,
        permitirRepeticiones: config.permitirRepeticiones,
      );
    } catch (e) {
      if (e is MatchingImposibleException && config.diferenciaMaxPeso > 0) {
        print(
          '    ⚠️ Matching imposible con diffMaxPeso=${config.diferenciaMaxPeso}g, reintentando sin límite de peso (diff mínima global)...',
        );
        final flexBuilder = GraphBuilder(
          compadres: compadres,
          gallosUsados: gallosYaPeleados,
          conteoEnfrentamientos: conteoEnfrentamientos,
          diferenciaMaxPeso: 0.0, // bypass param
        );
        resultado = _solver.resolver(
          gallosDisponibles: gallosDisponibles,
          partidosActivos: partidosActivos,
          graphBuilder: flexBuilder,
          rondaNumero: rondaNumero,
          permitirRepeticiones: config.permitirRepeticiones,
        );
      } else {
        rethrow;
      }
    }

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
      gallosYaPeleados: gallosYaPeleados,
      partidosDobles: partidosDobles,
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
    //    Si impar y permitirSobrante: tolerar sobrantes (no hay bye,
    //    simplemente no pelean y no reciben puntos gratis).
    //    El sobrante mínimo es 1 (impar), pero restricciones de peso
    //    pueden dejar más fuera.
    if (resultado.partidosSinEmparejar.isNotEmpty) {
      if (!permitirSobrante) {
        throw RondaIncompletaException(
          partidosSinEmparejar: resultado.partidosSinEmparejar.length,
          idsNoEmparejados: resultado.partidosSinEmparejar,
        );
      }
      // Log de sobrantes para análisis
      print(
        '    Sobrantes tolerados (${resultado.partidosSinEmparejar.length}): '
        '${resultado.partidosSinEmparejar.map((id) => "P$id").join(", ")}',
      );
    }

    return Ronda(
      numero: rondaNumero,
      enfrentamientos: enfrentamientos,
      esRondaBase: false,
      fechaCreacion: DateTime.now(),
      partidosBye: partidosBye,
      partidosDobles: partidosDobles,
    );
  }

  /// Genera TODAS las rondas de una sola vez usando optimización global
  /// multi-ronda con criterio minimax (minimizar la diferencia máxima individual).
  ///
  /// Retorna lista de [Ronda] numeradas 1..numRondas.
  /// Lanza si no encuentra solución viable.
  List<Ronda> generarSorteoPLGlobal({
    required List<Partido> partidos,
    required List<Gallo> gallos,
    required List<Compadres> compadres,
    int? numRondasOverride,
  }) {
    final numRondasPL = numRondasOverride ?? config.rondasTotales;
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
