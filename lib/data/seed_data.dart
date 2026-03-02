import '../main.dart' show partidoRepository, galloRepository;

/// Datos de prueba precargados para un derby.
///
/// Contiene 8 partidos con 4 gallos cada uno (1 base + 3 P.L.).
/// Los datos replican la tabla de ejemplo estándar.
class SeedData {
  SeedData._();

  /// Siembra los 8 partidos con sus gallos en el derby [derbyId].
  ///
  /// Retorna la cantidad de partidos creados.
  static Future<int> sembrar(int derbyId) async {
    // Prefijo para garantizar anillos únicos entre derbies
    final prefix = 'D${derbyId}_';

    for (final p in _partidos) {
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

    return _partidos.length;
  }

  // ── Datos de prueba ──────────────────────────────────────

  static final List<_PartidoSeed> _partidos = [
    _PartidoSeed(
      nombre: 'EL ROSAL',
      galloBase: _GalloSeed('001', 2100),
      gallosPL: [
        _GalloSeed('005', 1980),
        _GalloSeed('010', 2025),
        _GalloSeed('006', 2360),
      ],
    ),
    _PartidoSeed(
      nombre: 'FAMILIA LOYOLA',
      galloBase: _GalloSeed('032', 2100),
      gallosPL: [
        _GalloSeed('040', 2215),
        _GalloSeed('031', 2340),
        _GalloSeed('041', 2490),
      ],
    ),
    _PartidoSeed(
      nombre: 'ISSA Y LOS CARNALES',
      galloBase: _GalloSeed('066', 2100),
      gallosPL: [
        _GalloSeed('067', 2270),
        _GalloSeed('068', 2340),
        _GalloSeed('069', 2550),
      ],
    ),
    _PartidoSeed(
      nombre: 'JR. DIAZ',
      galloBase: _GalloSeed('012', 2100),
      gallosPL: [
        _GalloSeed('003', 2260),
        _GalloSeed('004', 2465),
        _GalloSeed('002', 2550),
      ],
    ),
    _PartidoSeed(
      nombre: 'LA JOYA',
      galloBase: _GalloSeed('086', 2100),
      gallosPL: [
        _GalloSeed('075', 2010),
        _GalloSeed('078', 2225),
        _GalloSeed('084', 2390),
      ],
    ),
    _PartidoSeed(
      nombre: 'LA NVA ESPERANZA Y EL JAROCHO II',
      galloBase: _GalloSeed('055', 2100),
      gallosPL: [
        _GalloSeed('052', 1925),
        _GalloSeed('051', 2350),
        _GalloSeed('053', 2450),
      ],
    ),
    _PartidoSeed(
      nombre: 'MG FARM',
      galloBase: _GalloSeed('009', 2100),
      gallosPL: [
        _GalloSeed('008', 2280),
        _GalloSeed('015', 2380),
        _GalloSeed('016', 2445),
      ],
    ),
    _PartidoSeed(
      nombre: 'RANCHO NUEVO',
      galloBase: _GalloSeed('023', 2100),
      gallosPL: [
        _GalloSeed('007', 2040),
        _GalloSeed('030', 2045),
        _GalloSeed('011', 2205),
      ],
    ),
  ];
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
