import 'package:test/test.dart';
import 'package:derby2_flutter/domain/domain.dart';
import 'package:derby2_flutter/engine/engine.dart';
import 'package:derby2_flutter/application/usecases/generar_sorteo.dart';

void main() {
  // ============================================================
  // HELPERS
  // ============================================================
  Gallo _gallo(int id, int partidoId, double peso, {bool esBase = false}) {
    return Gallo(
      id: id,
      partidoId: partidoId,
      anillo: 'A-$id',
      pesoGramos: peso,
      esBase: esBase,
    );
  }

  Partido _partido(int id, {int puntos = 0}) {
    return Partido(id: id, nombre: 'Partido $id', puntos: puntos);
  }

  // ============================================================
  // GRAPH BUILDER
  // ============================================================
  group('GraphBuilder', () {
    test('no genera aristas entre gallos del mismo partido', () {
      final builder = GraphBuilder(compadres: []);
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2010),
        _gallo(3, 2, 2005),
      ];

      final aristas = builder.construirGrafo(gallos);

      // Solo 1→3 y 2→3, nunca 1→2 (mismo partido)
      expect(aristas.length, 2);
      for (final a in aristas) {
        expect(a.galloA.partidoId, isNot(equals(a.galloB.partidoId)));
      }
    });

    test('no genera aristas entre compadres', () {
      final compadres = [const Compadres(id: 1, partidoIdA: 1, partidoIdB: 2)];
      final builder = GraphBuilder(compadres: compadres);
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 2, 2005),
        _gallo(3, 3, 2010),
      ];

      final aristas = builder.construirGrafo(gallos);

      // Solo 1→3 y 2→3, nunca 1→2 (compadres)
      expect(aristas.length, 2);
      for (final a in aristas) {
        final pids = {a.galloA.partidoId, a.galloB.partidoId};
        expect(pids.contains(1) && pids.contains(2), isFalse);
      }
    });

    test('excluye gallos ya usados', () {
      final builder = GraphBuilder(compadres: [], gallosUsados: {1});
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 2, 2005),
        _gallo(3, 3, 2010),
      ];

      final aristas = builder.construirGrafo(gallos);

      // Gallo 1 excluido, solo queda 2→3
      expect(aristas.length, 1);
      expect(aristas[0].galloA.id, 2);
      expect(aristas[0].galloB.id, 3);
    });

    test('ordena aristas por peso (diferencia) ascendente', () {
      final builder = GraphBuilder(compadres: []);
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 2, 2100),
        _gallo(3, 3, 2010),
      ];

      final aristas = builder.construirGrafo(gallos);

      // Deben estar ordenadas: menor diferencia primero
      for (var i = 1; i < aristas.length; i++) {
        expect(aristas[i].peso, greaterThanOrEqualTo(aristas[i - 1].peso));
      }
    });

    test('filtra aristas por diferencia máxima de peso', () {
      final builder = GraphBuilder(compadres: [], diferenciaMaxPeso: 50);
      final gallos = [
        _gallo(1, 1, 2000), // diff con gallo 2 = 100g → excluida
        _gallo(2, 2, 2100), // diff con gallo 3 = 70g  → excluida
        _gallo(3, 3, 2030), // diff con gallo 1 = 30g  → incluida
      ];

      final aristas = builder.construirGrafo(gallos);

      // Solo gallo 1↔3 (diff=30) debe pasar. 1↔2 (100g) y 2↔3 (70g) excluidas.
      expect(aristas.length, 1);
      expect(aristas[0].galloA.id, 1);
      expect(aristas[0].galloB.id, 3);
    });

    test('no filtra peso en ronda base', () {
      final builder = GraphBuilder(
        compadres: [],
        diferenciaMaxPeso: 50,
        esRondaBase: true,
      );
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 2, 2100),
        _gallo(3, 3, 2030),
      ];

      final aristas = builder.construirGrafo(gallos);

      // Ronda base: no se aplica filtro de peso → 3 aristas posibles
      expect(aristas.length, 3);
    });

    test('diferenciaMaxPeso=0 no aplica filtro', () {
      final builder = GraphBuilder(compadres: [], diferenciaMaxPeso: 0);
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 2, 2500),
        _gallo(3, 3, 2030),
      ];

      final aristas = builder.construirGrafo(gallos);

      // Sin límite: todas las aristas válidas
      expect(aristas.length, 3);
    });

    test('prioriza aristas sin enfrentamiento previo', () {
      final builder = GraphBuilder(
        compadres: [],
        conteoEnfrentamientos: {(1, 2): 1},
      );
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 2, 2005),
        _gallo(3, 3, 2010),
      ];

      final resultado = builder.construirGrafoPriorizado(gallos);

      // 1 vs 2 ya se enfrentaron → va a respaldo
      expect(
        resultado.respaldo.any(
          (a) => {a.galloA.partidoId, a.galloB.partidoId}.containsAll({1, 2}),
        ),
        isTrue,
      );
      // 1 vs 3 y 2 vs 3 → preferidas
      expect(resultado.preferidas.length, 2);
    });
  });

  // ============================================================
  // CONSTRAINT VALIDATOR
  // ============================================================
  group('ConstraintValidator', () {
    test('detecta gallos del mismo partido', () {
      final validator = ConstraintValidator(compadres: []);
      final enfrentamientos = [
        Enfrentamiento(
          id: 1,
          rondaNumero: 1,
          galloA: _gallo(1, 1, 2000),
          galloB: _gallo(2, 1, 2010), // ¡Mismo partido!
          diferenciaPeso: 10,
        ),
      ];

      final errores = validator.validarRonda(enfrentamientos);
      expect(errores, isNotEmpty);
      expect(errores.first, contains('MISMO partido'));
    });

    test('detecta compadres', () {
      final compadres = [const Compadres(id: 1, partidoIdA: 1, partidoIdB: 2)];
      final validator = ConstraintValidator(compadres: compadres);
      final enfrentamientos = [
        Enfrentamiento(
          id: 1,
          rondaNumero: 1,
          galloA: _gallo(1, 1, 2000),
          galloB: _gallo(2, 2, 2010), // Compadres
          diferenciaPeso: 10,
        ),
      ];

      final errores = validator.validarRonda(enfrentamientos);
      expect(errores, isNotEmpty);
      expect(errores.first, contains('COMPADRES'));
    });

    test('detecta gallo duplicado en ronda', () {
      final validator = ConstraintValidator(compadres: []);
      final enfrentamientos = [
        Enfrentamiento(
          id: 1,
          rondaNumero: 1,
          galloA: _gallo(1, 1, 2000),
          galloB: _gallo(2, 2, 2010),
          diferenciaPeso: 10,
        ),
        Enfrentamiento(
          id: 2,
          rondaNumero: 1,
          galloA: _gallo(1, 3, 2000), // ¡Gallo 1 repetido!
          galloB: _gallo(3, 4, 2020),
          diferenciaPeso: 20,
        ),
      ];

      final errores = validator.validarRonda(enfrentamientos);
      expect(errores, isNotEmpty);
      expect(errores.any((e) => e.contains('MÁS DE UNA VEZ')), isTrue);
    });

    test('detecta gallo base en ronda no-base', () {
      final validator = ConstraintValidator(compadres: []);
      final enfrentamientos = [
        Enfrentamiento(
          id: 1,
          rondaNumero: 1,
          galloA: _gallo(1, 1, 2000, esBase: true), // ¡Base en ronda 1!
          galloB: _gallo(2, 2, 2010),
          diferenciaPeso: 10,
        ),
      ];

      final errores = validator.validarGallosBase(
        enfrentamientos,
        esRondaBase: false,
        rondaNumero: 1,
      );
      expect(errores, isNotEmpty);
      expect(errores.first, contains('solo en la ronda base'));
    });

    test('detecta gallo no-base en ronda base', () {
      final validator = ConstraintValidator(compadres: []);
      final enfrentamientos = [
        Enfrentamiento(
          id: 1,
          rondaNumero: 4,
          galloA: _gallo(1, 1, 2000), // ¡No es base en ronda base!
          galloB: _gallo(2, 2, 2010, esBase: true),
          diferenciaPeso: 10,
        ),
      ];

      final errores = validator.validarGallosBase(
        enfrentamientos,
        esRondaBase: true,
        rondaNumero: 4,
      );
      expect(errores, isNotEmpty);
      expect(errores.first, contains('NO es base'));
    });

    test('valida ronda base con rondasTotales=3', () {
      final validator = ConstraintValidator(compadres: []);
      // Con 3 rondas totales, la ronda 3 es la base
      final enfrentamientos = [
        Enfrentamiento(
          id: 1,
          rondaNumero: 3,
          galloA: _gallo(1, 1, 2000, esBase: true),
          galloB: _gallo(2, 2, 2010, esBase: true),
          diferenciaPeso: 10,
        ),
      ];

      final errores = validator.validarGallosBase(
        enfrentamientos,
        esRondaBase: true,
        rondaNumero: 3,
      );
      expect(
        errores,
        isEmpty,
        reason: 'Ronda 3 como base debe aceptar gallos base',
      );
    });

    test('valida partido con gallos correctos', () {
      final validator = ConstraintValidator(compadres: []);
      final partido = _partido(1);
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2010),
        _gallo(3, 1, 2020),
        _gallo(4, 1, 2030, esBase: true),
      ];

      final errores = validator.validarPartido(partido, gallos);
      expect(errores, isEmpty);
    });

    test('detecta partido con gallos insuficientes', () {
      final validator = ConstraintValidator(compadres: []);
      final partido = _partido(1);
      // Solo gallo base, sin libres → debe reportar error
      final gallos = [_gallo(1, 1, 2000, esBase: true)];

      final errores = validator.validarPartido(partido, gallos);
      expect(errores, isNotEmpty);
    });
  });

  // ============================================================
  // MATCHING SOLVER
  // ============================================================
  group('MatchingSolver', () {
    test('matching básico 2 partidos', () {
      final solver = MatchingSolver();
      final gallos = [_gallo(1, 1, 2000), _gallo(2, 2, 2005)];
      final builder = GraphBuilder(compadres: []);

      final resultado = solver.resolver(
        gallosDisponibles: gallos,
        partidosActivos: {1, 2},
        graphBuilder: builder,
        rondaNumero: 1,
      );

      expect(resultado.esCompleto, isTrue);
      expect(resultado.pares.length, 1);
      expect(resultado.sumaTotal, 5.0);
    });

    test('matching 4 partidos minimiza diferencia total', () {
      final solver = MatchingSolver();
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 2, 2002),
        _gallo(3, 3, 2100),
        _gallo(4, 4, 2105),
      ];
      final builder = GraphBuilder(compadres: []);

      final resultado = solver.resolver(
        gallosDisponibles: gallos,
        partidosActivos: {1, 2, 3, 4},
        graphBuilder: builder,
        rondaNumero: 1,
      );

      expect(resultado.esCompleto, isTrue);
      expect(resultado.pares.length, 2);
      // Óptimo: (1→2, diff=2) + (3→4, diff=5) = 7
      expect(resultado.sumaTotal, 7.0);
    });

    test('matching respeta compadres', () {
      final compadres = [const Compadres(id: 1, partidoIdA: 1, partidoIdB: 2)];
      final solver = MatchingSolver();
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 2, 2001), // Peso similar pero compadres
        _gallo(3, 3, 2100),
        _gallo(4, 4, 2050),
      ];
      final builder = GraphBuilder(compadres: compadres);

      final resultado = solver.resolver(
        gallosDisponibles: gallos,
        partidosActivos: {1, 2, 3, 4},
        graphBuilder: builder,
        rondaNumero: 1,
      );

      expect(resultado.esCompleto, isTrue);
      // Verificar que 1 y 2 NO se enfrentan
      for (final par in resultado.pares) {
        final pids = {par.galloA.partidoId, par.galloB.partidoId};
        expect(
          pids.containsAll({1, 2}),
          isFalse,
          reason: 'Partidos compadres 1 y 2 no deben enfrentarse',
        );
      }
    });

    test('matching con 6 partidos', () {
      final solver = MatchingSolver();
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 2, 2010),
        _gallo(3, 3, 2020),
        _gallo(4, 4, 2030),
        _gallo(5, 5, 2040),
        _gallo(6, 6, 2050),
      ];
      final builder = GraphBuilder(compadres: []);

      final resultado = solver.resolver(
        gallosDisponibles: gallos,
        partidosActivos: {1, 2, 3, 4, 5, 6},
        graphBuilder: builder,
        rondaNumero: 1,
      );

      expect(resultado.esCompleto, isTrue);
      expect(resultado.pares.length, 3);
      // Óptimo: emparejamiento consecutivo = 3 × 10 = 30
      expect(resultado.sumaTotal, 30.0);
    });

    test('lanza excepción si no hay gallos', () {
      final solver = MatchingSolver();
      final builder = GraphBuilder(compadres: []);

      expect(
        () => solver.resolver(
          gallosDisponibles: [],
          partidosActivos: {1, 2},
          graphBuilder: builder,
          rondaNumero: 1,
        ),
        throwsA(isA<MatchingImposibleException>()),
      );
    });

    test('matching con múltiples gallos por partido (elige el mejor)', () {
      final solver = MatchingSolver();
      // Partido 1 tiene dos gallos disponibles
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2090), // Otro gallo de partido 1
        _gallo(3, 2, 2005),
        _gallo(4, 2, 2100),
      ];
      final builder = GraphBuilder(compadres: []);

      final resultado = solver.resolver(
        gallosDisponibles: gallos,
        partidosActivos: {1, 2},
        graphBuilder: builder,
        rondaNumero: 1,
      );

      expect(resultado.esCompleto, isTrue);
      expect(resultado.pares.length, 1);
      // Debe elegir 1 vs 3 (diff=5) que es la menor diferencia
      expect(resultado.sumaTotal, 5.0);
    });
  });

  // ============================================================
  // ELIMINATION SERVICE
  // ============================================================
  group('EliminationService', () {
    test('no elimina si todos pueden ganar', () {
      final service = EliminationService();
      final partidos = [
        _partido(1, puntos: 2),
        _partido(2, puntos: 2),
        _partido(3, puntos: 1),
        _partido(4, puntos: 0),
      ];

      final eliminados = service.partidosEliminados(
        partidos: partidos,
        rondasRestantes: 2,
        puntosVictoria: 1,
        posicionesPremio: 3,
      );

      expect(eliminados, isEmpty);
    });

    test('elimina partido que no puede alcanzar zona de premio', () {
      final service = EliminationService();
      final partidos = [
        _partido(1, puntos: 4),
        _partido(2, puntos: 4),
        _partido(3, puntos: 3),
        _partido(4, puntos: 0), // Max posible: 0+1=1, pero los 3 de arriba ≥3
      ];

      final eliminados = service.partidosEliminados(
        partidos: partidos,
        rondasRestantes: 1,
        puntosVictoria: 1,
        posicionesPremio: 3,
      );

      expect(eliminados.contains(4), isTrue);
    });

    test('análisis detallado retorna datos correctos', () {
      final service = EliminationService();
      final partidos = [_partido(1, puntos: 3), _partido(2, puntos: 2)];

      final analisis = service.analizar(
        partidos: partidos,
        rondasRestantes: 1,
        puntosVictoria: 1,
        posicionesPremio: 1,
      );

      expect(analisis.length, 2);
      final a1 = analisis.firstWhere((a) => a.partidoId == 1);
      expect(a1.puntosActuales, 3);
      expect(a1.puntosMaximosPosibles, 4);
    });
  });

  // ============================================================
  // DERBY ENGINE (INTEGRACIÓN)
  // ============================================================
  group('DerbyEngine', () {
    test('genera ronda 1 correctamente con 4 partidos', () {
      final engine = DerbyEngine(config: const DerbyConfig(), compadres: []);

      final partidos = [_partido(1), _partido(2), _partido(3), _partido(4)];

      final gallos = [
        // Partido 1: 3 libres + 1 base
        _gallo(1, 1, 2000), _gallo(2, 1, 2010), _gallo(3, 1, 2020),
        _gallo(4, 1, 2030, esBase: true),
        // Partido 2
        _gallo(5, 2, 2005), _gallo(6, 2, 2015), _gallo(7, 2, 2025),
        _gallo(8, 2, 2035, esBase: true),
        // Partido 3
        _gallo(9, 3, 2002), _gallo(10, 3, 2012), _gallo(11, 3, 2022),
        _gallo(12, 3, 2032, esBase: true),
        // Partido 4
        _gallo(13, 4, 2008), _gallo(14, 4, 2018), _gallo(15, 4, 2028),
        _gallo(16, 4, 2038, esBase: true),
      ];

      final ronda = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: [],
        rondaNumero: 1,
      );

      expect(ronda.numero, 1);
      expect(ronda.enfrentamientos.length, 2); // 4 partidos = 2 peleas
      expect(ronda.esRondaBase, isFalse);

      // Verificar que ningún gallo base pelea en ronda 1
      for (final e in ronda.enfrentamientos) {
        expect(e.galloA.esBase, isFalse);
        expect(e.galloB.esBase, isFalse);
      }
    });

    test('genera ronda 4 solo con gallos base', () {
      final engine = DerbyEngine(config: const DerbyConfig(), compadres: []);

      final partidos = [_partido(1), _partido(2)];

      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2010),
        _gallo(3, 1, 2020),
        _gallo(4, 1, 2030, esBase: true),
        _gallo(5, 2, 2005),
        _gallo(6, 2, 2015),
        _gallo(7, 2, 2025),
        _gallo(8, 2, 2035, esBase: true),
      ];

      // Simular rondas 1-3 (gallos libres ya pelearon)
      final rondasPrevias = [
        Ronda(
          numero: 1,
          enfrentamientos: [
            Enfrentamiento(
              id: 1,
              rondaNumero: 1,
              galloA: gallos[0],
              galloB: gallos[4],
              diferenciaPeso: 5,
              resultado: ResultadoPelea.ganoA,
            ),
          ],
        ),
        Ronda(
          numero: 2,
          enfrentamientos: [
            Enfrentamiento(
              id: 2,
              rondaNumero: 2,
              galloA: gallos[1],
              galloB: gallos[5],
              diferenciaPeso: 5,
              resultado: ResultadoPelea.ganoB,
            ),
          ],
        ),
        Ronda(
          numero: 3,
          enfrentamientos: [
            Enfrentamiento(
              id: 3,
              rondaNumero: 3,
              galloA: gallos[2],
              galloB: gallos[6],
              diferenciaPeso: 5,
              resultado: ResultadoPelea.empate,
            ),
          ],
        ),
      ];

      final ronda4 = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: rondasPrevias,
        rondaNumero: 4,
      );

      expect(ronda4.numero, 4);
      expect(ronda4.esRondaBase, isTrue);
      expect(ronda4.enfrentamientos.length, 1);
      expect(ronda4.enfrentamientos[0].galloA.esBase, isTrue);
      expect(ronda4.enfrentamientos[0].galloB.esBase, isTrue);
    });

    test('respeta restricción de compadres en generación', () {
      final compadres = [const Compadres(id: 1, partidoIdA: 1, partidoIdB: 2)];
      final engine = DerbyEngine(
        config: const DerbyConfig(diferenciaMaxPeso: 0),
        compadres: compadres,
      );

      final partidos = [_partido(1), _partido(2), _partido(3), _partido(4)];

      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2010),
        _gallo(3, 1, 2020),
        _gallo(4, 1, 2030, esBase: true),
        _gallo(5, 2, 2001),
        _gallo(6, 2, 2011),
        _gallo(7, 2, 2021),
        _gallo(8, 2, 2031, esBase: true),
        _gallo(9, 3, 2100),
        _gallo(10, 3, 2110),
        _gallo(11, 3, 2120),
        _gallo(12, 3, 2130, esBase: true),
        _gallo(13, 4, 2105),
        _gallo(14, 4, 2115),
        _gallo(15, 4, 2125),
        _gallo(16, 4, 2135, esBase: true),
      ];

      final ronda = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: compadres,
        rondasPrevias: [],
        rondaNumero: 1,
      );

      // Verificar que 1 y 2 NO se enfrentan
      for (final e in ronda.enfrentamientos) {
        final pids = {e.galloA.partidoId, e.galloB.partidoId};
        expect(
          pids.containsAll({1, 2}),
          isFalse,
          reason: 'Compadres 1 y 2 no deben enfrentarse',
        );
      }
    });

    test('actualiza puntos correctamente', () {
      final engine = DerbyEngine(config: const DerbyConfig(), compadres: []);

      final partidos = [_partido(1), _partido(2)];
      final ronda = Ronda(
        numero: 1,
        enfrentamientos: [
          Enfrentamiento(
            id: 1,
            rondaNumero: 1,
            galloA: _gallo(1, 1, 2000),
            galloB: _gallo(2, 2, 2010),
            diferenciaPeso: 10,
            resultado: ResultadoPelea.ganoA,
          ),
        ],
      );

      final actualizados = engine.actualizarPuntos(partidos, ronda);
      final p1 = actualizados.firstWhere((p) => p.id == 1);
      final p2 = actualizados.firstWhere((p) => p.id == 2);

      expect(p1.puntos, 1); // Ganó
      expect(p2.puntos, 0); // Perdió
    });

    test('valida derby: detecta partido incompleto', () {
      final engine = DerbyEngine(config: const DerbyConfig(), compadres: []);

      final partidos = [_partido(1), _partido(2)];
      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2010),
        // Partido 1 solo tiene 2 gallos
        _gallo(3, 2, 2005),
        _gallo(4, 2, 2015),
        _gallo(5, 2, 2025),
        _gallo(6, 2, 2035, esBase: true),
      ];

      final errores = engine.validarDerby(partidos, gallos);
      expect(errores, isNotEmpty);
    });

    test('matching determinista: mismos datos = mismo resultado', () {
      final engine = DerbyEngine(config: const DerbyConfig(), compadres: []);

      final partidos = [_partido(1), _partido(2), _partido(3), _partido(4)];

      final gallos = [
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2010),
        _gallo(3, 1, 2020),
        _gallo(4, 1, 2030, esBase: true),
        _gallo(5, 2, 2005),
        _gallo(6, 2, 2015),
        _gallo(7, 2, 2025),
        _gallo(8, 2, 2035, esBase: true),
        _gallo(9, 3, 2002),
        _gallo(10, 3, 2012),
        _gallo(11, 3, 2022),
        _gallo(12, 3, 2032, esBase: true),
        _gallo(13, 4, 2008),
        _gallo(14, 4, 2018),
        _gallo(15, 4, 2028),
        _gallo(16, 4, 2038, esBase: true),
      ];

      final ronda1 = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: [],
        rondaNumero: 1,
      );

      final ronda1b = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: [],
        rondaNumero: 1,
      );

      // Determinista: los pares deben ser idénticos
      expect(ronda1.enfrentamientos.length, ronda1b.enfrentamientos.length);
      for (var i = 0; i < ronda1.enfrentamientos.length; i++) {
        expect(
          ronda1.enfrentamientos[i].galloA.id,
          ronda1b.enfrentamientos[i].galloA.id,
        );
        expect(
          ronda1.enfrentamientos[i].galloB.id,
          ronda1b.enfrentamientos[i].galloB.id,
        );
      }
    });
  });

  // ============================================================
  // STRESS TEST
  // ============================================================
  group('Stress test', () {
    test('soporta 30 partidos sin degradación', () {
      final numPartidos = 30;
      final partidos = List.generate(numPartidos, (i) => _partido(i + 1));

      final gallos = <Gallo>[];
      var galloId = 1;
      for (var i = 0; i < numPartidos; i++) {
        final pid = i + 1;
        final basePeso = 1800.0 + (i * 15);
        gallos.add(_gallo(galloId++, pid, basePeso));
        gallos.add(_gallo(galloId++, pid, basePeso + 5));
        gallos.add(_gallo(galloId++, pid, basePeso + 10));
        gallos.add(_gallo(galloId++, pid, basePeso + 20, esBase: true));
      }

      // Algunos compadres
      final compadres = [
        const Compadres(id: 1, partidoIdA: 1, partidoIdB: 2),
        const Compadres(id: 2, partidoIdA: 3, partidoIdB: 4),
        const Compadres(id: 3, partidoIdA: 5, partidoIdB: 6),
      ];

      final engine = DerbyEngine(
        config: const DerbyConfig(diferenciaMaxPeso: 0),
        compadres: compadres,
      );

      final stopwatch = Stopwatch()..start();

      final ronda = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: compadres,
        rondasPrevias: [],
        rondaNumero: 1,
      );

      stopwatch.stop();

      expect(ronda.enfrentamientos.length, numPartidos ~/ 2);
      // Debe completar en tiempo razonable
      expect(stopwatch.elapsedMilliseconds, lessThan(30000));

      // Verificar integridad
      final partidosEmparejados = <int>{};
      for (final e in ronda.enfrentamientos) {
        expect(e.galloA.partidoId, isNot(equals(e.galloB.partidoId)));
        expect(partidosEmparejados.contains(e.galloA.partidoId), isFalse);
        expect(partidosEmparejados.contains(e.galloB.partidoId), isFalse);
        partidosEmparejados.add(e.galloA.partidoId);
        partidosEmparejados.add(e.galloB.partidoId);
      }
    });

    test('soporta 60 partidos con greedy', () {
      final numPartidos = 60;
      final partidos = List.generate(numPartidos, (i) => _partido(i + 1));

      final gallos = <Gallo>[];
      var galloId = 1;
      for (var i = 0; i < numPartidos; i++) {
        final pid = i + 1;
        final basePeso = 1800.0 + (i * 10);
        gallos.add(_gallo(galloId++, pid, basePeso));
        gallos.add(_gallo(galloId++, pid, basePeso + 3));
        gallos.add(_gallo(galloId++, pid, basePeso + 7));
        gallos.add(_gallo(galloId++, pid, basePeso + 15, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(diferenciaMaxPeso: 0),
        compadres: [],
      );

      final stopwatch = Stopwatch()..start();

      final ronda = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: [],
        rondaNumero: 1,
      );

      stopwatch.stop();

      expect(ronda.enfrentamientos.length, numPartidos ~/ 2);
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    });
  });

  // ============================================================
  // DOBLE PELEA & COMODÍN (NO BYE)
  // ============================================================
  group('Doble pelea & Comodín (sin BYE)', () {
    test('3 partidos ronda 1: doble pelea en vez de bye', () {
      final partidos = [_partido(1), _partido(2), _partido(3)];
      final gallos = <Gallo>[];
      var gid = 1;
      for (final p in partidos) {
        for (var i = 0; i < 5; i++) {
          gallos.add(_gallo(gid++, p.id, 2000 + i * 5));
        }
        gallos.add(_gallo(gid++, p.id, 2000, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(diferenciaMaxPeso: 0),
        compadres: [],
      );

      final ronda = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: [],
        rondaNumero: 1,
      );

      // Doble pelea: 2 enfrentamientos (doble partido fights twice)
      expect(ronda.enfrentamientos.length, 2);
      expect(ronda.tieneDoble, isTrue);
      expect(ronda.partidosDobles.length, 1);
      expect(ronda.tieneBye, isFalse);
    });

    test('5 partidos ronda 1: doble pelea genera 3 enfrentamientos', () {
      final partidos = List.generate(5, (i) => _partido(i + 1));
      final gallos = <Gallo>[];
      var gid = 1;
      for (final p in partidos) {
        for (var i = 0; i < 5; i++) {
          gallos.add(_gallo(gid++, p.id, 2000 + i * 5));
        }
        gallos.add(_gallo(gid++, p.id, 2000, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(diferenciaMaxPeso: 0),
        compadres: [],
      );

      final ronda = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: [],
        rondaNumero: 1,
      );

      expect(ronda.enfrentamientos.length, 3);
      expect(ronda.tieneDoble, isTrue);
      expect(ronda.partidosDobles.length, 1);
      expect(ronda.tieneBye, isFalse);
    });

    test(
      'doble partido participa en 2 enfrentamientos con gallos diferentes',
      () {
        final partidos = [_partido(1), _partido(2), _partido(3)];
        final gallos = <Gallo>[];
        var gid = 1;
        for (final p in partidos) {
          for (var i = 0; i < 5; i++) {
            gallos.add(_gallo(gid++, p.id, 2000 + i * 5));
          }
          gallos.add(_gallo(gid++, p.id, 2000, esBase: true));
        }

        final engine = DerbyEngine(
          config: const DerbyConfig(diferenciaMaxPeso: 0),
          compadres: [],
        );

        final ronda = engine.generarRonda(
          partidos: partidos,
          gallos: gallos,
          compadres: [],
          rondasPrevias: [],
          rondaNumero: 1,
        );

        final dobleId = ronda.partidosDobles.first;
        final dobleEnfs = ronda.enfrentamientos
            .where(
              (e) =>
                  e.galloA.partidoId == dobleId ||
                  e.galloB.partidoId == dobleId,
            )
            .toList();
        expect(dobleEnfs.length, 2);

        // Must use 2 different gallos
        final gallosUsados = dobleEnfs.map((e) {
          return e.galloA.partidoId == dobleId ? e.galloA.id : e.galloB.id;
        }).toSet();
        expect(
          gallosUsados.length,
          2,
          reason: 'Doble partido debe usar 2 gallos diferentes',
        );
      },
    );

    test('ronda >= 3 con impar sin comodín: un partido no participa', () {
      final partidos = [_partido(1), _partido(2), _partido(3)];
      final gallos = <Gallo>[];
      var gid = 1;
      for (final p in partidos) {
        for (var i = 0; i < 6; i++) {
          gallos.add(_gallo(gid++, p.id, 2000 + i * 5));
        }
        gallos.add(_gallo(gid++, p.id, 2000, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 0),
        compadres: [],
      );

      final rondas = <Ronda>[];
      for (var r = 1; r <= 2; r++) {
        rondas.add(
          engine.generarRonda(
            partidos: partidos,
            gallos: gallos,
            compadres: [],
            rondasPrevias: rondas,
            rondaNumero: r,
          ),
        );
      }

      // Round 3 (>=3) without comodín → tries doble, then one sits out
      final ronda3 = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: rondas,
        rondaNumero: 3,
      );

      // 3 partidos odd, no comodín → CASO C doble pelea exitosa (tienen gallos)
      expect(ronda3.enfrentamientos.length, 2);
      expect(ronda3.tieneBye, isFalse, reason: 'NO BYE');
      expect(ronda3.tieneDoble, isTrue);
    });

    test('ronda >= 3 con impar + comodín funciona correctamente', () {
      final partidos = [
        _partido(1),
        _partido(2),
        _partido(3),
        const Partido(id: 4, nombre: 'COMODIN', esComodin: true),
      ];
      final gallos = <Gallo>[];
      var gid = 1;
      for (final p in partidos) {
        for (var i = 0; i < 6; i++) {
          gallos.add(_gallo(gid++, p.id, 2000 + i * 5));
        }
        gallos.add(_gallo(gid++, p.id, 2000, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 0),
        compadres: [],
      );

      // Partidos 1-3 are active (3 = impar). Comodín is separate.

      final rondas = <Ronda>[];
      for (var r = 1; r <= 2; r++) {
        rondas.add(
          engine.generarRonda(
            partidos: partidos,
            gallos: gallos,
            compadres: [],
            rondasPrevias: rondas,
            rondaNumero: r,
          ),
        );
      }

      final ronda3 = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: rondas,
        rondaNumero: 3,
      );

      // Round 3: comodín enters → 4 partidos (even) → 2 fights
      expect(ronda3.enfrentamientos.length, 2);
      expect(ronda3.tieneBye, isFalse);
      expect(ronda3.tieneDoble, isFalse);
    });

    test('número par de partidos NO genera bye ni doble', () {
      final partidos = [_partido(1), _partido(2), _partido(3), _partido(4)];
      final gallos = <Gallo>[];
      var gid = 1;
      for (final p in partidos) {
        gallos.add(_gallo(gid++, p.id, 2000));
        gallos.add(_gallo(gid++, p.id, 2005));
        gallos.add(_gallo(gid++, p.id, 2010));
        gallos.add(_gallo(gid++, p.id, 2015, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(diferenciaMaxPeso: 0),
        compadres: [],
      );

      final ronda = engine.generarRonda(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: [],
        rondaNumero: 1,
      );

      expect(ronda.enfrentamientos.length, 2);
      expect(ronda.tieneBye, isFalse);
      expect(ronda.partidosBye, isEmpty);
      expect(ronda.tieneDoble, isFalse);
    });

    test('doble imposible por restricción de peso lanza error', () {
      // P1↔P2: compatible en peso, P3: incompatible con ambos.
      // Doble pelea impossible due to incompatible weights → error (NO BYE).
      final partidos = [_partido(1), _partido(2), _partido(3)];
      final gallos = <Gallo>[
        // P1: peso ~1800
        _gallo(1, 1, 1800), _gallo(2, 1, 1810), _gallo(3, 1, 1820),
        _gallo(4, 1, 1830, esBase: true),
        // P2: peso ~1800
        _gallo(5, 2, 1800), _gallo(6, 2, 1815), _gallo(7, 2, 1825),
        _gallo(8, 2, 1835, esBase: true),
        // P3: peso ~2200 (>80g de diferencia con P1/P2)
        _gallo(9, 3, 2200), _gallo(10, 3, 2210), _gallo(11, 3, 2220),
        _gallo(12, 3, 2230, esBase: true),
      ];

      final engine = DerbyEngine(
        config: const DerbyConfig(diferenciaMaxPeso: 80),
        compadres: [],
      );

      // Doble imposible → error (regla del juez: NO BYE fallback)
      expect(
        () => engine.generarRonda(
          partidos: partidos,
          gallos: gallos,
          compadres: [],
          rondasPrevias: [],
          rondaNumero: 1,
        ),
        throwsA(isA<MatchingImposibleException>()),
      );
    });

    test('3 partidos con comodín genera todas las rondas sin error', () {
      final partidos = [
        _partido(1),
        _partido(2),
        _partido(3),
        const Partido(id: 99, nombre: 'COMODIN', esComodin: true),
      ];
      final gallos = <Gallo>[];
      var gid = 1;
      for (final p in partidos) {
        // 6 PL gallos to support doble pelea across multiple rounds
        for (var i = 0; i < 6; i++) {
          gallos.add(_gallo(gid++, p.id, 2000 + i * 5));
        }
        gallos.add(_gallo(gid++, p.id, 2000, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 80),
        compadres: [],
      );

      final rondas = <Ronda>[];

      for (var r = 1; r <= 4; r++) {
        final ronda = engine.generarRonda(
          partidos: partidos,
          gallos: gallos,
          compadres: [],
          rondasPrevias: rondas,
          rondaNumero: r,
        );
        rondas.add(ronda);
      }

      expect(rondas.length, 4);
    });

    test('7 partidos con 3 PL genera todas las rondas', () {
      // 7 partidos, cada uno con exactamente 3 PL + 1 base.
      // R1-R2: doble pelea. R3: partidos sin gallos excluidos → odd →
      // sin comodín → un partido no participa. R4: base.
      final partidos = List.generate(7, (i) => _partido(i + 1));
      final gallos = <Gallo>[];
      var gid = 1;
      for (final p in partidos) {
        for (var i = 0; i < 3; i++) {
          gallos.add(_gallo(gid++, p.id, 2000 + i * 30));
        }
        gallos.add(_gallo(gid++, p.id, 2100, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 500),
        compadres: [],
      );

      final rondas = <Ronda>[];
      for (var r = 1; r <= 4; r++) {
        rondas.add(
          engine.generarRonda(
            partidos: partidos,
            gallos: gallos,
            compadres: [],
            rondasPrevias: rondas,
            rondaNumero: r,
          ),
        );
      }

      expect(rondas.length, 4);

      // R1-R2: doble pelea
      expect(rondas[0].tieneDoble, isTrue);
      expect(rondas[1].tieneDoble, isTrue);
      expect(rondas[0].tieneBye, isFalse);
      expect(rondas[1].tieneBye, isFalse);

      // R3: no BYE, some partidos excluded (no gallos)
      expect(rondas[2].tieneBye, isFalse);

      // R4: base
      expect(rondas[3].esRondaBase, isTrue);

      // Each PL gallo used max once
      final gallosUsados = <int>{};
      for (final ronda in rondas.where((r) => !r.esRondaBase)) {
        for (final e in ronda.enfrentamientos) {
          expect(
            gallosUsados.add(e.galloA.id),
            isTrue,
            reason: 'Gallo ${e.galloA.anillo} repetido',
          );
          expect(
            gallosUsados.add(e.galloB.id),
            isTrue,
            reason: 'Gallo ${e.galloB.anillo} repetido',
          );
        }
      }
    });

    test('5 partidos con 3 PL genera todas las rondas', () {
      // 5 partidos impares, 3 PL cada uno.
      // R1-R2 doble pelea. R3: partidos sin gallos excluidos → odd →
      // un partido no participa. R4: base.
      final partidos = List.generate(5, (i) => _partido(i + 1));
      final gallos = <Gallo>[];
      var gid = 1;
      for (final p in partidos) {
        for (var i = 0; i < 3; i++) {
          gallos.add(_gallo(gid++, p.id, 2000 + i * 20));
        }
        gallos.add(_gallo(gid++, p.id, 2100, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 500),
        compadres: [],
      );

      final rondas = <Ronda>[];
      for (var r = 1; r <= 4; r++) {
        rondas.add(
          engine.generarRonda(
            partidos: partidos,
            gallos: gallos,
            compadres: [],
            rondasPrevias: rondas,
            rondaNumero: r,
          ),
        );
      }

      expect(rondas.length, 4);
      expect(rondas[0].tieneDoble, isTrue);
      expect(rondas[1].tieneDoble, isTrue);
      expect(rondas[3].esRondaBase, isTrue);
      // No BYE in any round
      for (final r in rondas) {
        expect(r.tieneBye, isFalse);
      }
    });

    test('7 partidos con pesos reales del derby EL PASO genera 4 rondas', () {
      // Reproduce exactamente los datos del derby real.
      // R1-R2: doble pelea. R3: excluidos sin gallos → impar → un partido no
      // participa (sin comodín ni BYE). R4: base.
      final partidos = [
        _partido(12),
        _partido(13),
        _partido(14),
        _partido(15),
        _partido(16),
        _partido(17),
        _partido(18),
      ];
      final gallos = <Gallo>[
        // P12 EL ROSAL
        _gallo(1, 12, 1980), _gallo(2, 12, 2025), _gallo(3, 12, 2360),
        _gallo(4, 12, 2100, esBase: true),
        // P13 FAMILIA LOYOLA
        _gallo(5, 13, 2215), _gallo(6, 13, 2340), _gallo(7, 13, 2490),
        _gallo(8, 13, 2100, esBase: true),
        // P14 ISSA Y LOS CARNALES
        _gallo(9, 14, 2270), _gallo(10, 14, 2340), _gallo(11, 14, 2550),
        _gallo(12, 14, 2100, esBase: true),
        // P15 JR. DIAZ
        _gallo(13, 15, 2260), _gallo(14, 15, 2465), _gallo(15, 15, 2550),
        _gallo(16, 15, 2100, esBase: true),
        // P16 LA JOYA
        _gallo(17, 16, 2010), _gallo(18, 16, 2225), _gallo(19, 16, 2390),
        _gallo(20, 16, 2100, esBase: true),
        // P17 LA NVA ESPERANZA Y EL JAROCHO II
        _gallo(21, 17, 1925), _gallo(22, 17, 2350), _gallo(23, 17, 2450),
        _gallo(24, 17, 2100, esBase: true),
        // P18 MG FARM
        _gallo(25, 18, 2280), _gallo(26, 18, 2380), _gallo(27, 18, 2445),
        _gallo(28, 18, 2100, esBase: true),
      ];

      final engine = DerbyEngine(
        config: const DerbyConfig(
          rondasTotales: 4,
          diferenciaMaxPeso: 500,
          pesoMinimo: 1800,
          pesoMaximo: 2600,
          pesoGalloBase: 2100,
          permitirRepeticiones: true,
          validacionEstricta: false,
        ),
        compadres: [],
      );

      final rondas = <Ronda>[];
      for (var r = 1; r <= 4; r++) {
        rondas.add(
          engine.generarRonda(
            partidos: partidos,
            gallos: gallos,
            compadres: [],
            rondasPrevias: rondas,
            rondaNumero: r,
          ),
        );
      }

      expect(rondas.length, 4);

      // R1-R2: doble pelea, 7 partidos participan
      for (var i = 0; i < 2; i++) {
        expect(rondas[i].tieneDoble, isTrue);
        expect(rondas[i].tieneBye, isFalse);
        expect(rondas[i].enfrentamientos.length, 4);
        final participantes = <int>{};
        for (final e in rondas[i].enfrentamientos) {
          participantes.add(e.galloA.partidoId);
          participantes.add(e.galloB.partidoId);
        }
        expect(
          participantes.length,
          7,
          reason: 'Ronda ${i + 1}: 7 partidos participan',
        );
      }

      // No BYE in any round
      for (final r in rondas) {
        expect(r.tieneBye, isFalse);
      }

      // R4: base
      expect(rondas[3].esRondaBase, isTrue);
    });
  });

  // ============================================================
  // GLOBAL OPTIMIZER (MINIMAX)
  // ============================================================
  group('GlobalMatchingOptimizer', () {
    test('4 partidos par — minimax produce menor maxDiff que secuencial', () {
      // Simula los datos de "LOS DE ABAJO": 4 partidos, 4 rondas (3 PL + 1 base)
      final partidos = [
        _partido(1), // EL ROSAL
        _partido(2), // FAMILIA LOYOLA
        _partido(3), // ISSA Y LOS CARNALES
        _partido(4), // JR. DIAZ
      ];
      final gallos = <Gallo>[
        // P1: pesos variados
        _gallo(1, 1, 2220), _gallo(2, 1, 2025), _gallo(3, 1, 2360),
        _gallo(4, 1, 2100, esBase: true),
        // P2
        _gallo(5, 2, 2215), _gallo(6, 2, 2340), _gallo(7, 2, 2490),
        _gallo(8, 2, 2100, esBase: true),
        // P3
        _gallo(9, 3, 2270), _gallo(10, 3, 2340), _gallo(11, 3, 2550),
        _gallo(12, 3, 2100, esBase: true),
        // P4
        _gallo(13, 4, 2260), _gallo(14, 4, 2465), _gallo(15, 4, 2550),
        _gallo(16, 4, 2100, esBase: true),
      ];

      final config = const DerbyConfig(
        rondasTotales: 4,
        diferenciaMaxPeso: 500,
        pesoMinimo: 1800,
        pesoMaximo: 2600,
        pesoGalloBase: 2100,
        permitirRepeticiones: true,
        validacionEstricta: false,
      );
      final engine = DerbyEngine(config: config, compadres: []);
      final sorteo = GenerarSorteo(engine);

      final rondas = sorteo.ejecutarTodas(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
      );

      expect(rondas.length, 4);

      // Collect all PL fight diffs
      double maxDiff = 0;
      for (final r in rondas) {
        if (r.esRondaBase) continue;
        for (final e in r.enfrentamientos) {
          if (e.diferenciaPeso > maxDiff) maxDiff = e.diferenciaPeso;
        }
      }

      // The old sequential approach produced 315g max diff.
      // Global optimizer should do significantly better.
      print('  Global minimax maxDiff: ${maxDiff.toStringAsFixed(0)}g');
      expect(
        maxDiff,
        lessThan(200),
        reason:
            'Global minimax should reduce max diff significantly '
            '(old sequential was 315g)',
      );
    });

    test('4 partidos par — cada gallo PL pelea exactamente una vez', () {
      final partidos = [_partido(1), _partido(2), _partido(3), _partido(4)];
      final gallos = <Gallo>[
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2100),
        _gallo(3, 1, 2200),
        _gallo(4, 1, 2100, esBase: true),
        _gallo(5, 2, 2050),
        _gallo(6, 2, 2150),
        _gallo(7, 2, 2250),
        _gallo(8, 2, 2100, esBase: true),
        _gallo(9, 3, 2000),
        _gallo(10, 3, 2100),
        _gallo(11, 3, 2200),
        _gallo(12, 3, 2100, esBase: true),
        _gallo(13, 4, 2050),
        _gallo(14, 4, 2150),
        _gallo(15, 4, 2250),
        _gallo(16, 4, 2100, esBase: true),
      ];

      final engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 500),
        compadres: [],
      );
      final sorteo = GenerarSorteo(engine);

      final rondas = sorteo.ejecutarTodas(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
      );

      // Verify each PL gallo fights exactly once across PL rounds
      final plGallosSeen = <int>{};
      for (final r in rondas) {
        if (r.esRondaBase) continue;
        for (final e in r.enfrentamientos) {
          expect(
            plGallosSeen.contains(e.galloA.id),
            isFalse,
            reason: 'Gallo ${e.galloA.anillo} fights twice!',
          );
          expect(
            plGallosSeen.contains(e.galloB.id),
            isFalse,
            reason: 'Gallo ${e.galloB.anillo} fights twice!',
          );
          plGallosSeen.add(e.galloA.id);
          plGallosSeen.add(e.galloB.id);
        }
      }
      // All 12 PL gallos should have fought
      expect(plGallosSeen.length, 12);
    });

    test('7 partidos impar — primer bloque con doble pelea', () {
      final partidos = List.generate(7, (i) => _partido(i + 1));
      final gallos = <Gallo>[];
      var gId = 1;
      for (var p = 1; p <= 7; p++) {
        // 3 PL gallos with varied weights
        gallos.add(_gallo(gId++, p, 2000.0 + p * 30));
        gallos.add(_gallo(gId++, p, 2100.0 + p * 20));
        gallos.add(_gallo(gId++, p, 2200.0 + p * 10));
        gallos.add(_gallo(gId++, p, 2100, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(
          rondasTotales: 4,
          diferenciaMaxPeso: 500,
          permitirRepeticiones: true,
          validacionEstricta: false,
        ),
        compadres: [],
      );
      final sorteo = GenerarSorteo(engine);

      // Para impar, ejecutarPrimerBloque usa flujo secuencial (no global)
      final rondas = sorteo.ejecutarPrimerBloque(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
      );

      expect(rondas.length, 2);

      // All PL rounds should cover all 7 partidos via doble pelea (NO BYE)
      for (final r in rondas) {
        expect(r.tieneDoble, isTrue);
        expect(r.tieneBye, isFalse);
        final participantes = <int>{};
        for (final e in r.enfrentamientos) {
          participantes.add(e.galloA.partidoId);
          participantes.add(e.galloB.partidoId);
        }
        expect(
          participantes.length,
          7,
          reason: 'Ronda ${r.numero}: all 7 partidos should participate',
        );
      }
    });

    test(
      'global optimizer produces valid matchings (no same-partido fights)',
      () {
        final partidos = List.generate(6, (i) => _partido(i + 1));
        final gallos = <Gallo>[];
        var gId = 1;
        for (var p = 1; p <= 6; p++) {
          gallos.add(_gallo(gId++, p, 2000.0 + p * 50));
          gallos.add(_gallo(gId++, p, 2100.0 + p * 40));
          gallos.add(_gallo(gId++, p, 2200.0 + p * 30));
          gallos.add(_gallo(gId++, p, 2100, esBase: true));
        }

        final engine = DerbyEngine(
          config: const DerbyConfig(
            rondasTotales: 4,
            diferenciaMaxPeso: 500,
            permitirRepeticiones: true,
          ),
          compadres: [],
        );
        final sorteo = GenerarSorteo(engine);

        final rondas = sorteo.ejecutarTodas(
          partidos: partidos,
          gallos: gallos,
          compadres: [],
        );

        // Verify no same-partido fights in any round
        for (final r in rondas) {
          for (final e in r.enfrentamientos) {
            expect(
              e.galloA.partidoId,
              isNot(equals(e.galloB.partidoId)),
              reason:
                  'Ronda ${r.numero}: gallos del mismo partido se enfrentan',
            );
          }
        }
      },
    );

    test('compadres restriction is respected in global optimizer', () {
      final partidos = [_partido(1), _partido(2), _partido(3), _partido(4)];
      final gallos = <Gallo>[
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2100),
        _gallo(3, 1, 2200),
        _gallo(4, 1, 2100, esBase: true),
        _gallo(5, 2, 2005),
        _gallo(6, 2, 2105),
        _gallo(7, 2, 2205),
        _gallo(8, 2, 2100, esBase: true),
        _gallo(9, 3, 2010),
        _gallo(10, 3, 2110),
        _gallo(11, 3, 2210),
        _gallo(12, 3, 2100, esBase: true),
        _gallo(13, 4, 2015),
        _gallo(14, 4, 2115),
        _gallo(15, 4, 2215),
        _gallo(16, 4, 2100, esBase: true),
      ];

      // P1 and P2 are compadres — should NEVER face each other
      final compadresList = [
        const Compadres(id: 1, partidoIdA: 1, partidoIdB: 2),
      ];

      final engine = DerbyEngine(
        config: const DerbyConfig(
          rondasTotales: 4,
          diferenciaMaxPeso: 500,
          permitirRepeticiones: true,
        ),
        compadres: compadresList,
      );
      final sorteo = GenerarSorteo(engine);

      final rondas = sorteo.ejecutarTodas(
        partidos: partidos,
        gallos: gallos,
        compadres: compadresList,
      );

      for (final r in rondas) {
        for (final e in r.enfrentamientos) {
          final pids = {e.galloA.partidoId, e.galloB.partidoId};
          expect(
            pids.contains(1) && pids.contains(2),
            isFalse,
            reason: 'Ronda ${r.numero}: compadres P1 vs P2 se enfrentan!',
          );
        }
      }
    });

    test('minimax with 12 partidos — runs within time limit', () {
      final partidos = List.generate(12, (i) => _partido(i + 1));
      final gallos = <Gallo>[];
      var gId = 1;
      for (var p = 1; p <= 12; p++) {
        gallos.add(_gallo(gId++, p, 1900.0 + p * 40));
        gallos.add(_gallo(gId++, p, 2000.0 + p * 35));
        gallos.add(_gallo(gId++, p, 2100.0 + p * 25));
        gallos.add(_gallo(gId++, p, 2100, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(
          rondasTotales: 4,
          diferenciaMaxPeso: 500,
          permitirRepeticiones: true,
        ),
        compadres: [],
      );
      final sorteo = GenerarSorteo(engine);

      final sw = Stopwatch()..start();
      final rondas = sorteo.ejecutarTodas(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
      );
      sw.stop();

      expect(rondas.length, 4);
      expect(
        sw.elapsedMilliseconds,
        lessThan(10000),
        reason: 'Global optimizer should complete in <10s for 12 partidos',
      );

      double maxDiff = 0;
      for (final r in rondas) {
        if (r.esRondaBase) continue;
        for (final e in r.enfrentamientos) {
          if (e.diferenciaPeso > maxDiff) maxDiff = e.diferenciaPeso;
        }
      }
      print(
        '  12 partidos: maxDiff=${maxDiff.toStringAsFixed(0)}g, '
        'time=${sw.elapsedMilliseconds}ms',
      );
    });

    test('fallback to sequential if global fails', () {
      // This test verifies the fallback path works (2 partidos, edge case)
      final partidos = [_partido(1), _partido(2)];
      final gallos = <Gallo>[
        _gallo(1, 1, 2000),
        _gallo(2, 1, 2100),
        _gallo(3, 1, 2200),
        _gallo(4, 1, 2100, esBase: true),
        _gallo(5, 2, 2010),
        _gallo(6, 2, 2110),
        _gallo(7, 2, 2210),
        _gallo(8, 2, 2100, esBase: true),
      ];

      final engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 500),
        compadres: [],
      );
      final sorteo = GenerarSorteo(engine);

      final rondas = sorteo.ejecutarTodas(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
      );

      expect(rondas.length, 4);
      // All PL rounds should have 1 fight
      for (final r in rondas) {
        if (r.esRondaBase) continue;
        expect(r.enfrentamientos.length, 1);
      }
    });

    test(
      'ejecutarPrimerBloque generates only 2 PL rounds for 4-round derby',
      () {
        final partidos = List.generate(6, (i) => _partido(i + 1));
        final gallos = <Gallo>[];
        var gId = 1;
        for (var p = 1; p <= 6; p++) {
          gallos.add(_gallo(gId++, p, 2000.0 + p * 50));
          gallos.add(_gallo(gId++, p, 2050.0 + p * 30));
          gallos.add(_gallo(gId++, p, 2100.0 + p * 20));
          gallos.add(_gallo(gId++, p, 2100, esBase: true));
        }

        final engine = DerbyEngine(
          config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 500),
          compadres: [],
        );
        final sorteo = GenerarSorteo(engine);

        final rondas = sorteo.ejecutarPrimerBloque(
          partidos: partidos,
          gallos: gallos,
          compadres: [],
        );

        // Should generate exactly 2 PL rounds, not all 3
        expect(rondas.length, 2);
        expect(rondas[0].numero, 1);
        expect(rondas[1].numero, 2);
        expect(rondas.every((r) => !r.esRondaBase), isTrue);

        // Each round should have 3 fights (6 partidos / 2)
        for (final r in rondas) {
          expect(r.enfrentamientos.length, 3);
        }
      },
    );

    test('incremental flow: primer bloque + generar ronda 3 after results', () {
      final partidos = List.generate(6, (i) => _partido(i + 1));
      final gallos = <Gallo>[];
      var gId = 1;
      for (var p = 1; p <= 6; p++) {
        gallos.add(_gallo(gId++, p, 2000.0 + p * 50));
        gallos.add(_gallo(gId++, p, 2050.0 + p * 30));
        gallos.add(_gallo(gId++, p, 2100.0 + p * 20));
        gallos.add(_gallo(gId++, p, 2100, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 500),
        compadres: [],
      );
      final sorteo = GenerarSorteo(engine);

      // Step 1: Generate primer bloque (rounds 1-2)
      final primerBloque = sorteo.ejecutarPrimerBloque(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
      );
      expect(primerBloque.length, 2);

      // Step 2: Generate round 3 using sequential method with previous rounds
      final ronda3 = sorteo.ejecutar(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: primerBloque,
        rondaNumero: 3,
      );
      expect(ronda3.numero, 3);
      expect(ronda3.esRondaBase, isFalse);
      expect(ronda3.enfrentamientos.length, 3);

      // Step 3: Generate round 4 (base)
      final todasPL = [...primerBloque, ronda3];
      final ronda4 = sorteo.ejecutar(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
        rondasPrevias: todasPL,
        rondaNumero: 4,
      );
      expect(ronda4.numero, 4);
      expect(ronda4.esRondaBase, isTrue);
      expect(ronda4.enfrentamientos.length, 3);

      // Verify no PL gallo is reused across all PL rounds
      final gallosPLUsados = <int>{};
      for (final r in [...primerBloque, ronda3]) {
        for (final e in r.enfrentamientos) {
          expect(
            gallosPLUsados.contains(e.galloA.id),
            isFalse,
            reason: 'Gallo ${e.galloA.id} reused',
          );
          expect(
            gallosPLUsados.contains(e.galloB.id),
            isFalse,
            reason: 'Gallo ${e.galloB.id} reused',
          );
          gallosPLUsados.add(e.galloA.id);
          gallosPLUsados.add(e.galloB.id);
        }
      }
    });

    test('incremental flow with elimination changes party count', () {
      // 8 partidos, after primer bloque one gets eliminated → round 3
      // has 7 active (odd) → requires comodín.
      final partidos = List.generate(8, (i) => _partido(i + 1));
      // Add a comodín partido for round 3
      final partidosConComodin = [
        ...partidos,
        const Partido(id: 99, nombre: 'COMODIN', esComodin: true),
      ];
      final gallos = <Gallo>[];
      var gId = 1;
      for (final p in partidosConComodin) {
        // Use moderate weights for all (including comodín)
        final baseWeight = 2000.0 + (p.id <= 8 ? p.id * 40 : 5 * 40);
        gallos.add(_gallo(gId++, p.id, baseWeight));
        gallos.add(_gallo(gId++, p.id, baseWeight + 30));
        gallos.add(_gallo(gId++, p.id, baseWeight + 60));
        gallos.add(_gallo(gId++, p.id, 2100, esBase: true));
      }

      final engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 500),
        compadres: [],
      );
      final sorteo = GenerarSorteo(engine);

      // Step 1: Primer bloque (8 even → global optimizer)
      final primerBloque = sorteo.ejecutarPrimerBloque(
        partidos: partidosConComodin,
        gallos: gallos,
        compadres: [],
      );
      expect(primerBloque.length, 2);

      // Simulate: partido 1 lost everything and is "eliminated"
      final partidosPostElim = partidosConComodin.map((p) {
        if (p.id == 1) return p.copyWith(eliminado: true);
        return p;
      }).toList();

      // Step 2: Ronda 3 — engine should skip eliminated partido
      //   7 activos → impar → comodín enters (R3 >= 3)
      final ronda3 = engine.generarRonda(
        partidos: partidosPostElim,
        gallos: gallos,
        compadres: [],
        rondasPrevias: primerBloque,
        rondaNumero: 3,
      );
      expect(ronda3.numero, 3);
      final participantes = <int>{};
      for (final e in ronda3.enfrentamientos) {
        participantes.add(e.galloA.partidoId);
        participantes.add(e.galloB.partidoId);
      }
      // Eliminated partido should NOT be in enfrentamientos
      expect(
        participantes.contains(1),
        isFalse,
        reason: 'Eliminated partido 1 should not fight',
      );
      // Comodín should enter → 8 total (7 active + comodín)
      expect(
        participantes.contains(99),
        isTrue,
        reason: 'Comodín should enter for odd count',
      );
      expect(
        ronda3.enfrentamientos.length,
        4,
        reason: '8 partidos (7+comodín) → 4 fights',
      );
    });
  });
}
