import 'package:flutter/material.dart';
import '../../main.dart' show partidoRepository, galloRepository;
import '../../data/database/app_database.dart';
import 'partido_form_screen.dart';

/// Pantalla de detalle de un derby: lista de partidos inscritos.
class DerbyDetailScreen extends StatefulWidget {
  final Derby derby;

  const DerbyDetailScreen({super.key, required this.derby});

  @override
  State<DerbyDetailScreen> createState() => _DerbyDetailScreenState();
}

class _DerbyDetailScreenState extends State<DerbyDetailScreen> {
  List<Partido> _partidos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPartidos();
  }

  Future<void> _cargarPartidos() async {
    setState(() => _cargando = true);
    final partidos =
        await partidoRepository.listarPorDerby(widget.derby.id);
    setState(() {
      _partidos = partidos;
      _cargando = false;
    });
  }

  Future<void> _agregarPartido() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PartidoFormScreen(derbyId: widget.derby.id),
      ),
    );
    if (resultado == true) {
      _cargarPartidos();
    }
  }

  Future<void> _editarPartido(Partido partido) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PartidoFormScreen(
          derbyId: widget.derby.id,
          partidoExistente: partido,
        ),
      ),
    );
    if (resultado == true) {
      _cargarPartidos();
    }
  }

  Future<void> _eliminarPartido(Partido partido) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar partido'),
        content: Text(
            '¿Eliminar "${partido.nombre}" y todos sus gallos? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await partidoRepository.eliminar(partido.id);
      _cargarPartidos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.derby.nombre),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _partidos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_add,
                          size: 80,
                          color: cs.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No hay partidos inscritos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Agrega partidos para comenzar el derby'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _partidos.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (ctx, i) {
                    final p = _partidos[i];
                    return _PartidoCard(
                      partido: p,
                      onTap: () => _editarPartido(p),
                      onDelete: () => _eliminarPartido(p),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarPartido,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Partido'),
      ),
      bottomNavigationBar: _partidos.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: cs.outlineVariant),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total partidos: ${_partidos.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Depósitos pagados: '
                    '${_partidos.where((p) => p.depositoPagado).length}'
                    '/${_partidos.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.primary,
                        ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Card de un partido con info resumida.
class _PartidoCard extends StatefulWidget {
  final Partido partido;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PartidoCard({
    required this.partido,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_PartidoCard> createState() => _PartidoCardState();
}

class _PartidoCardState extends State<_PartidoCard> {
  List<GalloEntry>? _gallos;

  @override
  void initState() {
    super.initState();
    _cargarGallos();
  }

  @override
  void didUpdateWidget(covariant _PartidoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partido.id != widget.partido.id) {
      _cargarGallos();
    }
  }

  Future<void> _cargarGallos() async {
    final gallos =
        await galloRepository.listarPorPartido(widget.partido.id);
    if (mounted) setState(() => _gallos = gallos);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.partido;
    final cs = Theme.of(context).colorScheme;

    final galloBase = _gallos?.where((g) => g.esBase).firstOrNull;
    final gallosPL = _gallos?.where((g) => !g.esBase).toList() ?? [];

    return Card(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: nombre + estado depósito
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (p.depositoPagado)
                    Chip(
                      avatar: Icon(Icons.check_circle,
                          size: 16, color: cs.primary),
                      label: Text(
                        '\$${p.depositoCantidad.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12, color: cs.primary),
                      ),
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  else
                    Chip(
                      avatar:
                          Icon(Icons.warning_amber, size: 16, color: cs.error),
                      label: Text(
                        'Sin pagar',
                        style: TextStyle(fontSize: 12, color: cs.error),
                      ),
                      side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: cs.error),
                    onPressed: widget.onDelete,
                    tooltip: 'Eliminar partido',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Gallos
              if (_gallos == null)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                // Gallo base
                _GalloChip(
                  label: 'BASE',
                  anillo: galloBase?.anillo,
                  peso: galloBase?.pesoGramos,
                  color: cs.tertiary,
                ),
                const SizedBox(height: 4),
                // Gallos P.L.
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: List.generate(3, (idx) {
                    final g = idx < gallosPL.length ? gallosPL[idx] : null;
                    return _GalloChip(
                      label: 'P.L. ${idx + 1}',
                      anillo: g?.anillo,
                      peso: g?.pesoGramos,
                      color: cs.secondary,
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip que muestra la info de un gallo.
class _GalloChip extends StatelessWidget {
  final String label;
  final String? anillo;
  final double? peso;
  final Color color;

  const _GalloChip({
    required this.label,
    this.anillo,
    this.peso,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tiene = anillo != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          tiene ? '$anillo · ${peso?.toStringAsFixed(0)}g' : '— sin asignar',
          style: TextStyle(
            fontSize: 13,
            color: tiene
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
