import 'package:flutter/material.dart';
import '../../domain/domain.dart';
import '../../data/repositories/gallo_repository.dart';
import '../../data/repositories/partido_repository.dart';

class DerbyPeleasReassignScreen extends StatefulWidget {
  final List<Ronda> rondasOriginales;
  final List<Partido> partidos;
  final List<Gallo> gallos;
  final List<Compadres> compadres;
  final double diferenciaMaxPeso;
  final GalloRepository galloRepository;
  final PartidoRepository partidoRepository;
  final int derbyId;

  const DerbyPeleasReassignScreen({
    super.key,
    required this.rondasOriginales,
    required this.partidos,
    required this.gallos,
    required this.compadres,
    required this.diferenciaMaxPeso,
    required this.galloRepository,
    required this.partidoRepository,
    required this.derbyId,
  });

  @override
  State<DerbyPeleasReassignScreen> createState() =>
      _DerbyPeleasReassignScreenState();
}

class _DerbyPeleasReassignScreenState extends State<DerbyPeleasReassignScreen> {
  late List<Ronda> _rondas;

  /// Gallos P.L. quitados de sus rondas — disponibles para reasignar.
  final List<Gallo> _gallosSueltos = [];

  /// Gallos comodín creados ad-hoc en este editor (ya persistidos en DB).
  final List<Gallo> _gallosAdHoc = [];

  /// IDs de gallos que estaban en rondas con esRondaBase=true al abrir el editor.
  /// Se usa como fuente de verdad para la sección BASE del panel.
  late final Set<int> _gallosBaseIds;

  /// ID del partido "COMODÍN ORGANIZADOR" creado automáticamente si el
  /// usuario elige agregar un gallo sin partido registrado.
  int? _organizadorPartidoId;

  // ── Getters computados ────────────────────────────────

  Set<int> get _gallosEnRondas => _rondas
      .expand((r) => r.enfrentamientos)
      .expand((e) => [e.galloA.id, if (e.galloB != null) e.galloB!.id])
      .toSet();

  List<Gallo> get _gallosBasePanel {
    final enRondas = _gallosEnRondas;
    return widget.gallos
        .where((g) =>
            (g.esBase || _gallosBaseIds.contains(g.id)) &&
            !enRondas.contains(g.id))
        .toList();
  }

  List<Gallo> get _gallosComodinPanel {
    final comodinIds =
        widget.partidos.where((p) => p.esComodin).map((p) => p.id).toSet();
    final enRondas = _gallosEnRondas;
    final deWidget = widget.gallos
        .where((g) => comodinIds.contains(g.partidoId) && !enRondas.contains(g.id));
    final adHocDisponibles = _gallosAdHoc.where((g) => !enRondas.contains(g.id));
    return [...deWidget, ...adHocDisponibles];
  }

  /// True si el gallo es base o pertenece a un partido comodín.
  bool _esBaseOComodin(Gallo g) =>
      g.esBase ||
      _gallosBaseIds.contains(g.id) ||
      widget.partidos.any((p) => p.id == g.partidoId && p.esComodin);

  @override
  void initState() {
    super.initState();
    // Capturar IDs de gallos que están en rondas base ANTES de cualquier edición.
    // Esto resuelve el caso donde esBase=false en DB pero el gallo juega en ronda base.
    _gallosBaseIds = widget.rondasOriginales
        .where((r) => r.esRondaBase)
        .expand((r) => r.enfrentamientos)
        .expand((e) => [e.galloA.id, if (e.galloB != null) e.galloB!.id])
        .toSet();
    _rondas = widget.rondasOriginales.map<Ronda>((r) {
      return Ronda(
        numero: r.numero,
        enfrentamientos: List.from(r.enfrentamientos),
      );
    }).toList();
  }

  bool _esInvalido(Enfrentamiento e) {
    if (e.galloB == null) return false; // si es huérfano en teoría no es "inválido", es incompleto
    if (e.galloA.partidoId == e.galloB!.partidoId) return true;
    if (widget.diferenciaMaxPeso > 0 &&
        e.galloA.diferenciaAbsoluta(e.galloB!) > widget.diferenciaMaxPeso) {
      return true;
    }
    for (var c in widget.compadres) {
      if ((c.partidoIdA == e.galloA.partidoId &&
              c.partidoIdB == e.galloB!.partidoId) ||
          (c.partidoIdA == e.galloB!.partidoId &&
              c.partidoIdB == e.galloA.partidoId)) {
        return true;
      }
    }
    return false;
  }

