import 'package:flutter/material.dart';
import '../../main.dart'
    show
        partidoRepository,
        galloRepository,
        compadresRepository,
        derbyRepository,
        rondaRepository;
import '../../data/database/app_database.dart';
import '../../domain/domain.dart' as domain;
import '../../engine/derby_engine.dart';
import '../../application/usecases/generar_sorteo.dart';
import '../reports/reporte_anillos_pdf.dart';
import '../reports/reporte_estilo_pdf.dart';
import 'partido_form_screen.dart';
import 'derby_peleas_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  Constantes de estilo – replica el diseño de la imagen
// ═══════════════════════════════════════════════════════════════

const _kHeaderBg = Color(0xFF6B1C2A); // vino oscuro (header + # col)
const _kRowHeight = 74.0;
const _kHeaderHeight = 46.0;

/// Paleta de colores asignados a cada partido (chips de gallos).
const _kPartyColors = [
  Color(0xFF8B2131), // vino
  Color(0xFF1B5E20), // verde bosque
  Color(0xFF0D47A1), // azul real
  Color(0xFF6A1B9A), // púrpura
  Color(0xFFBF360C), // naranja quemado
  Color(0xFF00695C), // teal
  Color(0xFF4E342E), // café
  Color(0xFF37474F), // gris azulado
  Color(0xFFC62828), // rojo
  Color(0xFF2E7D32), // verde
  Color(0xFF283593), // índigo
  Color(0xFF558B2F), // verde lima
];

// Anchos de columna
const _kColNum = 42.0;
const _kColPartido = 210.0;
const _kColGallo = 142.0;
const _kColResult = 56.0;
const _kColPts = 58.0;
const _kColCompadre = 52.0;

double get _kTotalWidth =>
    _kColNum +
    _kColPartido +
    4 * _kColGallo +
    _kColCompadre +
    4 * _kColResult +
    _kColPts;

// ═══════════════════════════════════════════════════════════════
//  Modelo interno para agrupar partido + gallos
// ═══════════════════════════════════════════════════════════════

class _PartidoRow {
  final Partido partido;
  final GalloEntry? galloBase;
  final List<GalloEntry> gallosPL;

  _PartidoRow({required this.partido, this.galloBase, required this.gallosPL});
}

// ═══════════════════════════════════════════════════════════════
//  Pantalla principal – Grilla del Derby
// ═══════════════════════════════════════════════════════════════

class DerbyGridScreen extends StatefulWidget {
  final Derby derby;

  const DerbyGridScreen({super.key, required this.derby});

  @override
  State<DerbyGridScreen> createState() => _DerbyGridScreenState();
}

class _DerbyGridScreenState extends State<DerbyGridScreen> {
  List<_PartidoRow> _rows = [];
  bool _cargando = true;

  /// Mapa: partidoId → set de ids de sus compadres.
  Map<int, Set<int>> _compadresMap = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ── Carga de datos ─────────────────────────────────────

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    final partidos = await partidoRepository.listarPorDerby(widget.derby.id);
    final gallos = await galloRepository.listarPorDerby(widget.derby.id);
    final compadresList = await compadresRepository.listarPorDerby(
      widget.derby.id,
    );

    // Construir mapa bidireccional de compadres
    final cMap = <int, Set<int>>{};
    for (final c in compadresList) {
      cMap.putIfAbsent(c.partidoIdA, () => {}).add(c.partidoIdB);
      cMap.putIfAbsent(c.partidoIdB, () => {}).add(c.partidoIdA);
    }

    final mapa = <int, List<GalloEntry>>{};
    for (final g in gallos) {
      mapa.putIfAbsent(g.partidoId, () => []).add(g);
    }

