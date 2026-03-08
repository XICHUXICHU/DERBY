import 'package:flutter/material.dart';
import '../../domain/entities/gallo.dart';
import '../../domain/entities/partido.dart';

/// Resultado de la decisión del juez para un derby impar.
class ImparDecision {
  /// Estrategia elegida para manejar el partido sobrante.
  final EstrategiaImpar estrategia;

  /// ID del partido que peleará doble (solo si estrategia == doblePelea).
  final int? partidoDoblePeleaId;

  /// ID del gallo base a promover a PL (solo si promoverGallo == true).
  final int? galloBasePromovidoId;

  /// true si el juez decidió promover un gallo base a PL.
  final bool promoverGallo;

  const ImparDecision({
    required this.estrategia,
    this.partidoDoblePeleaId,
    this.galloBasePromovidoId,
    this.promoverGallo = false,
  });
}

enum EstrategiaImpar {
  /// Un partido pelea doble (2 gallos vs 2 rivales distintos) cada ronda.
  doblePelea,

  /// El engine decide automáticamente (comportamiento actual).
  automatico,
}

/// Diálogo que permite al juez configurar cómo manejar un derby impar.
///
/// Muestra:
/// 1. Explicación de la situación (número impar de partidos)
/// 2. Selección de partido que peleará doble
/// 3. Opción de promover un gallo base a PL
class DialogImparConfig extends StatefulWidget {
  /// Partidos activos del derby.
  final List<Partido> partidos;

  /// Gallos de todos los partidos.
  final List<Gallo> gallos;

  /// Nombre del derby (para el título).
  final String nombreDerby;

  /// Número de rondas PL calculadas.
  final int rondasPL;

  const DialogImparConfig({
    super.key,
    required this.partidos,
    required this.gallos,
    required this.nombreDerby,
    required this.rondasPL,
  });

  @override
  State<DialogImparConfig> createState() => _DialogImparConfigState();
}

class _DialogImparConfigState extends State<DialogImparConfig> {
  EstrategiaImpar _estrategia = EstrategiaImpar.doblePelea;
  int? _partidoDobleId;
  int? _galloBaseId;
  bool _promoverGallo = false;

  late final List<Partido> _partidosActivos;
  late final Map<int, List<Gallo>> _gallosPLPorPartido;
  late final Map<int, Gallo?> _galloBasePorPartido;
  late final int _totalGallosPL;
  late final bool _totalEsImpar;

  /// Partidos elegibles para doble pelea (>=2 gallos PL disponibles, o >=1 si
  /// promoveremos su base).
  List<Partido> get _candidatosDoble {
    return _partidosActivos.where((p) {
      final plCount = _gallosPLPorPartido[p.id]?.length ?? 0;
      // Necesita al menos 2 gallos PL para la ronda donde haga doble.
      // Con N rondas, necesita N+1 gallos PL totales.
      return plCount >= 2;
    }).toList();
  }

  /// Gallos base que podrían promoverse a PL.
  List<_GalloBaseInfo> get _candidatosPromocion {
    final result = <_GalloBaseInfo>[];
    for (final p in _partidosActivos) {
      final base = _galloBasePorPartido[p.id];
      if (base == null) continue;

      final plPesos = (_gallosPLPorPartido[p.id] ?? [])
          .map((g) => g.pesoGramos)
          .toList();
      if (plPesos.isEmpty) continue;

      // Distancia mínima al PL más cercano
      double minDist = double.infinity;
      for (final peso in plPesos) {
        final d = (base.pesoGramos - peso).abs();
        if (d < minDist) minDist = d;
      }

      result.add(_GalloBaseInfo(
        gallo: base,
        partido: p,
        distanciaMinPL: minDist,
        totalPLPartido: plPesos.length,
      ));
    }

    // Ordenar por mejor fit (menor distancia al PL más cercano)
    result.sort((a, b) => a.distanciaMinPL.compareTo(b.distanciaMinPL));
    return result;
  }

