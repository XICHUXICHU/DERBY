import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show derbyRepository;
import '../../data/database/app_database.dart';

/// Pantalla de configuración del derby.
///
/// Se usa tanto para crear un derby nuevo como para editar la
/// configuración de uno existente (siempre que esté en estado
/// "configuración").
class DerbyConfigFormScreen extends StatefulWidget {
  /// Si es null → crear nuevo; si tiene valor → editar existente.
  final Derby? derbyExistente;

  const DerbyConfigFormScreen({super.key, this.derbyExistente});

  bool get esEdicion => derbyExistente != null;

  @override
  State<DerbyConfigFormScreen> createState() => _DerbyConfigFormScreenState();
}

class _DerbyConfigFormScreenState extends State<DerbyConfigFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;

  // ── Controladores ──
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _rondasCtrl;
  late final TextEditingController _puntosGCtrl;
  late final TextEditingController _puntosPCtrl;
  late final TextEditingController _puntosTCtrl;
  late final TextEditingController _posicionesPremioCtrl;
  late final TextEditingController _pesoMinCtrl;
  late final TextEditingController _pesoMaxCtrl;
  late final TextEditingController _pesoBaseCtrl;
  late bool _permitirRepeticiones;
  late final TextEditingController _difMaxPesoCtrl;
  late bool _validacionEstricta;

  @override
  void initState() {
    super.initState();
    final d = widget.derbyExistente;

    _nombreCtrl = TextEditingController(text: d?.nombre ?? '');
    _rondasCtrl = TextEditingController(text: '${d?.rondasTotales ?? 4}');
    _puntosGCtrl = TextEditingController(text: '${d?.puntosVictoria ?? 2}');
    _puntosPCtrl = TextEditingController(text: '${d?.puntosDerrota ?? 0}');
    _puntosTCtrl = TextEditingController(text: '${d?.puntosEmpate ?? 1}');
    _posicionesPremioCtrl = TextEditingController(
      text: '${d?.posicionesPremio ?? 3}',
    );
    _pesoMinCtrl = TextEditingController(
      text: d != null ? d.pesoMinimo.toStringAsFixed(0) : '1800',
    );
    _pesoMaxCtrl = TextEditingController(
      text: d != null ? d.pesoMaximo.toStringAsFixed(0) : '2500',
    );
    _pesoBaseCtrl = TextEditingController(
      text: d != null && d.pesoGalloBase > 0
          ? d.pesoGalloBase.toStringAsFixed(0)
          : '',
    );
    _permitirRepeticiones = d?.permitirRepeticiones ?? false;
    _difMaxPesoCtrl = TextEditingController(
      text: d != null ? d.diferenciaMaxPeso.toStringAsFixed(0) : '80',
    );
    _validacionEstricta = d?.validacionEstricta ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rondasCtrl.dispose();
    _puntosGCtrl.dispose();
    _puntosPCtrl.dispose();
    _puntosTCtrl.dispose();
    _posicionesPremioCtrl.dispose();
    _pesoMinCtrl.dispose();
    _pesoMaxCtrl.dispose();
    _pesoBaseCtrl.dispose();
    _difMaxPesoCtrl.dispose();
    super.dispose();
  }

  // ── Guardar ──

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final nombre = _nombreCtrl.text.trim();
      final rondas = int.parse(_rondasCtrl.text.trim());
      final pG = int.parse(_puntosGCtrl.text.trim());
      final pP = int.parse(_puntosPCtrl.text.trim());
      final pT = int.parse(_puntosTCtrl.text.trim());
      final posiciones = int.parse(_posicionesPremioCtrl.text.trim());
      final pesoMin = double.parse(_pesoMinCtrl.text.trim());
      final pesoMax = double.parse(_pesoMaxCtrl.text.trim());
      final pesoBase = _pesoBaseCtrl.text.trim().isEmpty
          ? 0.0
          : double.parse(_pesoBaseCtrl.text.trim());
      final difMaxPeso = _difMaxPesoCtrl.text.trim().isEmpty
          ? 0.0
          : double.parse(_difMaxPesoCtrl.text.trim());

      if (widget.esEdicion) {
        await derbyRepository.actualizarConfig(
          id: widget.derbyExistente!.id,
          nombre: nombre,
          rondasTotales: rondas,
          puntosVictoria: pG,
          puntosEmpate: pT,
          puntosDerrota: pP,
          posicionesPremio: posiciones,
          pesoMinimo: pesoMin,
          pesoMaximo: pesoMax,
          pesoGalloBase: pesoBase,
          permitirRepeticiones: _permitirRepeticiones,
          diferenciaMaxPeso: difMaxPeso,
          validacionEstricta: _validacionEstricta,
        );
      } else {
        await derbyRepository.crear(
          nombre: nombre,
          rondasTotales: rondas,
          puntosVictoria: pG,
          puntosEmpate: pT,
          puntosDerrota: pP,
          posicionesPremio: posiciones,
          pesoMinimo: pesoMin,
          pesoMaximo: pesoMax,
          pesoGalloBase: pesoBase,
          permitirRepeticiones: _permitirRepeticiones,
          diferenciaMaxPeso: difMaxPeso,
          validacionEstricta: _validacionEstricta,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ── Validadores ──

  String? _reqEntero(String? v, {int min = 0, int? max}) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Número inválido';
    if (n < min) return 'Mínimo $min';
    if (max != null && n > max) return 'Máximo $max';
    return null;
  }

  String? _reqDecimal(String? v, {double min = 0}) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    final n = double.tryParse(v.trim());
    if (n == null) return 'Número inválido';
    if (n < min) return 'Mínimo ${min.toStringAsFixed(0)}';
    return null;
  }

  String? _validarPesoMax(String? v) {
    final err = _reqDecimal(v, min: 1);
    if (err != null) return err;
    final max = double.parse(v!.trim());
    final min = double.tryParse(_pesoMinCtrl.text.trim()) ?? 0;
    if (max <= min) return 'Debe ser mayor al mínimo';
    return null;
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final intFormatter = FilteringTextInputFormatter.digitsOnly;
    final decFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'^\d+\.?\d{0,1}'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.esEdicion ? 'Configuración del Derby' : 'Nuevo Derby',
        ),
        centerTitle: true,
        actions: [
          if (_guardando)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── NOMBRE ──────────────────────────
                  _SectionHeader(
                    icon: Icons.emoji_events,
                    title: 'NOMBRE DEL DERBY',
                    color: cs.primary,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej: Derby Nacional 2026',
                      prefixIcon: Icon(Icons.edit),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: !widget.esEdicion,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
                  ),

                  const SizedBox(height: 32),

                  // ── RONDAS Y POSICIONES ─────────────
                  _SectionHeader(
                    icon: Icons.repeat,
                    title: 'RONDAS',
                    color: cs.tertiary,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rondasCtrl,
                          decoration: const InputDecoration(
                            labelText: 'No. de rondas',
                            hintText: '4',
                            prefixIcon: Icon(Icons.format_list_numbered),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [intFormatter],
                          validator: (v) => _reqEntero(v, min: 1, max: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _posicionesPremioCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Posiciones de premio',
                            hintText: '3',
                            prefixIcon: Icon(Icons.military_tech),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [intFormatter],
                          validator: (v) => _reqEntero(v, min: 1, max: 10),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── PUNTUACIÓN ──────────────────────
                  _SectionHeader(
                    icon: Icons.scoreboard,
                    title: 'PUNTUACIÓN POR RESULTADO',
                    color: cs.secondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Define cuántos puntos se otorgan por cada resultado',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _puntosGCtrl,
                          decoration: InputDecoration(
                            labelText: 'G (Ganado)',
                            hintText: '2',
                            prefixIcon: Icon(
                              Icons.emoji_events,
                              color: Colors.amber.shade700,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [intFormatter],
                          validator: (v) => _reqEntero(v, min: 0, max: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _puntosPCtrl,
                          decoration: InputDecoration(
                            labelText: 'P (Perdido)',
                            hintText: '0',
                            prefixIcon: Icon(
                              Icons.cancel,
                              color: Colors.red.shade400,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [intFormatter],
                          validator: (v) => _reqEntero(v, min: 0, max: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _puntosTCtrl,
                          decoration: InputDecoration(
                            labelText: 'T (Tablas)',
                            hintText: '1',
                            prefixIcon: Icon(
                              Icons.handshake,
                              color: Colors.orange.shade400,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [intFormatter],
                          validator: (v) => _reqEntero(v, min: 0, max: 10),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── PESOS ───────────────────────────
                  _SectionHeader(
                    icon: Icons.scale,
                    title: 'CONFIGURACIÓN DE PESOS',
                    color: cs.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rango de peso aceptado para gallos P.L. y peso del gallo base',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pesoMinCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Peso mínimo',
                            suffixText: 'g',
                            prefixIcon: Icon(Icons.arrow_downward),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [decFormatter],
                          validator: (v) => _reqDecimal(v, min: 100),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _pesoMaxCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Peso máximo',
                            suffixText: 'g',
                            prefixIcon: Icon(Icons.arrow_upward),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [decFormatter],
                          validator: _validarPesoMax,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pesoBaseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Peso gallo base (opcional)',
                      hintText: 'Dejar vacío = sin restricción',
                      suffixText: 'g',
                      prefixIcon: Icon(Icons.star),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [decFormatter],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Peso inválido';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── OPCIONES AVANZADAS ──────────────
                  _SectionHeader(
                    icon: Icons.tune,
                    title: 'OPCIONES AVANZADAS',
                    color: cs.tertiary,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Permitir repetir contrincantes'),
                      subtitle: const Text(
                        'En derbys de pesos libres se pueden '
                        'repetir enfrentamientos entre partidos',
                      ),
                      value: _permitirRepeticiones,
                      onChanged: (v) =>
                          setState(() => _permitirRepeticiones = v),
                      secondary: const Icon(Icons.swap_horiz),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _difMaxPesoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Diferencia máxima de peso P.L.',
                      hintText: '80  (0 = sin límite)',
                      suffixText: 'g',
                      prefixIcon: Icon(Icons.compare_arrows),
                      border: OutlineInputBorder(),
                      helperText:
                          'Solo aplica a peleas de peso libre, no a gallo base',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [decFormatter],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0) return 'Valor inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Validación estricta'),
                      subtitle: const Text(
                        'Si está activa, el sorteo falla cuando hay '
                        'errores de validación. Si está desactivada, '
                        'muestra advertencias y permite continuar.',
                      ),
                      value: _validacionEstricta,
                      onChanged: (v) => setState(() => _validacionEstricta = v),
                      secondary: const Icon(Icons.verified),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── RESUMEN ─────────────────────────
                  _buildResumen(cs),

                  const SizedBox(height: 24),

                  // ── BOTÓN GUARDAR ───────────────────
                  FilledButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: Icon(
                      widget.esEdicion ? Icons.save : Icons.add_circle,
                    ),
                    label: Text(
                      widget.esEdicion
                          ? 'GUARDAR CONFIGURACIÓN'
                          : 'CREAR DERBY',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta de resumen de configuración.
  Widget _buildResumen(ColorScheme cs) {
    final g = _puntosGCtrl.text.trim();
    final p = _puntosPCtrl.text.trim();
    final t = _puntosTCtrl.text.trim();

    return Card(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'RESUMEN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    letterSpacing: 1,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _resumenItem('Rondas', _rondasCtrl.text),
            _resumenItem('Puntos', 'G=$g  P=$p  T=$t'),
            _resumenItem(
              'Peso P.L.',
              '${_pesoMinCtrl.text}g – ${_pesoMaxCtrl.text}g',
            ),
            _resumenItem(
              'Peso base',
              _pesoBaseCtrl.text.trim().isEmpty
                  ? 'Sin restricción'
                  : '${_pesoBaseCtrl.text}g',
            ),
            _resumenItem(
              'Repeticiones',
              _permitirRepeticiones ? 'Sí (pesos libres)' : 'No',
            ),
            _resumenItem(
              'Dif. máx. peso',
              _difMaxPesoCtrl.text.trim().isEmpty ||
                      _difMaxPesoCtrl.text.trim() == '0'
                  ? 'Sin límite'
                  : '${_difMaxPesoCtrl.text}g',
            ),
            _resumenItem(
              'Validación',
              _validacionEstricta ? 'Estricta' : 'Flexible',
            ),

          ],
        ),
      ),
    );
  }

  Widget _resumenItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// ── Widget auxiliar ─────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
      ],
    );
  }
}
