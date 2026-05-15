import 'package:flutter/material.dart';
import '../../main.dart' show derbyRepository;
import '../../data/database/app_database.dart';
import '../../core/security/secure_license_storage.dart';
import '../../core/security/license_manager.dart';
import 'derby_grid_screen.dart';
import 'derby_config_form_screen.dart';
import 'activation_screen.dart';

/// Pantalla principal: lista de derbys.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Derby> _derbys = [];
  bool _cargando = true;

  String? _licenseCode;
  DateTime? _expiryDate;
  int _daysRemaining = 0;

  @override
  void initState() {
    super.initState();
    _cargarDerbys();
    _loadLicenseInfo();
  }

  Future<void> _loadLicenseInfo() async {
    final code = await SecureLicenseStorage.getLicenseCode();
    final expiry = await SecureLicenseStorage.getExpiryDate();
    if (mounted && expiry != null) {
      setState(() {
        _licenseCode = code;
        _expiryDate = expiry;
        _daysRemaining = expiry.difference(DateTime.now()).inDays;
      });
    }
  }

  void _showLicenseInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: Colors.green),
            SizedBox(width: 8),
            Text('Información de Licencia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clave: ${_licenseCode ?? 'Desconocida'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Válida hasta: ${_expiryDate != null ? "${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}" : "N/A"}'),
            const SizedBox(height: 8),
            Text(
              'Tiempo restante: $_daysRemaining días',
              style: TextStyle(
                color: _daysRemaining > 30 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Desvincular Licencia', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('¿Desvincular Licencia?'),
                  content: const Text('Esto cerrará la aplicación y requerirá una nueva activación de licencia para volver a entrar. ¿Deseas continuar?'),
                  actions: [
                    TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(c, false)),
                    TextButton(child: const Text('Sí, desvincular', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(c, true)),
                  ],
                ),
              );
              if (confirm == true) {
                await LicenseManager.deactivate();
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ActivationScreen()),
                );
              }
            }
          ),
        ],
      ),
    );
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ActionChip(
              avatar: const Icon(Icons.security, size: 16, color: Colors.greenAccent),
              label: Text(
                _daysRemaining > 0 ? '$_daysRemaining días' : 'Evaluando...',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: _showLicenseInfo,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: Colors.green.withOpacity(0.5)),
            ),
          )
        ],
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