  @override
  void initState() {
    super.initState();

    _partidosActivos = widget.partidos
        .where(
          (p) =>
              p.estado == EstadoPartido.activo && !p.eliminado && !p.esComodin,
        )
        .toList();

    _gallosPLPorPartido = {};
    _galloBasePorPartido = {};
    for (final p in _partidosActivos) {
      _gallosPLPorPartido[p.id] =
          widget.gallos.where((g) => g.partidoId == p.id && !g.esBase).toList();
      _galloBasePorPartido[p.id] =
          widget.gallos.where((g) => g.partidoId == p.id && g.esBase).firstOrNull;
    }

    _totalGallosPL = _gallosPLPorPartido.values.fold(0, (s, l) => s + l.length);
    _totalEsImpar = _totalGallosPL.isOdd;

    // Pre-seleccionar: último partido (mayor ID) como doble
    if (_candidatosDoble.isNotEmpty) {
      _partidoDobleId =
          _candidatosDoble.map((p) => p.id).reduce((a, b) => a > b ? a : b);
    }

    // Pre-seleccionar el mejor gallo base para promoción (si PL es impar)
    if (_totalEsImpar && _candidatosPromocion.isNotEmpty) {
      _promoverGallo = true;
      _galloBaseId = _candidatosPromocion.first.gallo.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final txtTheme = Theme.of(context).textTheme;

    return AlertDialog(
      icon: Icon(Icons.gavel, color: cs.primary, size: 36),
      title: const Text('Configuración Derby Impar'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info box ──
              _infoBox(cs, txtTheme),
              const SizedBox(height: 20),

              // ── Sección 1: Estrategia ──
              Text(
                '1. ¿Cómo manejar el partido sobrante?',
                style: txtTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildEstrategiaOption(
                EstrategiaImpar.doblePelea,
                Icons.repeat_one,
                'Doble pelea',
                'Un partido pelea 2 veces por ronda con gallos distintos '
                    'contra 2 rivales diferentes.',
                cs,
              ),
              const SizedBox(height: 6),
              _buildEstrategiaOption(
                EstrategiaImpar.automatico,
                Icons.auto_awesome,
                'Automático',
                'El sistema decide qué partido pelea doble en cada ronda.',
                cs,
              ),

              // ── Sección 2: Seleccionar partido doble ──
              if (_estrategia == EstrategiaImpar.doblePelea) ...[
                const SizedBox(height: 20),
                Text(
                  '2. ¿Qué partido pelea doble?',
                  style: txtTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este partido usará 2 gallos por ronda. Necesita tener '
                  'suficientes gallos PL disponibles.',
                  style: txtTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPartidoDobleSelector(cs, txtTheme),
              ],

              // ── Sección 3: Promoción de gallo base ──
              if (_totalEsImpar) ...[
                const SizedBox(height: 20),
                Divider(color: cs.outlineVariant),
                const SizedBox(height: 12),
                Text(
                  '${_estrategia == EstrategiaImpar.doblePelea ? "3" : "2"}. '
                  'Promoción de gallo base',
                  style: txtTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 18,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El total de gallos PL es impar ($_totalGallosPL). '
                          'Se necesita promover un gallo base a PL para que '
                          'todos los gallos tengan pelea.',
                          style: txtTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _promoverGallo,
                  onChanged: (v) => setState(() {
                    _promoverGallo = v;
                    if (v && _galloBaseId == null && _candidatosPromocion.isNotEmpty) {
                      _galloBaseId = _candidatosPromocion.first.gallo.id;
                    }
                  }),
                  title: const Text('Promover gallo base a PL'),
                  subtitle: Text(
                    _promoverGallo
                        ? 'Un gallo base participará como PL'
                        : 'Un gallo quedará sin pelear',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_promoverGallo) _buildPromocionSelector(cs, txtTheme),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirmar y Sortear'),
          onPressed: _onConfirmar,
        ),
      ],
    );
  }

  Widget _infoBox(ColorScheme cs, TextTheme txtTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Derby "${widget.nombreDerby}"',
                style: txtTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoStat(
            Icons.groups,
            '${_partidosActivos.length} partidos activos (IMPAR)',
            cs,
          ),
          _infoStat(
            Icons.sports_mma,
            '$_totalGallosPL gallos PL${_totalEsImpar ? " (IMPAR)" : " (par)"}',
            cs,
          ),
          _infoStat(Icons.repeat, '${widget.rondasPL} rondas PL', cs),
          if (_candidatosDoble.length < _partidosActivos.length)
            _infoStat(
              Icons.warning_amber,
              '${_candidatosDoble.length} partido(s) elegible(s) para doble pelea',
              cs,
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _infoStat(IconData icon, String text, ColorScheme cs,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? cs.onSurface),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstrategiaOption(
    EstrategiaImpar valor,
    IconData icon,
    String titulo,
    String subtitulo,
    ColorScheme cs,
  ) {
    final selected = _estrategia == valor;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _estrategia = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? cs.primaryContainer.withValues(alpha: 0.2) : null,
        ),
        child: Row(
          children: [
            Radio<EstrategiaImpar>(
              value: valor,
              groupValue: _estrategia,
              onChanged: (v) => setState(() => _estrategia = v!),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Icon(icon, size: 22, color: selected ? cs.primary : cs.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartidoDobleSelector(ColorScheme cs, TextTheme txtTheme) {
    if (_candidatosDoble.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error, size: 18, color: cs.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No hay partidos con suficientes gallos PL para doble pelea.',
                style: TextStyle(fontSize: 12, color: cs.error),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _candidatosDoble.length,
        itemBuilder: (_, i) {
          final p = _candidatosDoble[i];
          final gallosPL = _gallosPLPorPartido[p.id] ?? [];
          final selected = _partidoDobleId == p.id;
          final pesoMin = gallosPL.isNotEmpty
              ? gallosPL
                  .map((g) => g.pesoGramos)
                  .reduce((a, b) => a < b ? a : b)
              : 0.0;
          final pesoMax = gallosPL.isNotEmpty
              ? gallosPL
                  .map((g) => g.pesoGramos)
                  .reduce((a, b) => a > b ? a : b)
              : 0.0;

          return Card(
            elevation: selected ? 2 : 0,
            color: selected ? cs.primaryContainer.withValues(alpha: 0.3) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: selected ? cs.primary : cs.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: RadioListTile<int>(
              value: p.id,
              groupValue: _partidoDobleId,
              onChanged: (v) => setState(() => _partidoDobleId = v),
              dense: true,
              title: Text(
                p.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
              subtitle: Text(
                '${gallosPL.length} gallos PL  '
                '(${pesoMin.toStringAsFixed(0)}g – ${pesoMax.toStringAsFixed(0)}g)',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              secondary: CircleAvatar(
                radius: 14,
                backgroundColor: selected ? cs.primary : cs.surfaceContainerHighest,
                child: Text(
                  '${gallosPL.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: selected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromocionSelector(ColorScheme cs, TextTheme txtTheme) {
    final candidatos = _candidatosPromocion;
    if (candidatos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'No hay gallos base disponibles para promover.',
          style: TextStyle(fontSize: 12, color: cs.error),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: candidatos.length,
        itemBuilder: (_, i) {
          final info = candidatos[i];
          final selected = _galloBaseId == info.gallo.id;
          final fitLabel = info.distanciaMinPL == 0
              ? 'Peso idéntico a PL'
              : 'Dif. mín. ${info.distanciaMinPL.toStringAsFixed(0)}g vs PL';

          return Card(
            elevation: 0,
            color: selected ? cs.tertiaryContainer.withValues(alpha: 0.3) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: selected ? cs.tertiary : cs.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: RadioListTile<int>(
              value: info.gallo.id,
              groupValue: _galloBaseId,
              onChanged: (v) => setState(() => _galloBaseId = v),
              dense: true,
              activeColor: cs.tertiary,
              title: Row(
                children: [
                  Text(
                    '${info.gallo.anillo} (P${info.partido.id})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected ? cs.tertiary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: info.distanciaMinPL <= 20
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fitLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: info.distanciaMinPL <= 20
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                '${info.gallo.pesoGramos.toStringAsFixed(0)}g  •  '
                '${info.partido.nombre}  •  '
                '${info.totalPLPartido} gallos PL',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onConfirmar() {
    final decision = ImparDecision(
      estrategia: _estrategia,
      partidoDoblePeleaId:
          _estrategia == EstrategiaImpar.doblePelea ? _partidoDobleId : null,
      galloBasePromovidoId: _promoverGallo ? _galloBaseId : null,
      promoverGallo: _promoverGallo,
    );
    Navigator.pop(context, decision);
  }
}

/// Info helper para candidatos base→PL.
class _GalloBaseInfo {
  final Gallo gallo;
  final Partido partido;
  final double distanciaMinPL;
  final int totalPLPartido;

  const _GalloBaseInfo({
    required this.gallo,
    required this.partido,
    required this.distanciaMinPL,
    required this.totalPLPartido,
  });
}

/// Muestra el diálogo de configuración impar y retorna la decisión del juez.
///
/// Retorna null si el juez cancela.
Future<ImparDecision?> mostrarDialogImparConfig({
  required BuildContext context,
  required List<Partido> partidos,
  required List<Gallo> gallos,
  required String nombreDerby,
  required int rondasPL,
}) {
  return showDialog<ImparDecision>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => DialogImparConfig(
      partidos: partidos,
      gallos: gallos,
      nombreDerby: nombreDerby,
      rondasPL: rondasPL,
    ),
  );
}
