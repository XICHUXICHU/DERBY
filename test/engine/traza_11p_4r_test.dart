/// Test exhaustivo: 11 partidos, 4 rondas (todas PL — no hay ronda base).
/// Traza completa para verificar que el engine genera las 4 rondas.
import 'package:test/test.dart';
import 'package:derby2_flutter/domain/domain.dart';
import 'package:derby2_flutter/engine/engine.dart';
import 'package:derby2_flutter/application/usecases/generar_sorteo.dart';

void main() {
  Gallo gallo(int id, int partidoId, double peso, {bool esBase = false}) {
    return Gallo(
      id: id,
      partidoId: partidoId,
      anillo: 'A-$id',
      pesoGramos: peso,
      esBase: esBase,
    );
  }

  Partido partido0(int id, {int puntos = 0}) {
    return Partido(id: id, nombre: 'Partido $id', puntos: puntos);
  }

  group('11 partidos × 4 rondas completas (caso real)', () {
    late List<Partido> partidos;
    late List<Gallo> gallos;
    late DerbyEngine engine;
    late List<Ronda> rondas;

    setUp(() {
      partidos = List.generate(11, (i) => partido0(i + 1));
      gallos = <Gallo>[];
      var gid = 1;
      for (final p in partidos) {
        // 4 gallos PL (sin base — base solo es para registro)
        for (var i = 0; i < 4; i++) {
          gallos.add(gallo(gid++, p.id, 2000 + i * 10));
        }
      }
      engine = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 4, diferenciaMaxPeso: 0),
        compadres: [],
      );
    });

    test('ejecutarTodas genera exactamente 4 rondas', () {
      final sorteo = GenerarSorteo(engine);
      rondas = sorteo.ejecutarTodas(
        partidos: partidos,
        gallos: gallos,
        compadres: [],
      );
      expect(rondas.length, 4, reason: 'Debe generar 4 rondas completas');
    });

    test('generarRonda secuencial produce 4 rondas', () {
      final rondasGen = <Ronda>[];
      for (var i = 1; i <= 4; i++) {
        final ronda = engine.generarRonda(
          partidos: partidos,
          gallos: gallos,
          compadres: [],
          rondasPrevias: rondasGen,
          rondaNumero: i,
        );
        rondasGen.add(ronda);
      }
      rondas = rondasGen;

      expect(rondas.length, 4);

      // ── R1: PL, impar → doble pelea P11, 6 peleas ──
      expect(rondas[0].numero, 1);
      expect(rondas[0].esRondaBase, isFalse);
      expect(rondas[0].enfrentamientos.length, 6);
      expect(rondas[0].tieneDoble, isTrue);
      expect(rondas[0].partidosDobles, [
        11,
      ], reason: 'R1: último partido (P11) pelea doble');

      // ── R2: PL, impar → doble pelea (P11 aún tiene ≥2 PL con 4 gallos) ──
      expect(rondas[1].numero, 2);
      expect(rondas[1].esRondaBase, isFalse);
      expect(rondas[1].enfrentamientos.length, 6);
      expect(rondas[1].tieneDoble, isTrue);
      expect(rondas[1].partidosDobles.length, 1);
      // P11 usó 2 PL en R1, le quedan 2 → todavía puede doblar
      expect(
        rondas[1].partidosDobles.first,
        11,
        reason: 'P11 con 4 PL total: R1 usó 2, quedan 2 → puede doblar en R2',
      );

      // ── R3: PL, partidos con gallos disponibles, impar posible ──
      expect(rondas[2].numero, 3);
      expect(rondas[2].esRondaBase, isFalse);
      expect(rondas[2].enfrentamientos.length, greaterThanOrEqualTo(4));

      // ── R4: PL, gallos restantes (ya no hay ronda base) ──
      expect(rondas[3].numero, 4);
      expect(rondas[3].esRondaBase, isFalse);
      expect(rondas[3].enfrentamientos.length, greaterThanOrEqualTo(1));

      // ── Verificar integridad global ──
      // Ningún gallo pelea más de 1 vez en todo el derby
      final gallosUsados = <int>{};
      for (final r in rondas) {
        for (final e in r.enfrentamientos) {
          expect(
            gallosUsados.add(e.galloA.id),
            isTrue,
            reason: 'Gallo ${e.galloA.anillo} ya peleó antes de R${r.numero}',
          );
          expect(
            gallosUsados.add(e.galloB.id),
            isTrue,
            reason: 'Gallo ${e.galloB.anillo} ya peleó antes de R${r.numero}',
          );
        }
      }

      // Máximo 1 partido pelea doble en cada ronda
      for (final r in rondas) {
        expect(
          r.partidosDobles.length,
          lessThanOrEqualTo(1),
          reason: 'R${r.numero}: máx 1 doble',
        );
      }

      // Ningún partido pelea >2 veces en una sola ronda
      for (final r in rondas) {
        final apariciones = <int, int>{};
        for (final e in r.enfrentamientos) {
          apariciones[e.galloA.partidoId] =
              (apariciones[e.galloA.partidoId] ?? 0) + 1;
          apariciones[e.galloB.partidoId] =
              (apariciones[e.galloB.partidoId] ?? 0) + 1;
        }
        for (final entry in apariciones.entries) {
          expect(
            entry.value,
            lessThanOrEqualTo(2),
            reason: 'R${r.numero}: P${entry.key} pelea ${entry.value} veces',
          );
        }
      }

      // Contar peleas por partido (resumen)
      final totalPeleas = <int, int>{};
      for (final r in rondas) {
        for (final e in r.enfrentamientos) {
          totalPeleas[e.galloA.partidoId] =
              (totalPeleas[e.galloA.partidoId] ?? 0) + 1;
          totalPeleas[e.galloB.partidoId] =
              (totalPeleas[e.galloB.partidoId] ?? 0) + 1;
        }
      }

      // Todos los partidos pelean al menos 3 veces en 4 rondas
      for (var pid = 1; pid <= 11; pid++) {
        expect(
          totalPeleas[pid] ?? 0,
          greaterThanOrEqualTo(3),
          reason: 'P$pid debe pelear al menos 3 veces',
        );
      }
    });

    test('las rondas PL minimizan repetición de contrincantes', () {
      final rondasGen = <Ronda>[];
      for (var i = 1; i <= 4; i++) {
        rondasGen.add(
          engine.generarRonda(
            partidos: partidos,
            gallos: gallos,
            compadres: [],
            rondasPrevias: rondasGen,
            rondaNumero: i,
          ),
        );
      }

      // Recopilar todos los enfrentamientos partido↔partido
      final enfrentamientos = <(int, int), int>{};
      for (final r in rondasGen) {
        for (final e in r.enfrentamientos) {
          final a = e.galloA.partidoId < e.galloB.partidoId
              ? e.galloA.partidoId
              : e.galloB.partidoId;
          final b = e.galloA.partidoId < e.galloB.partidoId
              ? e.galloB.partidoId
              : e.galloA.partidoId;
          enfrentamientos[(a, b)] = (enfrentamientos[(a, b)] ?? 0) + 1;
        }
      }

      // Contar cuántos enfrentamientos se repiten
      final repetidos = enfrentamientos.entries
          .where((e) => e.value > 1)
          .toList();

      print('\n═══ Enfrentamientos repetidos ═══');
      for (final r in repetidos) {
        print('  P${r.key.$1} vs P${r.key.$2}: ${r.value} veces');
      }
      print(
        '  Total repetidos: ${repetidos.length} de ${enfrentamientos.length}',
      );

      // Con 11 partidos y 4 rondas es casi inevitable alguna repetición,
      // pero debe ser mínima (idealmente ≤2 repeticiones)
      expect(
        repetidos.length,
        lessThanOrEqualTo(3),
        reason: 'Demasiadas repeticiones de contrincantes',
      );
    });

    test('7 partidos × 3 rondas (3 PL)', () {
      final p7 = List.generate(7, (i) => partido0(i + 1));
      final g7 = <Gallo>[];
      var gid = 1;
      for (final p in p7) {
        // 3 PL (sin base)
        for (var i = 0; i < 3; i++) {
          g7.add(gallo(gid++, p.id, 2000 + i * 10));
        }
      }

      final eng = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 3, diferenciaMaxPeso: 0),
        compadres: [],
      );

      final rondasGen = <Ronda>[];
      for (var i = 1; i <= 3; i++) {
        rondasGen.add(
          eng.generarRonda(
            partidos: p7,
            gallos: g7,
            compadres: [],
            rondasPrevias: rondasGen,
            rondaNumero: i,
          ),
        );
      }

      expect(rondasGen.length, 3);
      // R1: 7 impar → 4 peleas (P7 doble)
      expect(rondasGen[0].enfrentamientos.length, 4);
      expect(rondasGen[0].tieneDoble, isTrue);
      expect(rondasGen[0].partidosDobles, [7]);
      // R2: PL → variable
      expect(rondasGen[1].esRondaBase, isFalse);
      // R3: PL, gallos restantes
      expect(rondasGen[2].esRondaBase, isFalse);
      expect(rondasGen[2].enfrentamientos.length, greaterThanOrEqualTo(1));
    });

    test('5 partidos × 5 rondas (5 PL)', () {
      final p5 = List.generate(5, (i) => partido0(i + 1));
      final g5 = <Gallo>[];
      var gid = 1;
      for (final p in p5) {
        // 5 PL (sin base)
        for (var i = 0; i < 5; i++) {
          g5.add(gallo(gid++, p.id, 2000 + i * 10));
        }
      }

      final eng = DerbyEngine(
        config: const DerbyConfig(rondasTotales: 5, diferenciaMaxPeso: 0),
        compadres: [],
      );

      final rondasGen = <Ronda>[];
      for (var i = 1; i <= 5; i++) {
        rondasGen.add(
          eng.generarRonda(
            partidos: p5,
            gallos: g5,
            compadres: [],
            rondasPrevias: rondasGen,
            rondaNumero: i,
          ),
        );
      }

      expect(rondasGen.length, 5);
      // R1-R2: doble pelea
      expect(rondasGen[0].tieneDoble, isTrue);
      expect(rondasGen[0].partidosDobles, [
        5,
      ], reason: 'Último partido pelea doble');
      // R5: PL, gallos restantes (ya no es ronda base)
      expect(rondasGen[4].esRondaBase, isFalse);
    });
  });
}