  void _intercambiarGallos(
    int rondaOrigenIdx,
    int rondaDestinoIdx,
    int enfOrigenIdx,
    int enfDestinoIdx,
    bool moverGalloBOrigen,
    bool moverGalloBDestino,
  ) {
    setState(() {
      final rondaOrigen = _rondas[rondaOrigenIdx];
      final rondaDestino = _rondas[rondaDestinoIdx];
      
      final enfOrigen = rondaOrigen.enfrentamientos[enfOrigenIdx];
      final enfDestino = rondaDestino.enfrentamientos[enfDestinoIdx];

      final galloOrigen = moverGalloBOrigen ? enfOrigen.galloB : enfOrigen.galloA;
      final galloDestino = moverGalloBDestino ? enfDestino.galloB : enfDestino.galloA;

      Gallo? aOrig = moverGalloBOrigen ? enfOrigen.galloA : galloDestino;
      Gallo? bOrig = !moverGalloBOrigen ? enfOrigen.galloB : galloDestino;

      Gallo? aDest = moverGalloBDestino ? enfDestino.galloA : galloOrigen;
      Gallo? bDest = !moverGalloBDestino ? enfDestino.galloB : galloOrigen;

      // Normalizar: galloA no puede ser null en un enfrentamiento vivo
      if (aOrig == null && bOrig != null) {
        aOrig = bOrig;
        bOrig = null;
      }
      if (aDest == null && bDest != null) {
        aDest = bDest;
        bDest = null;
      }

      // Reconstruir origen
      final nuevaListaOrigen = <Enfrentamiento>[];
      for (int i = 0; i < rondaOrigen.enfrentamientos.length; i++) {
        if (i == enfOrigenIdx) {
          if (aOrig != null) {
            nuevaListaOrigen.add(Enfrentamiento(
              id: enfOrigen.id,
              rondaNumero: enfOrigen.rondaNumero,
              galloA: aOrig,
              galloB: bOrig,
              diferenciaPeso: bOrig != null ? aOrig.diferenciaAbsoluta(bOrig) : 0,
            ));
          }
        } else if (rondaOrigenIdx == rondaDestinoIdx && i == enfDestinoIdx) {
          if (aDest != null) {
            nuevaListaOrigen.add(Enfrentamiento(
              id: enfDestino.id,
              rondaNumero: enfDestino.rondaNumero,
              galloA: aDest,
              galloB: bDest,
              diferenciaPeso: bDest != null ? aDest.diferenciaAbsoluta(bDest) : 0,
            ));
          }
        } else {
          nuevaListaOrigen.add(rondaOrigen.enfrentamientos[i]);
        }
      }

      // Reconstruir destino sólo si es de otra ronda
      if (rondaOrigenIdx != rondaDestinoIdx) {
        final nuevaListaDestino = <Enfrentamiento>[];
        for (int i = 0; i < rondaDestino.enfrentamientos.length; i++) {
          if (i == enfDestinoIdx) {
            if (aDest != null) {
              nuevaListaDestino.add(Enfrentamiento(
                id: enfDestino.id,
                rondaNumero: enfDestino.rondaNumero,
                galloA: aDest,
                galloB: bDest,
                diferenciaPeso: bDest != null ? aDest.diferenciaAbsoluta(bDest) : 0,
              ));
            }
          } else {
            nuevaListaDestino.add(rondaDestino.enfrentamientos[i]);
          }
        }
        rondaDestino.enfrentamientos.clear();
        rondaDestino.enfrentamientos.addAll(nuevaListaDestino);
      }

      rondaOrigen.enfrentamientos.clear();
      rondaOrigen.enfrentamientos.addAll(nuevaListaOrigen);
    });
  }

  // ── Quitar gallo de un enfrentamiento ────────────────

  void _quitarGallo(int rondaIdx, int enfIdx, bool isGalloB) {
    setState(() {
      final ronda = _rondas[rondaIdx];
      final enf = ronda.enfrentamientos[enfIdx];
      final galloQuitado = isGalloB ? enf.galloB : enf.galloA;

      // Solo los gallos P.L. (no base ni comodín) van a SUELTOS;
      // base/comodín reaparecen solos en sus secciones del panel.
      if (galloQuitado != null && !_esBaseOComodin(galloQuitado)) {
        _gallosSueltos.add(galloQuitado);
      }

      final nuevaLista = <Enfrentamiento>[];
      for (int i = 0; i < ronda.enfrentamientos.length; i++) {
        if (i == enfIdx) {
          if (isGalloB) {
            // Deja galloB vacío
            nuevaLista.add(Enfrentamiento(
              id: enf.id,
              rondaNumero: enf.rondaNumero,
              galloA: enf.galloA,
              galloB: null,
              diferenciaPeso: 0,
            ));
          } else if (enf.galloB != null) {
            // Promueve galloB → galloA, deja galloB vacío
            nuevaLista.add(Enfrentamiento(
              id: enf.id,
              rondaNumero: enf.rondaNumero,
              galloA: enf.galloB!,
              galloB: null,
              diferenciaPeso: 0,
            ));
          }
          // Si ambos quedarían nulos → elimina el enfrentamiento
        } else {
          nuevaLista.add(ronda.enfrentamientos[i]);
        }
      }
      ronda.enfrentamientos.clear();
      ronda.enfrentamientos.addAll(nuevaLista);
    });
  }

