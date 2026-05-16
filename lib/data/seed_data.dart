import 'dart:math' as math;
import '../main.dart' show partidoRepository, galloRepository;

/// Datos de prueba precargados para un derby.
///
/// Contiene 30 partidos con 4 gallos cada uno (1 base 2,200 + 3 P.L. 2,000-2,500).
/// Los datos replican la tabla de un derby masivo real.
class SeedData {
  SeedData._();

  /// Siembra los partidos con sus gallos en el derby [derbyId].
  ///
  /// Retorna la cantidad de partidos creados.
  static Future<int> sembrar(int derbyId) async {
    // Prefijo para garantizar anillos únicos entre derbies
    final prefix = 'D${derbyId}_';
    final partidos = _generarPartidos();

    for (final p in partidos) {
      final partidoId = await partidoRepository.crear(
        derbyId: derbyId,
        nombre: p.nombre,
        depositoPagado: true,
      );

      // Gallo base
      await galloRepository.crear(
        partidoId: partidoId,
        anillo: '$prefix${p.galloBase.anillo}',
        pesoGramos: p.galloBase.peso,
        esBase: true,
      );

      // Gallos peso libre (P.L.)
      for (final g in p.gallosPL) {
        await galloRepository.crear(
          partidoId: partidoId,
          anillo: '$prefix${g.anillo}',
          pesoGramos: g.peso,
          esBase: false,
        );
      }
    }

    return partidos.length;
  }

  // ── Generador de datos (30 partidos) ─────────────────────────

  static List<_PartidoSeed> _generarPartidos() {
    final rn = math.Random(12345); // Seed fijo para mismas pruebas
    final nombres = [
      'EL ROSAL', 'FAMILIA LOYOLA', 'ISSA Y LOS CARNALES', 'JR. DIAZ', 'LA JOYA', 
      'LA NVA ESPERANZA Y EL JAROCHO II', 'MG FARM', 'RANCHO NUEVO', 'EL IMPOSIBLE', 
      'LOS COMPADRES', 'CRIADERO EL ENCANTO', 'GALLOS DE ORO', 'EL DURAZNO', 
      'ATARJEA GTO', 'LOS 3 POTRILLOS', 'HACIENDA VIEJA', 'LA HERRADURA', 
      'PALENQUE SUR', 'LOS CHINGONES', 'GALLEROS UNIDOS', 'EL PALOMINO', 
      'TRES HERMANOS', 'LA REVANCHA', 'LOS PRIMOS', 'GALLOS FINOS MX', 
      'RANCHO EL PATRON', 'EL GALLO NEGRO', 'LOS INTOCABLES', 'EL RELAMPAGO', 
      'LA TEMPESTAD'
    ];

    List<_PartidoSeed> partidos = [];
    int anilloCount = 100;

    for (var nombre in nombres) {
      // Gallo base obligatorio: 2200 g
      final base = _GalloSeed('A${anilloCount++}', 2200);
      
      // 3 gallos libres entre 2.0 y 2.5 kg (2000g a 2500g)
      List<_GalloSeed> libres = [];
      for (int i = 0; i < 3; i++) {
        // Generar peso entre 2000 y 2500 en saltos de 5g
        double p = 2000.0 + (rn.nextInt(101) * 5);
        libres.add(_GalloSeed('A${anilloCount++}', p));
      }

      partidos.add(_PartidoSeed(
        nombre: nombre,
        galloBase: base,
        gallosPL: libres,
      ));
    }
    return partidos;
  }
}

// ── Modelos auxiliares para seed ──

class _PartidoSeed {
  final String nombre;
  final _GalloSeed galloBase;
  final List<_GalloSeed> gallosPL;

  const _PartidoSeed({
    required this.nombre,
    required this.galloBase,
    required this.gallosPL,
  });
}

class _GalloSeed {
  final String anillo;
  final double peso;

  const _GalloSeed(this.anillo, this.peso);
}