    setState(() {
      _compadresMap = cMap;
      _rows = partidos.map((p) {
        final list = mapa[p.id] ?? [];
        return _PartidoRow(
          partido: p,
          galloBase: list.where((g) => g.esBase).firstOrNull,
          gallosPL: list.where((g) => !g.esBase).toList(),
        );
      }).toList();
      _cargando = false;
    });
  }

  // ── Acciones (agregar / editar / eliminar) ─────────────

  Future<void> _agregarPartido() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PartidoFormScreen(derbyId: widget.derby.id),
      ),
    );
    if (ok == true) _cargarDatos();
  }

  Future<void> _editarPartido(Partido p) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PartidoFormScreen(derbyId: widget.derby.id, partidoExistente: p),
      ),
    );
    if (ok == true) _cargarDatos();
  }

  Future<void> _eliminarPartido(Partido p) async {
    final gallos = await galloRepository.listarPorPartido(p.id);
    final compadres = _compadresMap[p.id] ?? {};
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: cs.error, size: 36),
          title: const Text('Eliminar partido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Eliminar "${p.nombre}"?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Se eliminará permanentemente:',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              _deleteInfoRow(Icons.sports_mma, '${gallos.length} gallo(s)', cs),
              if (compadres.isNotEmpty)
                _deleteInfoRow(
                  Icons.people,
                  '${compadres.length} relación(es) de compadre',
                  cs,
                ),
              _deleteInfoRow(Icons.event_note, 'Enfrentamientos asociados', cs),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: cs.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer.',
                        style: TextStyle(fontSize: 12, color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Eliminar'),
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await partidoRepository.eliminar(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partido "${p.nombre}" eliminado'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      _cargarDatos();
    }
  }

  Widget _deleteInfoRow(IconData icon, String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.error),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: cs.onSurface)),
        ],
      ),
    );
  }

  // ── Reporte PDF ──────────────────────────────────────

  void _imprimirReporte(String opcion) {
    // Construir mapa de gallos por partido (reutiliza _rows)
    final partidos = _rows.map((r) => r.partido).toList();
    final gallosPorPartido = <int, List<GalloEntry>>{};
    for (final r in _rows) {
      final list = <GalloEntry>[];
      if (r.galloBase != null) list.add(r.galloBase!);
      list.addAll(r.gallosPL);
      gallosPorPartido[r.partido.id] = list;
    }

    final reporte = ReporteAnillosPdf(
      nombreDerby: widget.derby.nombre,
      fecha: DateTime.now(),
      partidos: partidos,
      gallosPorPartido: gallosPorPartido,
    );

    switch (opcion) {
      case 'preview_datos':
        reporte.vistaPrevia(context, ModoReporte.conDatos);
        break;
      case 'preview_limpio':
        reporte.vistaPrevia(context, ModoReporte.limpio);
        break;
      case 'print_datos':
        reporte.imprimir(context, ModoReporte.conDatos);
        break;
      case 'print_limpio':
        reporte.imprimir(context, ModoReporte.limpio);
        break;
    }
  }

  void _showContextMenu(Offset globalPos, Partido p) {
    final size = MediaQuery.sizeOf(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        size.width - globalPos.dx,
        size.height - globalPos.dy,
      ),
      items: const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Editar'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Eliminar'),
            dense: true,
          ),
        ),
      ],
    ).then((val) {
      if (val == 'edit') _editarPartido(p);
      if (val == 'delete') _eliminarPartido(p);
    });
  }

  // ── Sorteo ─────────────────────────────────────────────

  /// Guarda las rondas generadas por el sorteo en la BD.
  Future<void> _guardarSorteo(List<domain.Ronda> rondas) async {
    try {
      // Eliminar rondas previas (si re-generamos)
      final rondasPrevias = await rondaRepository.listarPorDerby(
        widget.derby.id,
      );
      if (rondasPrevias.isNotEmpty) {
        // Confirmar sobrescribir
        if (!mounted) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(
              Icons.warning_amber,
              color: Colors.orange,
              size: 40,
            ),
            title: const Text('Sorteo existente'),
            content: const Text(
              'Ya existen rondas guardadas. ¿Deseas reemplazarlas?\n'
              'Se perderán todos los resultados de peleas registrados.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Reemplazar'),
              ),
            ],
          ),
        );
        if (ok != true || !mounted) return;

        // Eliminar rondas anteriores
        await rondaRepository.eliminarPorDerby(widget.derby.id);
      }

      // Guardar nuevas rondas
      for (final ronda in rondas) {
        await rondaRepository.crearRondaConEnfrentamientos(
          derbyId: widget.derby.id,
          numero: ronda.numero,
          esRondaBase: ronda.esRondaBase,
          enfrentamientos: ronda.enfrentamientos,
          partidosBye: ronda.partidosBye,
          partidosDobles: ronda.partidosDobles,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Sorteo guardado correctamente'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Ejecuta el sorteo completo y muestra resultados / PDF.
  Future<void> _ejecutarSorteo() async {
    // 1. Cargar datos frescos de la base
    final partidos = await partidoRepository.listarPorDerby(widget.derby.id);
    final galloEntries = await galloRepository.listarPorDerby(widget.derby.id);
    final compadreEntries = await compadresRepository.listarPorDerby(
      widget.derby.id,
    );
    final derbyData = await derbyRepository.obtenerPorId(widget.derby.id);
    if (derbyData == null || !mounted) return;

    // 2. Convertir a entidades de dominio
    final domPartidos = partidos
        .map(
          (p) => domain.Partido(
            id: p.id,
            nombre: p.nombre,
            responsable: p.responsable,
            telefono: p.telefono,
            puntos: p.puntos,
            eliminado: p.eliminado,
            depositoPagado: p.depositoPagado,
            depositoCantidad: p.depositoCantidad,
            esComodin: p.esComodin,
          ),
        )
        .toList();

    final domGallos = galloEntries
        .map(
          (g) => domain.Gallo(
            id: g.id,
            partidoId: g.partidoId,
            anillo: g.anillo,
            pesoGramos: g.pesoGramos,
            esBase: g.esBase,
            color: g.color,
            observaciones: g.observaciones,
          ),
        )
        .toList();

    final domCompadres = compadreEntries
        .map(
          (c) => domain.Compadres(
            id: c.id,
            partidoIdA: c.partidoIdA,
            partidoIdB: c.partidoIdB,
            motivo: c.motivo,
          ),
        )
        .toList();

    // 3. Construir config
    final config = DerbyConfig(
      rondasTotales: derbyData.rondasTotales,
      puntosVictoria: derbyData.puntosVictoria,
      puntosEmpate: derbyData.puntosEmpate,
      puntosDerrota: derbyData.puntosDerrota,
      pesoMinimo: derbyData.pesoMinimo,
      pesoMaximo: derbyData.pesoMaximo,
      pesoGalloBase: derbyData.pesoGalloBase,
      permitirRepeticiones: derbyData.permitirRepeticiones,
      diferenciaMaxPeso: derbyData.diferenciaMaxPeso,
      validacionEstricta: derbyData.validacionEstricta,
    );

    // ── DEBUG LOGS ──
    print('\n════════════════════════════════════════════');
    print('🎯 SORTEO DEBUG - Derby: ${derbyData.nombre}');
    print('════════════════════════════════════════════');
    print(
      'Config: rondas=${config.rondasTotales}, diffMaxPeso=${config.diferenciaMaxPeso}g',
    );
    print(
      '  pesoMin=${config.pesoMinimo}g, pesoMax=${config.pesoMaximo}g, pesoBase=${config.pesoGalloBase}g',
    );
    print(
      '  estricta=${config.validacionEstricta}, repeticiones=${config.permitirRepeticiones}',
    );
    print(
      'Partidos: ${domPartidos.length} (${domPartidos.length.isOdd ? "IMPAR" : "par"})',
    );
    for (final p in domPartidos) {
      final gs = domGallos.where((g) => g.partidoId == p.id).toList();
      final bases = gs
          .where((g) => g.esBase)
          .map((g) => '${g.anillo}(${g.pesoGramos}g)');
      final libres = gs
          .where((g) => !g.esBase)
          .map((g) => '${g.anillo}(${g.pesoGramos}g)');
      print(
        '  [${p.id}] ${p.nombre}: base=[${bases.join(", ")}] PL=[${libres.join(", ")}]',
      );
    }
    print('Compadres: ${domCompadres.length}');
    for (final c in domCompadres) {
      final motivo = c.motivo ?? '';
      print('  ${c.partidoIdA} \u2194 ${c.partidoIdB} ($motivo)');
    }
    print('────────────────────────────────────────────');

    final engine = DerbyEngine(config: config, compadres: domCompadres);
    final sorteo = GenerarSorteo(engine);

    // 4. Validar
    final errores = sorteo.validar(partidos: domPartidos, gallos: domGallos);
    final validMsg = errores.isEmpty
        ? 'OK (0 errores)'
        : '${errores.length} error(es)';
    print('Validacion: $validMsg');
    for (final e in errores) {
      print('  ❌ $e');
    }
    if (errores.isNotEmpty && mounted) {
      if (config.validacionEstricta) {
        print('⛔ BLOQUEADO por validación estricta. No se ejecuta sorteo.');
        _mostrarErroresSorteo(errores);
        return;
      }
      // Modo flexible: mostrar advertencias y continuar
      final continuar = await _mostrarAdvertenciasSorteo(errores);
      if (continuar != true || !mounted) return;
    }

    // 5. Ejecutar sorteo
    //    PAR  → todas las rondas de golpe (no hay problema de impar).
    //    IMPAR → solo primer bloque (rondas 1-2). Las posteriores se
    //            generan desde la pantalla de peleas tras registrar
    //            resultados, para evaluar eliminación → comodín/BYE.
    final esImpar = domPartidos.where((p) =>
        p.estado == domain.EstadoPartido.activo && !p.eliminado && !p.esComodin
    ).length.isOdd;
    print('🚀 Ejecutando sorteo (${esImpar ? "impar → primer bloque" : "par → todas"})...');
    try {
      final List<domain.Ronda> rondas;
      if (esImpar) {
        rondas = sorteo.ejecutarPrimerBloque(
          partidos: domPartidos,
          gallos: domGallos,
          compadres: domCompadres,
        );
      } else {
        rondas = sorteo.ejecutarTodas(
          partidos: domPartidos,
          gallos: domGallos,
          compadres: domCompadres,
        );
      }

      print('✅ Sorteo completado: ${rondas.length} rondas generadas');
      for (final r in rondas) {
        print(
          '  Ronda ${r.numero}: ${r.enfrentamientos.length} peleas, bye=${r.partidosBye}, doble=${r.partidosDobles}',
        );
      }

      final resultado = sorteo.construirResultadoVisual(
        nombreDerby: derbyData.nombre,
        partidos: domPartidos,
        rondas: rondas,
        compadres: domCompadres,
      );

      if (!mounted) return;
      _mostrarResultadoSorteo(resultado, rondas);
    } on domain.DerbyException catch (e) {
      print('❌ DerbyException: ${e.mensaje}');
      if (!mounted) return;
      _mostrarErroresSorteo([e.mensaje]);
    } catch (e, st) {
      print('❌ Error inesperado: $e');
      print('Stack trace: $st');
      if (!mounted) return;
      _mostrarErroresSorteo(['Error inesperado: $e']);
    }
  }

  void _mostrarErroresSorteo(List<String> errores) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        title: const Text('No se puede generar el sorteo'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errores
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red)),
                        Expanded(child: Text(e)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _mostrarAdvertenciasSorteo(List<String> advertencias) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 40),
        title: const Text('Advertencias del sorteo'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Se encontraron los siguientes problemas:'),
              const SizedBox(height: 8),
              ...advertencias.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠ ', style: TextStyle(color: Colors.orange)),
                      Expanded(
                        child: Text(e, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Deseas continuar de todos modos?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _mostrarResultadoSorteo(
    domain.SorteoResultado resultado,
    List<domain.Ronda> rondas,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.check_circle, color: cs.primary, size: 40),
          title: const Text('Sorteo generado correctamente'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statChip(
                        Icons.groups,
                        '${resultado.partidos.length}',
                        'Partidos',
                        cs,
                      ),
                      _statChip(
                        Icons.repeat,
                        '${resultado.rondasGeneradas}',
                        'Rondas',
                        cs,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    itemCount: resultado.partidos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final pr = resultado.partidos[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            '${pr.fila}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                pr.nombrePartido,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (pr.compadresFilas.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  '⇄ ${pr.compadresFilas.map((f) => '#$f').join(', ')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          pr.rondas
                              .map((r) {
                                if (r.esBye) return 'R${r.numeroRonda}: BYE';
                                final prefix = r.esDoble ? '×2 ' : '';
                                return 'R${r.numeroRonda}: $prefix${r.anilloPropio} vs ${r.anilloRival}';
                              })
                              .join('  |  '),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
                if (resultado.advertencias.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${resultado.advertencias.length} advertencia(s)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Vista previa'),
              onPressed: () {
                Navigator.pop(ctx);
                ReporteEstiloPdf(sorteo: resultado).vistaPrevia(context);
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Guardar Sorteo'),
              onPressed: () async {
                Navigator.pop(ctx);
                await _guardarSorteo(rondas);
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.print, size: 18),
              label: const Text('Imprimir'),
              onPressed: () {
                Navigator.pop(ctx);
                ReporteEstiloPdf(sorteo: resultado).imprimir(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _statChip(IconData icon, String value, String label, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  // ── Build principal ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pagados = _rows.where((r) => r.partido.depositoPagado).length;
    final total = _rows.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.derby.nombre),
        centerTitle: true,
        actions: [
          if (!_cargando && _rows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '$total partidos  ·  $pagados dep. pagados',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          if (!_cargando && _rows.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.sports_mma),
              tooltip: 'Registro de Peleas',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DerbyPeleasScreen(derby: widget.derby),
                  ),
                );
                _cargarDatos();
              },
            ),
          if (!_cargando && _rows.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.shuffle),
              tooltip: 'Generar Sorteo',
              onPressed: _ejecutarSorteo,
            ),
          if (!_cargando && _rows.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.print),
              tooltip: 'Imprimir hoja de anillos',
              onSelected: (val) => _imprimirReporte(val),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'preview_datos',
                  child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('Vista previa con datos'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'preview_limpio',
                  child: ListTile(
                    leading: Icon(Icons.visibility_outlined),
                    title: Text('Vista previa formato limpio'),
                    dense: true,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'print_datos',
                  child: ListTile(
                    leading: Icon(Icons.print),
                    title: Text('Imprimir con datos'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'print_limpio',
                  child: ListTile(
                    leading: Icon(Icons.print_outlined),
                    title: Text('Imprimir formato limpio'),
                    dense: true,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
          ? _buildEmpty(cs)
          : _buildGrid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarPartido,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Partido'),
      ),
    );
  }

  // ── Estado vacío ───────────────────────────────────────

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.grid_on,
            size: 80,
            color: cs.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay partidos inscritos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Agrega partidos para ver la grilla'),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  GRILLA
  // ═════════════════════════════════════════════════════════

  Widget _buildGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _kTotalWidth,
        child: Column(
          children: [
            // Header fijo vertical, scrollea horizontal
            _buildHeader(),
            // Filas scrolleables vertical
            Expanded(
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (_, i) => _buildRow(i),
              ),
            ),
            // Barra de resumen
            _buildSummaryBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: _kHeaderHeight,
      decoration: const BoxDecoration(
        color: _kHeaderBg,
        border: Border(bottom: BorderSide(color: Colors.white24, width: 1.5)),
      ),
      child: Row(
        children: [
          _hCell('#', _kColNum),
          _hCell('PARTIDO', _kColPartido),
          _hCell('GALLO BASE', _kColGallo),
          _hCell('GALLO 1 P.L.', _kColGallo),
          _hCell('GALLO 2 P.L.', _kColGallo),
          _hCell('GALLO 3 P.L.', _kColGallo),
          _hCell('', _kColCompadre),
          _hCell('R1', _kColResult),
          _hCell('R2', _kColResult),
          _hCell('R3', _kColResult),
          _hCell('R4', _kColResult),
          _hCell('PTS', _kColPts),
        ],
      ),
    );
  }

  Widget _hCell(String text, double w) {
    return SizedBox(
      width: w,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11.5,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ── Fila de datos ──────────────────────────────────────

  Widget _buildRow(int index) {
    final data = _rows[index];
    final p = data.partido;
    final partyColor = _kPartyColors[index % _kPartyColors.length];
    final isOdd = index.isOdd;

    return GestureDetector(
      onSecondaryTapDown: (d) => _showContextMenu(d.globalPosition, p),
      child: Material(
        color: isOdd
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.transparent,
        child: InkWell(
          onTap: () => _editarPartido(p),
          child: Container(
            height: _kRowHeight,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // # ─ número de fila
                _numCell(index + 1),
                // PARTIDO ─ nombre + indicador depósito
                _partidoCell(p),
                // GALLOS ─ base + 3 PL
                _galloCell(data.galloBase, partyColor),
                _galloCell(
                  data.gallosPL.isNotEmpty ? data.gallosPL[0] : null,
                  partyColor,
                ),
                _galloCell(
                  data.gallosPL.length > 1 ? data.gallosPL[1] : null,
                  partyColor,
                ),
                _galloCell(
                  data.gallosPL.length > 2 ? data.gallosPL[2] : null,
                  partyColor,
                ),
                // Compadres
                _compadreCell(data.partido),
                // R1 – R4 (sin resultados aún)
                _resultBadge(null),
                _resultBadge(null),
                _resultBadge(null),
                _resultBadge(null),
                // PTS
                _ptsCell(p.puntos),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Barra de resumen inferior ──────────────────────────

  Widget _buildSummaryBar() {
    final cs = Theme.of(context).colorScheme;
    final pagados = _rows.where((r) => r.partido.depositoPagado).length;
    final montoTotal = _rows.fold<double>(
      0,
      (sum, r) =>
          sum + (r.partido.depositoPagado ? r.partido.depositoCantidad : 0),
    );

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: const Border(top: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _kColNum + _kColPartido,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Total: ${_rows.length} partidos',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Depósitos: $pagados/${_rows.length} pagados'
                '  ·  \$${montoTotal.toStringAsFixed(0)} recaudado',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  CELDAS INDIVIDUALES
  // ═════════════════════════════════════════════════════════

  /// Celda de número de fila — fondo vino como el header.
  Widget _numCell(int n) {
    return Container(
      width: _kColNum,
      color: _kHeaderBg,
      child: Center(
        child: Text(
          '$n',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// Celda de nombre del partido + indicador depósito.
  Widget _partidoCell(Partido p) {
    return SizedBox(
      width: _kColPartido,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                p.nombre.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: p.depositoPagado
                  ? 'Depósito pagado: \$${p.depositoCantidad.toStringAsFixed(0)}'
                  : 'Depósito pendiente',
              child: Icon(
                p.depositoPagado
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                size: 18,
                color: p.depositoPagado
                    ? Colors.green.shade400
                    : Colors.orange.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Celda de gallo — chip coloreado con anillo + peso.
  Widget _galloCell(GalloEntry? g, Color partyColor) {
    if (g == null) {
      return SizedBox(
        width: _kColGallo,
        child: Center(
          child: Text(
            '—',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 18),
          ),
        ),
      );
    }

    return SizedBox(
      width: _kColGallo,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chip con anillo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: partyColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              g.anillo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Peso
          Text(
            '${g.pesoGramos.toStringAsFixed(0)}g',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  /// Celda con botón de compadres — muestra ícono + conteo.
  Widget _compadreCell(Partido p) {
    final count = _compadresMap[p.id]?.length ?? 0;

    return SizedBox(
      width: _kColCompadre,
      child: Center(
        child: Tooltip(
          message: count > 0
              ? '$count compadre${count > 1 ? 's' : ''}'
              : 'Asignar compadres',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _mostrarCompadresDialog(p),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  size: 26,
                  color: count > 0
                      ? const Color(0xFFFF8F00)
                      : Colors.grey.shade600,
                ),
                if (count > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF8F00),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Diálogo para gestionar compadres de un partido.
  Future<void> _mostrarCompadresDialog(Partido partido) async {
    // IDs actuales de compadres de este partido
    final compadresActuales = Set<int>.from(_compadresMap[partido.id] ?? {});
    // Todos los otros partidos
    final otros = _rows.where((r) => r.partido.id != partido.id).toList();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CompadresDialog(
        partido: partido,
        derbyId: widget.derby.id,
        otrosPartidos: otros.map((r) => r.partido).toList(),
        compadresIniciales: compadresActuales,
      ),
    );
    if (result == true) _cargarDatos();
  }

  /// Badge de resultado: G (verde), P (rojo), ? (azul outline).
  Widget _resultBadge(String? result) {
    final Color borderColor;
    final Color? fillColor;
    final Color textColor;
    final String text;

    switch (result) {
      case 'G':
        fillColor = const Color(0xFF2E7D32);
        borderColor = const Color(0xFF2E7D32);
        textColor = Colors.white;
        text = 'G';
      case 'P':
        fillColor = const Color(0xFFC62828);
        borderColor = const Color(0xFFC62828);
        textColor = Colors.white;
        text = 'P';
      default:
        fillColor = null;
        borderColor = const Color(0xFF1976D2);
        textColor = const Color(0xFF1976D2);
        text = '?';
    }

    return SizedBox(
      width: _kColResult,
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Celda de puntos totales.
  Widget _ptsCell(int pts) {
    return SizedBox(
      width: _kColPts,
      child: Center(
        child: Text(
          '$pts',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Diálogo para gestionar compadres
// ═══════════════════════════════════════════════════════════════

class _CompadresDialog extends StatefulWidget {
  final Partido partido;
  final int derbyId;
  final List<Partido> otrosPartidos;
  final Set<int> compadresIniciales;

  const _CompadresDialog({
    required this.partido,
    required this.derbyId,
    required this.otrosPartidos,
    required this.compadresIniciales,
  });

  @override
  State<_CompadresDialog> createState() => _CompadresDialogState();
}

class _CompadresDialogState extends State<_CompadresDialog> {
  late Set<int> _seleccionados;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _seleccionados = Set<int>.from(widget.compadresIniciales);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);

    try {
      // Obtener relaciones actuales del derby
      final existentes = await compadresRepository.listarPorDerby(
        widget.derbyId,
      );

      // Filtrar las que involucran a este partido
      final propias = existentes.where(
        (c) =>
            c.partidoIdA == widget.partido.id ||
            c.partidoIdB == widget.partido.id,
      );

      // Eliminar las que ya no están seleccionadas
      for (final c in propias) {
        final otroId = c.partidoIdA == widget.partido.id
            ? c.partidoIdB
            : c.partidoIdA;
        if (!_seleccionados.contains(otroId)) {
          await compadresRepository.eliminar(c.id);
        }
      }

      // IDs que ya existían
      final yaExisten = propias
          .map(
            (c) =>
                c.partidoIdA == widget.partido.id ? c.partidoIdB : c.partidoIdA,
          )
          .toSet();

      // Crear las nuevas
      for (final id in _seleccionados) {
        if (!yaExisten.contains(id)) {
          await compadresRepository.crear(
            derbyId: widget.derbyId,
            partidoIdA: widget.partido.id,
            partidoIdB: id,
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.people_alt_rounded,
            color: Color(0xFFFF8F00),
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Compadres', style: TextStyle(fontSize: 18)),
                Text(
                  widget.partido.nombre.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFFFF8F00)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los compadres nunca se enfrentarán entre sí '
                      'durante el derby.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona los partidos compadres:',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: widget.otrosPartidos.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No hay otros partidos registrados'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.otrosPartidos.length,
                      itemBuilder: (_, i) {
                        final otro = widget.otrosPartidos[i];
                        final selected = _seleccionados.contains(otro.id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _seleccionados.add(otro.id);
                              } else {
                                _seleccionados.remove(otro.id);
                              }
                            });
                          },
                          title: Text(
                            otro.nombre.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: selected ? const Color(0xFFFF8F00) : null,
                            ),
                          ),
                          secondary: Icon(
                            selected ? Icons.handshake : Icons.person_outline,
                            color: selected
                                ? const Color(0xFFFF8F00)
                                : Colors.grey,
                          ),
                          activeColor: const Color(0xFFFF8F00),
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _guardando ? null : _guardar,
          icon: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text('Guardar (${_seleccionados.length})'),
        ),
      ],
    );
  }
}