  // ── Asignar gallo desde el panel lateral ─────────────

  void _asignarDesdePanel(
    Gallo gallo,
    int rondaDestinoIdx,
    int enfDestinoIdx,
    bool isGalloBDestino,
  ) {
    setState(() {
      _gallosSueltos.remove(gallo);
      final ronda = _rondas[rondaDestinoIdx];
      final enf = ronda.enfrentamientos[enfDestinoIdx];

      final desplazado = isGalloBDestino ? enf.galloB : enf.galloA;
      if (desplazado != null && !_esBaseOComodin(desplazado)) {
        _gallosSueltos.add(desplazado);
      }

      final nuevaLista = <Enfrentamiento>[];
      for (int i = 0; i < ronda.enfrentamientos.length; i++) {
        if (i == enfDestinoIdx) {
          final nuevoA = isGalloBDestino ? enf.galloA : gallo;
          final nuevoB = isGalloBDestino ? gallo : enf.galloB;
          nuevaLista.add(Enfrentamiento(
            id: enf.id,
            rondaNumero: enf.rondaNumero,
            galloA: nuevoA,
            galloB: nuevoB,
            diferenciaPeso:
                nuevoB != null ? nuevoA.diferenciaAbsoluta(nuevoB) : 0,
          ));
        } else {
          nuevaLista.add(ronda.enfrentamientos[i]);
        }
      }
      ronda.enfrentamientos.clear();
      ronda.enfrentamientos.addAll(nuevaLista);
    });
  }

  // ── Diálogo: agregar comodín ad-hoc ──────────────────

