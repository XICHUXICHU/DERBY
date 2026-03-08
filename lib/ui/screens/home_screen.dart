import 'package:flutter/material.dart';
import '../../main.dart' show derbyRepository;
import '../../data/database/app_database.dart';
import 'derby_grid_screen.dart';
import 'derby_config_form_screen.dart';

/// Pantalla principal: lista de derbys.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Derby> _derbys = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDerbys();
  }

  Future<void> _cargarDerbys() async {
    setState(() => _cargando = true);
    final derbys = await derbyRepository.listarTodos();
    setState(() {
      _derbys = derbys;
      _cargando = false;
    });
  }

  Future<void> _crearDerby() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const DerbyConfigFormScreen(),
      ),
    );
    if (ok == true) _cargarDerbys();
  }

  Future<void> _editarConfig(Derby derby) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DerbyConfigFormScreen(derbyExistente: derby),
      ),
    );
    if (ok == true) _cargarDerbys();
  }

  Future<void> _eliminarDerby(Derby derby) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
        title: const Text('Eliminar Derby'),
        content: Text(
          '¿Estás seguro de eliminar "${derby.nombre}"?\n\n'
          'Se eliminarán todos los partidos, gallos, rondas y '
          'enfrentamientos asociados. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await derbyRepository.eliminar(derby.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${derby.nombre}" eliminado')),
          );
        }
        _cargarDerbys();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Derby Manager'),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _derbys.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_mma,
                          size: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No hay derbys registrados',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Crea uno nuevo para comenzar'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _derbys.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (ctx, i) {
                    final derby = _derbys[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${derby.id}'),
                        ),
                        title: Text(derby.nombre),
                        subtitle: Text(
                          'Rondas: ${derby.rondasTotales} · '
                          'G=${derby.puntosVictoria} P=${derby.puntosDerrota} T=${derby.puntosEmpate} · '
                          '${derby.pesoMinimo.toStringAsFixed(0)}–${derby.pesoMaximo.toStringAsFixed(0)}g',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (derby.estado == 'configuracion')
                              IconButton(
                                icon: const Icon(Icons.settings),
                                tooltip: 'Editar configuración',
                                onPressed: () => _editarConfig(derby),
                              ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error),
                              tooltip: 'Eliminar derby',
                              onPressed: () => _eliminarDerby(derby),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DerbyGridScreen(derby: derby),
                            ),
                          ).then((_) => _cargarDerbys());
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearDerby,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Derby'),
      ),
    );
  }
}
