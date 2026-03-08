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

  /// Valida la composición de gallos de un partido.
  ///
  /// Reglas mínimas:
  /// - Al menos 1 gallo P.L. (libre) para participar en sorteo.
  ///
  /// El gallo base es opcional (solo se registra, no participa en sorteo).
  List<String> validarPartido(Partido partido, List<Gallo> gallos) {
    final errores = <String>[];

    final gallosDelPartido = gallos
        .where((g) => g.partidoId == partido.id)
        .toList();

    final libres = gallosDelPartido.where((g) => !g.esBase).toList();
    if (libres.isEmpty) {
      errores.add(
        'Partido ${partido.nombre} no tiene gallos libres '
        '(necesita al menos 1 para participar en el sorteo).',
      );
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
        errores.add('Gallo ${e.galloA.anillo} (id=${e.galloA.id}) ya peleó.');
      }
      if (gallosYaPeleados.contains(e.galloB.id)) {
        errores.add('Gallo ${e.galloB.anillo} (id=${e.galloB.id}) ya peleó.');
      }
    }
    return errores;
  }

  /// Valida que los gallos base solo aparezcan en la ronda base y viceversa.
  ///
  /// - [esRondaBase]: true si esta ronda es la ronda base.
  /// - [rondaNumero]: número de la ronda (para mensajes de error).
  List<String> validarGallosBase(
    List<Enfrentamiento> enfrentamientos, {
    required bool esRondaBase,
    required int rondaNumero,
  }) {
    final errores = <String>[];
    for (final e in enfrentamientos) {
      for (final g in [e.galloA, e.galloB]) {
        if (!esRondaBase && g.esBase) {
          errores.add(
            'Gallo base ${g.anillo}: solo en la ronda base se permiten '
            'gallos base (ronda $rondaNumero).',
          );
        }
        if (esRondaBase && !g.esBase) {
          errores.add(
            'Gallo ${g.anillo} NO es base pero está en la ronda base '
            '(ronda $rondaNumero).',
          );
        }
      }
    }
    return errores;
  }

  /// Validación completa de una ronda nueva.
  ///
  /// [partidosDobles]: IDs de partidos que pelean doble en esta ronda.
  /// Se valida que máximo 1 partido pelee doble.
  List<String> validarCompleto({
    required List<Enfrentamiento> enfrentamientos,
    required int rondaNumero,
    required Set<int> gallosYaPeleados,
    List<int> partidosDobles = const [],
  }) {
    final errores = [
      ...validarRonda(enfrentamientos),
      ...validarGallosNoPeleados(enfrentamientos, gallosYaPeleados),
    ];

    // Validar: máximo 1 partido pelea doble por ronda
    if (partidosDobles.length > 1) {
      errores.add(
        'Ronda $rondaNumero tiene ${partidosDobles.length} partidos dobles. '
        'Máximo permitido: 1.',
      );
    }

    // Validar: si hay doble, verificar que ese partido aparece exactamente
    // en 2 enfrentamientos (con 2 gallos distintos)
    for (final dobleId in partidosDobles) {
      final apariciones = enfrentamientos
          .where(
            (e) =>
                e.galloA.partidoId == dobleId || e.galloB.partidoId == dobleId,
          )
          .length;
      if (apariciones != 2) {
        errores.add(
          'Partido doble $dobleId aparece en $apariciones enfrentamientos '
          '(debe ser exactamente 2).',
        );
      }

      // Verificar que usa 2 gallos distintos
      final gallosDelDoble = <int>{};
      for (final e in enfrentamientos) {
        if (e.galloA.partidoId == dobleId) gallosDelDoble.add(e.galloA.id);
        if (e.galloB.partidoId == dobleId) gallosDelDoble.add(e.galloB.id);
      }
      if (gallosDelDoble.length != 2) {
        errores.add(
          'Partido doble $dobleId usa ${gallosDelDoble.length} gallos '
          '(debe usar exactamente 2 distintos).',
        );
      }
    }

    return errores;
  }
}