  Future<void> _mostrarDialogoAgregarComodin() async {
    final anilloCtrl = TextEditingController();
    final pesoCtrl = TextEditingController();

    // Modo: true = partido registrado, false = organizador
    bool esPartidoRegistrado = widget.partidos.isNotEmpty;
    Partido? partidoSeleccionado =
        widget.partidos.isNotEmpty ? widget.partidos.first : null;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A0A0E),
            title: const Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: Colors.lightBlue),
                SizedBox(width: 8),
                Text(
                  'Agregar Comodín',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Selector de origen ──────────────────
                  const Text(
                    'ORIGEN DEL GALLO',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogToggle(
                          label: 'Partido registrado',
                          icon: Icons.groups_rounded,
                          selected: esPartidoRegistrado,
                          onTap: () =>
                              setLocal(() => esPartidoRegistrado = true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _dialogToggle(
                          label: 'Organizador',
                          icon: Icons.person_rounded,
                          selected: !esPartidoRegistrado,
                          onTap: () =>
                              setLocal(() => esPartidoRegistrado = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ── Dropdown partido (si aplica) ─────────
                  if (esPartidoRegistrado) ...[
                    DropdownButtonFormField<Partido>(
                      value: partidoSeleccionado,
                      dropdownColor: const Color(0xFF2A1218),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDec('Partido proponente'),
                      items: widget.partidos
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.esComodin ? '${p.nombre} ★' : p.nombre,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setLocal(() => partidoSeleccionado = v),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue.withOpacity(0.08),
                        border: Border.all(color: Colors.lightBlue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.lightBlue, size: 14),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Se creará un partido "COMODÍN ORGANIZADOR" automáticamente.',
                              style: TextStyle(
                                  color: Colors.lightBlue, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // ── Campos anillo y peso ─────────────────
                  TextField(
                    controller: anilloCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('Anillo / identificador'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pesoCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _inputDec('Peso (gramos)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue.shade700),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmado != true || !mounted) return;

    final anillo = anilloCtrl.text.trim();
    final peso = double.tryParse(pesoCtrl.text.trim().replaceAll(',', '.'));

    if (anillo.isEmpty || peso == null || peso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Datos inválidos. Verifica anillo y peso.')),
      );
      return;
    }

    try {
      int partidoId;

      if (esPartidoRegistrado && partidoSeleccionado != null) {
        partidoId = partidoSeleccionado!.id;
      } else {
        // Obtener o crear partido "COMODÍN ORGANIZADOR"
        if (_organizadorPartidoId != null) {
          partidoId = _organizadorPartidoId!;
        } else {
          partidoId = await widget.partidoRepository.crear(
            derbyId: widget.derbyId,
            nombre: 'COMODÍN ORGANIZADOR',
            esComodin: true,
          );
          if (mounted) setState(() => _organizadorPartidoId = partidoId);
        }
      }

      final nuevoId = await widget.galloRepository.crear(
        partidoId: partidoId,
        anillo: anillo,
        pesoGramos: peso,
        esBase: false,
      );

      final nuevoGallo = Gallo(
        id: nuevoId,
        partidoId: partidoId,
        anillo: anillo,
        pesoGramos: peso,
        esBase: false,
      );

      if (mounted) setState(() => _gallosAdHoc.add(nuevoGallo));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar comodín: $e')),
        );
      }
    }
  }

  /// Botón de toggle para el diálogo de origen.
  Widget _dialogToggle({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.lightBlue.withOpacity(0.18)
              : Colors.transparent,
          border: Border.all(
            color: selected ? Colors.lightBlue : Colors.white24,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.lightBlue : Colors.white38, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.lightBlue : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Decoration reutilizable para TextFields del diálogo.
  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.lightBlue),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Manual de Sorteo'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'GUARDAR CAMBIOS',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              // Limpiar huecos nulos sin comprimir/eliminar rondas, 
              // para mantener la distribución manual (1 pelea por ronda cuando sea posible)
              final rondasLimpias = <Ronda>[];

              for (final ronda in _rondas) {
                // Eliminar enfrentamientos donde galloB es nulo (Huecos no llenados)
                final peleasCompletas = ronda.enfrentamientos
                    .where((e) => e.galloB != null)
                    .toList();

                final peleasFinales = <Enfrentamiento>[];
                for (final p in peleasCompletas) {
                  peleasFinales.add(
                    p.conResultado(p.resultado ?? ResultadoPelea.noPeleada),
                  );
                }

                rondasLimpias.add(Ronda(
                  numero: ronda.numero, // Mantenemos su número original (no subimos ni comprimimos)
                  enfrentamientos: peleasFinales,
                  esRondaBase: ronda.esRondaBase,
                  fechaCreacion: ronda.fechaCreacion,
                  partidosBye: ronda.partidosBye,
                  partidosDobles: ronda.partidosDobles,
                ));
              }

              Navigator.pop(context, rondasLimpias);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rondas.length,
              itemBuilder: (context, rondaIdx) {
                final ronda = _rondas[rondaIdx];
                return _buildRondaBoard(ronda, rondaIdx, cs);
              },
            ),
          ),
          _buildPanelLateral(cs),
        ],
      ),
    );
  }

  Widget _buildRondaBoard(Ronda ronda, int rondaIdx, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_mma, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'RONDA ${ronda.numero}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(ronda.enfrentamientos.length, (enfIdx) {
                final e = ronda.enfrentamientos[enfIdx];
                final flagError = _esInvalido(e);
                final diff = e.diferenciaPeso;

                return Container(
                  width: 340,
                  decoration: BoxDecoration(
                    color: flagError ? Colors.red.shade50 : Colors.white,
                    border: Border.all(
                      color: flagError
                          ? Colors.red.shade400
                          : Colors.grey.shade300,
                      width: flagError ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      if (flagError)
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDraggableGallo(
                            e.galloA,
                            rondaIdx,
                            enfIdx,
                            false,
                            cs,
                          ),
                          Text(
                            'VS',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          if (e.galloB != null)
                            _buildDraggableGallo(
                              e.galloB!,
                              rondaIdx,
                              enfIdx,
                              true,
                              cs,
                            )
                          else
                            DragTarget<Map<String, dynamic>>(
                              onWillAcceptWithDetails: (details) => true,
                              onAcceptWithDetails: (details) {
                                final data = details.data;
                                if (data['source'] == 'panel') {
                                  _asignarDesdePanel(
                                    data['gallo'] as Gallo,
                                    rondaIdx,
                                    enfIdx,
                                    true,
                                  );
                                } else {
                                  _intercambiarGallos(
                                    data['rondaIdx'],
                                    rondaIdx,
                                    data['enfIdx'],
                                    enfIdx,
                                    data['isGalloB'],
                                    true,
                                  );
                                }
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: candidateData.isNotEmpty ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.1),
                                    border: Border.all(
                                      color: candidateData.isNotEmpty ? Colors.blue : Colors.orange,
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "ESPACIO VACÍO\n(Arrastra aquí)",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: flagError
                              ? Colors.red.shade100
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Diferencia: ${diff.toStringAsFixed(0)}g',
                          style: TextStyle(
                            fontSize: 12,
                            color: flagError
                                ? Colors.red.shade900
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableGallo(
    Gallo gallo,
    int rondaIdx,
    int enfIdx,
    bool isGalloB,
    ColorScheme cs,
  ) {
    final Map<String, dynamic> dragData = {
      'source': 'ronda',
      'rondaIdx': rondaIdx,
      'enfIdx': enfIdx,
      'isGalloB': isGalloB,
    };

    final nombrePartido = widget.partidos
        .firstWhere(
          (p) => p.id == gallo.partidoId,
          orElse: () => const Partido(id: -1, nombre: '?'),
        )
        .nombre;

    final childWidget = Container(
      width: 130,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.primary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isGalloB ? cs.secondaryContainer : cs.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              gallo.anillo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isGalloB
                    ? cs.onSecondaryContainer
                    : cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${gallo.pesoGramos}g',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            nombrePartido,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['source'] == 'panel') return true;
        return data['rondaIdx'] == rondaIdx &&
                data['enfIdx'] == enfIdx &&
                data['isGalloB'] == isGalloB
            ? false
            : true;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data['source'] == 'panel') {
          _asignarDesdePanel(
            data['gallo'] as Gallo,
            rondaIdx,
            enfIdx,
            isGalloB,
          );
        } else {
          _intercambiarGallos(
            data['rondaIdx'],
            rondaIdx,
            data['enfIdx'],
            enfIdx,
            data['isGalloB'],
            isGalloB,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<Map<String, dynamic>>(
          data: dragData,
          feedback: Opacity(
            opacity: 0.8,
            child: Material(
              color: Colors.transparent,
              child: Transform.scale(scale: 1.05, child: childWidget),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: childWidget),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              candidateData.isNotEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: childWidget,
                    )
                  : childWidget,
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => _quitarGallo(rondaIdx, enfIdx, isGalloB),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  //  PANEL LATERAL DERECHO
  // ════════════════════════════════════════════════════

  Widget _buildPanelLateral(ColorScheme cs) {
    final base = _gallosBasePanel;
    final comodin = _gallosComodinPanel;
    final sueltos = _gallosSueltos;

    return Container(
      width: 264,
      decoration: const BoxDecoration(
        color: Color(0xFF12080C),
        border: Border(
          left: BorderSide(color: Color(0xFF3A1020), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            color: const Color(0xFF3A1020),
            child: const Row(
              children: [
                Icon(Icons.tune_rounded, color: Colors.white70, size: 15),
                SizedBox(width: 8),
                Text(
                  'BANCO DEL JUEZ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _panelSeccion('BASE', Icons.star_rounded, Colors.amber),
                if (base.isEmpty)
                  _panelVacio('Sin gallos base disponibles')
                else
                  ...base.map((g) => _buildChipGalloPanel(g)),
                const SizedBox(height: 14),
                _panelSeccion(
                  'COMODINES',
                  Icons.swap_horiz_rounded,
                  Colors.lightBlue,
                ),
                if (comodin.isEmpty)
                  _panelVacio('Sin comodines disponibles')
                else
                  ...comodin.map((g) => _buildChipGalloPanel(g)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _mostrarDialogoAgregarComodin,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.lightBlue.withOpacity(0.4),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.lightBlue, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'AGREGAR COMODÍN',
                          style: TextStyle(
                            color: Colors.lightBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _panelSeccion(
                  'SUELTOS',
                  Icons.inventory_2_outlined,
                  Colors.orange,
                ),
                if (sueltos.isEmpty)
                  _panelVacio('Gallos quitados de rondas')
                else
                  ...sueltos.map((g) => _buildChipGalloPanel(g)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelSeccion(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelVacio(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildChipGalloPanel(Gallo gallo) {
    final partido = widget.partidos.firstWhere(
      (p) => p.id == gallo.partidoId,
      orElse: () => const Partido(id: -1, nombre: '?'),
    );

    final dragData = <String, dynamic>{
      'source': 'panel',
      'gallo': gallo,
    };

    final chip = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF221018),
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gallo.anillo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  partido.nombre,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${gallo.pesoGramos.toStringAsFixed(0)}g',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    return Draggable<Map<String, dynamic>>(
      data: dragData,
      feedback: Opacity(
        opacity: 0.85,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(width: 230, child: chip),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }
}
