import '../../domain/domain.dart';

/// Validador de restricciones del derby.
/// Puro, sin dependencias de Flutter/Drift.
class ConstraintValidator {
  final Set<(int, int)> _compadresSet;

  ConstraintValidator({required List<Compadres> compadres})
      : _compadresSet = _normalize(compadres);

  static Set<(int, int)> _normalize(List<Compadres> compadres) {
    final set = <(int, int)>{};
    for (final c in compadres) {
      final a = c.partidoIdA < c.partidoIdB ? c.partidoIdA : c.partidoIdB;
      final b = c.partidoIdA < c.partidoIdB ? c.partidoIdB : c.partidoIdA;
      set.add((a, b));
    }
    return set;
  }

  /// Valida una lista completa de enfrentamientos para una ronda.
  /// Retorna lista de errores. Lista vacía = válido.
  List<String> validarRonda(List<Enfrentamiento> enfrentamientos) {
    final errores = <String>[];
    final gallosUsados = <int>{};

    for (final e in enfrentamientos) {
      // 1) Gallos del mismo partido
      if (e.galloA.partidoId == e.galloB.partidoId) {
        errores.add(
          'Enfrentamiento ${e.id}: gallos ${e.galloA.anillo} y '
          '${e.galloB.anillo} son del MISMO partido (${e.galloA.partidoId}).',
        );
      }

      // 2) Compadres
      final pA = e.galloA.partidoId;
      final pB = e.galloB.partidoId;
      final a = pA < pB ? pA : pB;
      final b = pA < pB ? pB : pA;
      if (_compadresSet.contains((a, b))) {
        errores.add(
          'Enfrentamiento ${e.id}: partidos $pA y $pB son COMPADRES.',
        );
      }

      // 3) Gallo ya usado en esta ronda
      if (gallosUsados.contains(e.galloA.id)) {
        errores.add(
          'Gallo ${e.galloA.anillo} (id=${e.galloA.id}) '
          'aparece MÁS DE UNA VEZ en la ronda.',
        );
      }
      if (gallosUsados.contains(e.galloB.id)) {
        errores.add(
          'Gallo ${e.galloB.anillo} (id=${e.galloB.id}) '
          'aparece MÁS DE UNA VEZ en la ronda.',
        );
      }
      gallosUsados.add(e.galloA.id);
      gallosUsados.add(e.galloB.id);
    }

    return errores;
  }

  /// Valida que un partido tenga exactamente 4 gallos: 3 libres + 1 base.
  List<String> validarPartido(Partido partido, List<Gallo> gallos) {
    final errores = <String>[];

    final gallosDelPartido =
        gallos.where((g) => g.partidoId == partido.id).toList();

    if (gallosDelPartido.length != 4) {
      errores.add(
        'Partido ${partido.nombre} tiene ${gallosDelPartido.length} gallos '
        '(necesita exactamente 4).',
      );
    }

    final bases = gallosDelPartido.where((g) => g.esBase).toList();
    if (bases.length != 1) {
      errores.add(
        'Partido ${partido.nombre} tiene ${bases.length} gallos base '
        '(necesita exactamente 1).',
      );
    }

    final libres = gallosDelPartido.where((g) => !g.esBase).toList();
    if (libres.length != 3) {
      errores.add(
        'Partido ${partido.nombre} tiene ${libres.length} gallos libres '
        '(necesita exactamente 3).',
      );
    }

    return errores;
  }

  /// Valida que gallos base solo peleen en la ronda base (última ronda)
  /// y que rondas regulares solo usen gallos libres.
  ///
  /// [esRondaBase]: true si esta ronda es la última (gallos base).
  /// [rondaNumero]: solo para mensajes de error descriptivos.
  List<String> validarGallosBase(
    List<Enfrentamiento> enfrentamientos, {
    required bool esRondaBase,
    required int rondaNumero,
  }) {
    final errores = <String>[];

    for (final e in enfrentamientos) {
      if (!esRondaBase) {
        // Rondas regulares: NO deben pelear gallos base
        if (e.galloA.esBase) {
          errores.add(
            'Gallo base ${e.galloA.anillo} no puede pelear en ronda $rondaNumero '
            '(solo en la ronda base).',
          );
        }
        if (e.galloB.esBase) {
          errores.add(
            'Gallo base ${e.galloB.anillo} no puede pelear en ronda $rondaNumero '
            '(solo en la ronda base).',
          );
        }
      } else {
        // Ronda base: DEBEN pelear gallos base
        if (!e.galloA.esBase) {
          errores.add(
            'Ronda base ($rondaNumero) debe usar gallos base. '
            '${e.galloA.anillo} NO es base.',
          );
        }
        if (!e.galloB.esBase) {
          errores.add(
            'Ronda base ($rondaNumero) debe usar gallos base. '
            '${e.galloB.anillo} NO es base.',
          );
        }
      }
    }

    return errores;
  }

  /// Valida que un gallo no haya peleado ya.
  List<String> validarGallosNoPeleados(
    List<Enfrentamiento> nuevos,
    Set<int> gallosYaPeleados,
  ) {
    final errores = <String>[];
    for (final e in nuevos) {
      if (gallosYaPeleados.contains(e.galloA.id)) {
        errores.add(
          'Gallo ${e.galloA.anillo} (id=${e.galloA.id}) ya peleó.',
        );
      }
      if (gallosYaPeleados.contains(e.galloB.id)) {
        errores.add(
          'Gallo ${e.galloB.anillo} (id=${e.galloB.id}) ya peleó.',
        );
      }
    }
    return errores;
  }

  /// Validación completa de una ronda nueva.
  List<String> validarCompleto({
    required List<Enfrentamiento> enfrentamientos,
    required int rondaNumero,
    required bool esRondaBase,
    required Set<int> gallosYaPeleados,
  }) {
    return [
      ...validarRonda(enfrentamientos),
      ...validarGallosBase(enfrentamientos,
          esRondaBase: esRondaBase, rondaNumero: rondaNumero),
      ...validarGallosNoPeleados(enfrentamientos, gallosYaPeleados),
    ];
  }
}
