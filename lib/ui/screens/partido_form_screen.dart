import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show partidoRepository, galloRepository, derbyRepository;
import '../../data/database/app_database.dart';

/// Formulario de captura de partido con sus 4 gallos y depósito.
///
/// Campos:
///  - Nombre del partido
///  - Gallo Base (anillo + peso)
///  - Gallo 1 P.L. (anillo + peso libre)
///  - Gallo 2 P.L. (anillo + peso libre)
///  - Gallo 3 P.L. (anillo + peso libre)
///  - Depósito: pagado (switch) + cantidad
class PartidoFormScreen extends StatefulWidget {
  final int derbyId;
  final Partido? partidoExistente;

  const PartidoFormScreen({
    super.key,
    required this.derbyId,
    this.partidoExistente,
  });

  bool get esEdicion => partidoExistente != null;

  @override
  State<PartidoFormScreen> createState() => _PartidoFormScreenState();
}

class _PartidoFormScreenState extends State<PartidoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Partido
  late final TextEditingController _nombreCtrl;

  // Gallo Base
  late final TextEditingController _baseAnilloCtrl;
  late final TextEditingController _basePesoCtrl;

  // Gallos P.L. 1, 2, 3
  late final List<TextEditingController> _plAnilloCtrls;
  late final List<TextEditingController> _plPesoCtrls;

  // Depósito
  bool _depositoPagado = false;
  late final TextEditingController _depositoCantidadCtrl;

  // Comodín
  bool _esComodin = false;

  bool _guardando = false;

  // Gallos existentes (para edición)
  GalloEntry? _galloBaseExistente;
  List<GalloEntry> _gallosPLExistentes = [];

  // Anillos ya registrados en el derby (excluye los del partido actual si edita)
  Set<String> _anillosOcupadosEnDerby = {};

  // Configuración de pesos del derby
  Derby? _derbyConfig;

  @override
  void initState() {
    super.initState();

    _nombreCtrl = TextEditingController(
      text: widget.partidoExistente?.nombre ?? '',
    );

    _baseAnilloCtrl = TextEditingController();
    _basePesoCtrl = TextEditingController();

    _plAnilloCtrls = List.generate(3, (_) => TextEditingController());
    _plPesoCtrls = List.generate(3, (_) => TextEditingController());

    _depositoCantidadCtrl = TextEditingController(
      text: widget.partidoExistente?.depositoCantidad.toStringAsFixed(0) ?? '',
    );
    _depositoPagado = widget.partidoExistente?.depositoPagado ?? false;

    _esComodin = widget.partidoExistente?.esComodin ?? false;

    _cargarAnillosExistentes();
    _cargarConfigDerby();

    if (widget.esEdicion) {
      _cargarGallosExistentes();
    }
  }

  /// Carga la configuración del derby para validar pesos.
  Future<void> _cargarConfigDerby() async {
    final derby = await derbyRepository.obtenerPorId(widget.derbyId);
    if (mounted && derby != null) {
      setState(() => _derbyConfig = derby);
    }
  }

  /// Carga todos los anillos ya registrados en el derby (excepto los del
  /// partido que se está editando) para validar duplicados.
  Future<void> _cargarAnillosExistentes() async {
    final gallos = await galloRepository.listarPorDerby(widget.derbyId);

    final propiosIds = <int>{};
    if (widget.esEdicion) {
      final propios = await galloRepository
          .listarPorPartido(widget.partidoExistente!.id);
      propiosIds.addAll(propios.map((g) => g.id));
    }

    if (mounted) {
      setState(() {
        _anillosOcupadosEnDerby = gallos
            .where((g) => !propiosIds.contains(g.id))
            .map((g) => g.anillo.trim().toUpperCase())
            .toSet();
      });
    }
  }

  /// Validador de anillo: revisa campo vacío, duplicados dentro del form
  /// y anillos ya ocupados en el derby.
  String? _validarAnillo(String? value) {
    if (value == null || value.trim().isEmpty) return 'Anillo requerido';

    final anillo = value.trim().toUpperCase();

    // Duplicados dentro del formulario
    final todos = [
      _baseAnilloCtrl,
      ..._plAnilloCtrls,
    ];
    int veces = 0;
    for (final ctrl in todos) {
      if (ctrl.text.trim().toUpperCase() == anillo) veces++;
    }
    if (veces > 1) {
      return 'Ese No. de anillo está repetido en este formulario';
    }

    // Duplicados contra la base de datos
    if (_anillosOcupadosEnDerby.contains(anillo)) {
      return 'Ese No. de anillo ya pertenece a otro partido';
    }

    return null;
  }

  /// Validador de peso para el gallo base.
  /// Si el derby define pesoGalloBase > 0, el peso debe coincidir exactamente.
  String? _validarPesoBase(String? v) {
    if (v == null || v.trim().isEmpty) return 'Peso requerido';
    final peso = double.tryParse(v.trim());
    if (peso == null || peso <= 0) return 'Peso inválido';
    if (_derbyConfig != null && _derbyConfig!.pesoGalloBase > 0) {
      if (peso != _derbyConfig!.pesoGalloBase) {
        return 'Debe ser ${_derbyConfig!.pesoGalloBase.toStringAsFixed(0)}g';
      }
    }
    return null;
  }

  /// Validador de peso para gallos P.L.
  /// Verifica que esté dentro del rango configurado del derby.
  String? _validarPesoPL(String? v) {
    if (v == null || v.trim().isEmpty) return 'Peso requerido';
    final peso = double.tryParse(v.trim());
    if (peso == null || peso <= 0) return 'Peso inválido';
    if (_derbyConfig != null) {
      if (peso < _derbyConfig!.pesoMinimo) {
        return 'Mínimo ${_derbyConfig!.pesoMinimo.toStringAsFixed(0)}g';
      }
      if (peso > _derbyConfig!.pesoMaximo) {
        return 'Máximo ${_derbyConfig!.pesoMaximo.toStringAsFixed(0)}g';
      }
    }
    return null;
  }

  Future<void> _cargarGallosExistentes() async {
    final gallos = await galloRepository
        .listarPorPartido(widget.partidoExistente!.id);

    final base = gallos.where((g) => g.esBase).firstOrNull;
    final pls = gallos.where((g) => !g.esBase).toList();

    setState(() {
      _galloBaseExistente = base;
      _gallosPLExistentes = pls;

      if (base != null) {
        _baseAnilloCtrl.text = base.anillo;
        _basePesoCtrl.text = base.pesoGramos.toStringAsFixed(0);
      }
      for (var i = 0; i < pls.length && i < 3; i++) {
        _plAnilloCtrls[i].text = pls[i].anillo;
        _plPesoCtrls[i].text = pls[i].pesoGramos.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _baseAnilloCtrl.dispose();
    _basePesoCtrl.dispose();
    for (final c in _plAnilloCtrls) {
      c.dispose();
    }
    for (final c in _plPesoCtrls) {
      c.dispose();
    }
    _depositoCantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      int partidoId;

      if (widget.esEdicion) {
        partidoId = widget.partidoExistente!.id;
        await partidoRepository.actualizar(
          id: partidoId,
          nombre: _nombreCtrl.text.trim(),
          depositoPagado: _depositoPagado,
          depositoCantidad: double.tryParse(_depositoCantidadCtrl.text) ?? 0.0,
        );
      } else {
        partidoId = await partidoRepository.crear(
          derbyId: widget.derbyId,
          nombre: _nombreCtrl.text.trim(),
          depositoPagado: _depositoPagado,
          depositoCantidad: double.tryParse(_depositoCantidadCtrl.text) ?? 0.0,
          esComodin: _esComodin,
        );
      }

      // — Guardar/actualizar gallos —
      await _guardarGalloBase(partidoId);
      await _guardarGallosPL(partidoId);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _guardarGalloBase(int partidoId) async {
    final anillo = _baseAnilloCtrl.text.trim();
    final peso = double.tryParse(_basePesoCtrl.text) ?? 0;

    if (anillo.isEmpty) return;

    if (_galloBaseExistente != null) {
      await galloRepository.actualizar(
        id: _galloBaseExistente!.id,
        anillo: anillo,
        pesoGramos: peso,
        esBase: true,
      );
    } else {
      await galloRepository.crear(
        partidoId: partidoId,
        anillo: anillo,
        pesoGramos: peso,
        esBase: true,
      );
    }
  }

  Future<void> _guardarGallosPL(int partidoId) async {
    for (var i = 0; i < 3; i++) {
      final anillo = _plAnilloCtrls[i].text.trim();
      final peso = double.tryParse(_plPesoCtrls[i].text) ?? 0;

      if (anillo.isEmpty) continue;

      if (i < _gallosPLExistentes.length) {
        await galloRepository.actualizar(
          id: _gallosPLExistentes[i].id,
          anillo: anillo,
          pesoGramos: peso,
          esBase: false,
        );
      } else {
        await galloRepository.crear(
          partidoId: partidoId,
          anillo: anillo,
          pesoGramos: peso,
          esBase: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar Partido' : 'Nuevo Partido'),
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
                  // ── NOMBRE DEL PARTIDO ──
                  _SectionHeader(
                    icon: Icons.group,
                    title: 'NOMBRE DEL PARTIDO',
                    color: cs.primary,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del partido',
                      hintText: 'Ej: Los Destruidores',
                      prefixIcon: Icon(Icons.edit),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // ── GALLO BASE ──
                  _SectionHeader(
                    icon: Icons.star,
                    title: 'GALLO BASE',
                    color: cs.tertiary,
                  ),
                  const SizedBox(height: 4),
                  if (_derbyConfig != null && _derbyConfig!.pesoGalloBase > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Peso requerido: ${_derbyConfig!.pesoGalloBase.toStringAsFixed(0)}g',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.tertiary,
                            ),
                      ),
                    ),
                  if (_derbyConfig != null && _derbyConfig!.pesoGalloBase == 0)
                    const SizedBox(height: 4),
                  _GalloFields(
                    anilloCtrl: _baseAnilloCtrl,
                    pesoCtrl: _basePesoCtrl,
                    labelAnillo: 'Anillo gallo base',
                    labelPeso: _derbyConfig != null && _derbyConfig!.pesoGalloBase > 0
                        ? 'Peso (${_derbyConfig!.pesoGalloBase.toStringAsFixed(0)}g)'
                        : 'Peso (gramos)',
                    anilloValidator: _validarAnillo,
                    pesoValidator: _validarPesoBase,
                  ),

                  const SizedBox(height: 32),

                  // ── GALLOS P.L. ──
                  _SectionHeader(
                    icon: Icons.fitness_center,
                    title: 'GALLOS PESO LIBRE (P.L.)',
                    color: cs.secondary,
                  ),
                  const SizedBox(height: 4),
                  if (_derbyConfig != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Rango aceptado: ${_derbyConfig!.pesoMinimo.toStringAsFixed(0)}g – ${_derbyConfig!.pesoMaximo.toStringAsFixed(0)}g',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.secondary,
                            ),
                      ),
                    ),
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _GalloFields(
                      anilloCtrl: _plAnilloCtrls[i],
                      pesoCtrl: _plPesoCtrls[i],
                      labelAnillo: 'Anillo gallo ${i + 1} P.L.',
                      labelPeso: 'Peso (gramos)',
                      anilloValidator: _validarAnillo,
                      pesoValidator: _validarPesoPL,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── DEPÓSITO ──
                  _SectionHeader(
                    icon: Icons.payments,
                    title: 'DEPÓSITO',
                    color: cs.primary,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _depositoCantidadCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Column(
                            children: [
                              Text(
                                'PAGADO',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Switch(
                                value: _depositoPagado,
                                onChanged: (v) =>
                                    setState(() => _depositoPagado = v),
                                activeColor: cs.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── COMODÍN ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _esComodin
                            ? cs.tertiary
                            : cs.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.style,
                            color:
                                _esComodin ? cs.tertiary : cs.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Comodín',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _esComodin
                                        ? cs.tertiary
                                        : cs.onSurface,
                                  )),
                              Text(
                                  'Partido comodín que entra cuando hay número impar',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _esComodin,
                          onChanged: (v) => setState(() => _esComodin = v),
                          activeColor: cs.tertiary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── BOTÓN GUARDAR ──
                  FilledButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: Icon(
                        widget.esEdicion ? Icons.save : Icons.add_circle),
                    label: Text(
                      widget.esEdicion
                          ? 'GUARDAR CAMBIOS'
                          : 'REGISTRAR PARTIDO',
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
}

// ── Widgets auxiliares ──────────────────────────────────────────────

/// Encabezado de sección con ícono y título.
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
        Expanded(
          child: Divider(color: color.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}

/// Par de campos anillo + peso para un gallo.
class _GalloFields extends StatelessWidget {
  final TextEditingController anilloCtrl;
  final TextEditingController pesoCtrl;
  final String labelAnillo;
  final String labelPeso;
  final FormFieldValidator<String>? anilloValidator;
  final FormFieldValidator<String>? pesoValidator;

  const _GalloFields({
    required this.anilloCtrl,
    required this.pesoCtrl,
    required this.labelAnillo,
    required this.labelPeso,
    this.anilloValidator,
    this.pesoValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Anillo
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: anilloCtrl,
            decoration: InputDecoration(
              labelText: labelAnillo,
              hintText: 'Ej: A-001',
              prefixIcon: const Icon(Icons.tag),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: anilloValidator,
          ),
        ),
        const SizedBox(width: 12),
        // Peso
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: pesoCtrl,
            decoration: InputDecoration(
              labelText: labelPeso,
              suffixText: 'g',
              prefixIcon: const Icon(Icons.scale),
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
            ],
            validator: pesoValidator ??
                (anilloValidator != null
                    ? (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Peso requerido';
                        }
                        final peso = double.tryParse(v);
                        if (peso == null || peso <= 0) {
                          return 'Peso inválido';
                        }
                        return null;
                      }
                    : null),
          ),
        ),
      ],
    );
  }
}
