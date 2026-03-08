import 'package:flutter/material.dart';
import '../../main.dart'
    show
        partidoRepository,
        rondaRepository,
        derbyRepository,
        galloRepository,
        compadresRepository;
import '../../data/database/app_database.dart' show Derby;
import '../../domain/domain.dart' as domain;
import '../../application/usecases/generar_sorteo.dart';
import '../../engine/derby_engine.dart';
import '../reports/reporte_resultados_pdf.dart';
import '../reports/reporte_ronda_sorteo_pdf.dart';

// ═══════════════════════════════════════════════════════════════
//  Constantes de estilo – Premium SaaS Dashboard
// ═══════════════════════════════════════════════════════════════

// -- Paleta profesional --
const _kBgCanvas = Color(0xFFF3F4F6); // fondo general gris muy claro
const _kCardBg = Color(0xFFFFFFFF); // cards blancas
const _kAccent = Color(0xFF6B1C2A); // vino institucional
const _kAccentLight = Color(0xFFFBECEF); // vino 5%

// Resultados
const _kGreen = Color(0xFF16A34A); // verde elegante
const _kGreenBg = Color(0xFFDCFCE7); // verde fondo chip
const _kRed = Color(0xFFDC2626); // rojo elegante
const _kRedBg = Color(0xFFFEE2E2); // rojo fondo chip
const _kAmber = Color(0xFFF59E0B); // ámbar tablas
const _kAmberBg = Color(0xFFFEF3C7); // ámbar fondo chip
const _kBlue = Color(0xFF2563EB); // azul institucional
const _kBlueBg = Color(0xFFDBEAFE); // azul fondo
const _kGrey = Color(0xFF6B7280); // gris neutro
const _kGreyBg = Color(0xFFF3F4F6);

// Texto
const _kTextPrimary = Color(0xFF111827); // casi negro
const _kTextSecondary = Color(0xFF6B7280); // gris medio
const _kTextTertiary = Color(0xFF9CA3AF); // gris claro
const _kDivider = Color(0xFFE5E7EB); // separadores

// Sombra reutilizable — contraste suficiente en Windows
const _kCardShadow = [
  BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
];

/// Paleta de colores asignados a cada partido.
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

// ═══════════════════════════════════════════════════════════════
//  Modelo interno: fila de la tabla
// ═══════════════════════════════════════════════════════════════

class _PeleaRow {
  final domain.Partido partido;
  int puntos;
  int posicion;

  /// Resultado por ronda: null = sin pelea, 'G', 'P', 'T', 'BYE', 'NP', '?'
  final List<String?> resultados;

  _PeleaRow({
    required this.partido,
    required this.puntos,
    required this.posicion,
    required this.resultados,
  });
}

// ═══════════════════════════════════════════════════════════════
//  Pantalla: Registro de Peleas
// ═══════════════════════════════════════════════════════════════

class DerbyPeleasScreen extends StatefulWidget {
  final Derby derby;

  const DerbyPeleasScreen({super.key, required this.derby});

  @override
  State<DerbyPeleasScreen> createState() => _DerbyPeleasScreenState();
}

class _DerbyPeleasScreenState extends State<DerbyPeleasScreen> {
  bool _cargando = true;
  List<_PeleaRow> _rows = [];
  List<domain.Ronda> _rondas = [];
  List<domain.Partido> _partidos = [];
  int _rondasTotales = 4;
  int _puntosVictoria = 2;
  int _puntosEmpate = 1;
  int _puntosDerrota = 0;

  /// Mapa: (partidoId, rondaNumero) -> enfrentamientoId
  final Map<(int, int), int> _enfrentamientoMap = {};

  /// Mapa: (partidoId, rondaNumero) -> info completa del enfrentamiento(s)
  final Map<(int, int), List<_EnfrentamientoInfo>> _infoMap = {};

  /// Partidos que tienen BYE por ronda
  final Map<int, Set<int>> _byesPorRonda = {};

  /// Partidos que tienen doble pelea por ronda
  final Map<int, Set<int>> _doblesPorRonda = {};

  /// Mapa: partidoId -> color asignado
  final Map<int, Color> _colorMap = {};

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ── Carga de datos ─────────────────────────────────────

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    final derbyData = await derbyRepository.obtenerPorId(widget.derby.id);
    if (derbyData == null || !mounted) return;

    _rondasTotales = derbyData.rondasTotales;
    _puntosVictoria = derbyData.puntosVictoria;
    _puntosEmpate = derbyData.puntosEmpate;
    _puntosDerrota = derbyData.puntosDerrota;

    final partidosDb = await partidoRepository.listarPorDerby(widget.derby.id);
    _partidos = partidosDb
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

    // Asignar colores estables por partido (orden por nombre = misma de grid)
    _colorMap.clear();
    for (var i = 0; i < _partidos.length; i++) {
      _colorMap[_partidos[i].id] = _kPartyColors[i % _kPartyColors.length];
    }

    // Cargar rondas hidratadas
    _rondas = await rondaRepository.listarHidratadasPorDerby(widget.derby.id);

    // Construir mapas de enfrentamientos
    _enfrentamientoMap.clear();
    _infoMap.clear();
    _byesPorRonda.clear();
    _doblesPorRonda.clear();

    for (final ronda in _rondas) {
      if (ronda.partidosDobles.isNotEmpty) {
        _doblesPorRonda[ronda.numero] = Set.from(ronda.partidosDobles);
      }

      for (final e in ronda.enfrentamientos) {
        final pIdA = e.galloA.partidoId;
        final pIdB = e.galloB.partidoId;

        _enfrentamientoMap[(pIdA, ronda.numero)] = e.id;
        _enfrentamientoMap[(pIdB, ronda.numero)] = e.id;

        _infoMap
            .putIfAbsent((pIdA, ronda.numero), () => [])
            .add(
              _EnfrentamientoInfo(
                enfrentamientoId: e.id,
                rivalPartidoId: pIdB,
                esMiGalloA: true,
                resultado: e.resultado,
                galloPropio: e.galloA,
                galloRival: e.galloB,
              ),
            );

        _infoMap
            .putIfAbsent((pIdB, ronda.numero), () => [])
            .add(
              _EnfrentamientoInfo(
                enfrentamientoId: e.id,
                rivalPartidoId: pIdA,
                esMiGalloA: false,
                resultado: e.resultado,
                galloPropio: e.galloB,
                galloRival: e.galloA,
              ),
            );
      }

      if (ronda.partidosBye.isNotEmpty) {
        _byesPorRonda[ronda.numero] = Set.from(ronda.partidosBye);
      }
    }

    _reconstruirFilas();
    if (mounted) setState(() => _cargando = false);
  }

  // ── Reconstruir tabla ──────────────────────────────────

  void _reconstruirFilas() {
    final puntosMap = <int, int>{};
    for (final p in _partidos) {
      puntosMap[p.id] = 0;
    }

    for (final ronda in _rondas) {
      // BYE NO otorga victoria automática (regla del juez).
      for (final e in ronda.enfrentamientos) {
        if (e.resultado == null) continue;
        final pIdA = e.galloA.partidoId;
        final pIdB = e.galloB.partidoId;

        switch (e.resultado!) {
          case domain.ResultadoPelea.ganoA:
            puntosMap[pIdA] = (puntosMap[pIdA] ?? 0) + _puntosVictoria;
            puntosMap[pIdB] = (puntosMap[pIdB] ?? 0) + _puntosDerrota;
          case domain.ResultadoPelea.ganoB:
            puntosMap[pIdB] = (puntosMap[pIdB] ?? 0) + _puntosVictoria;
            puntosMap[pIdA] = (puntosMap[pIdA] ?? 0) + _puntosDerrota;
          case domain.ResultadoPelea.empate:
            puntosMap[pIdA] = (puntosMap[pIdA] ?? 0) + _puntosEmpate;
            puntosMap[pIdB] = (puntosMap[pIdB] ?? 0) + _puntosEmpate;
          case domain.ResultadoPelea.noPeleada:
            break;
        }
      }
    }

    _rows = _partidos.map((p) {
      final resultados = List<String?>.filled(_rondasTotales, null);
      for (var r = 1; r <= _rondasTotales; r++) {
        if (r > _rondas.length) {
          resultados[r - 1] = null;
        } else if (_byesPorRonda[r]?.contains(p.id) == true) {
          resultados[r - 1] = 'BYE';
        } else {
          final infos = _infoMap[(p.id, r)];
          if (infos == null || infos.isEmpty) {
            resultados[r - 1] = '\u2014';
          } else if (infos.length == 1) {
            final info = infos.first;
            if (info.resultado == null) {
              resultados[r - 1] = '?';
            } else {
              resultados[r - 1] = _resultadoLabel(info);
            }
          } else {
            // Doble pelea: combine results
            final labels = infos.map((i) {
              if (i.resultado == null) return '?';
              return _resultadoLabel(i);
            }).toList();
            resultados[r - 1] = labels.join('|');
          }
        }
      }

      return _PeleaRow(
        partido: p.copyWith(puntos: puntosMap[p.id] ?? 0),
        puntos: puntosMap[p.id] ?? 0,
        posicion: 0,
        resultados: resultados,
      );
    }).toList();

    _rows.sort((a, b) {
      final cmp = b.puntos.compareTo(a.puntos);
      return cmp != 0 ? cmp : a.partido.nombre.compareTo(b.partido.nombre);
    });

    for (var i = 0; i < _rows.length; i++) {
      _rows[i].posicion = i + 1;
    }
  }

  String _resultadoLabel(_EnfrentamientoInfo info) {
    switch (info.resultado!) {
      case domain.ResultadoPelea.ganoA:
        return info.esMiGalloA ? 'G' : 'P';
      case domain.ResultadoPelea.ganoB:
        return info.esMiGalloA ? 'P' : 'G';
      case domain.ResultadoPelea.empate:
        return 'T';
      case domain.ResultadoPelea.noPeleada:
        return 'NP';
    }
  }

  // ── Registrar resultado ────────────────────────────────

  Future<void> _registrarResultado(
    int partidoId,
    int rondaNum, [
    int enfIdx = 0,
  ]) async {
    final infos = _infoMap[(partidoId, rondaNum)];
    if (infos == null || infos.isEmpty) return;
    final info = infos[enfIdx.clamp(0, infos.length - 1)];
    if (info.resultado != null) return;

    final rivalPartido = _partidos.firstWhere(
      (p) => p.id == info.rivalPartidoId,
    );
    final miPartido = _partidos.firstWhere((p) => p.id == partidoId);

    if (!mounted) return;

    final resultado = await showDialog<domain.ResultadoPelea>(
      context: context,
      builder: (ctx) => _ResultadoDialog(
        partidoA: miPartido.nombre,
        partidoB: rivalPartido.nombre,
        galloA: info.galloPropio,
        galloB: info.galloRival,
        colorA: _colorMap[miPartido.id] ?? _kPartyColors[0],
        colorB: _colorMap[rivalPartido.id] ?? _kPartyColors[1],
      ),
    );

    if (resultado == null || !mounted) return;

    final domain.ResultadoPelea resultadoReal;
    if (resultado == domain.ResultadoPelea.ganoA) {
      resultadoReal = info.esMiGalloA
          ? domain.ResultadoPelea.ganoA
          : domain.ResultadoPelea.ganoB;
    } else if (resultado == domain.ResultadoPelea.ganoB) {
      resultadoReal = info.esMiGalloA
          ? domain.ResultadoPelea.ganoB
          : domain.ResultadoPelea.ganoA;
    } else {
      resultadoReal = resultado;
    }

    await rondaRepository.registrarResultado(
      info.enfrentamientoId,
      resultadoReal.name,
    );

    await _recalcularYGuardarPuntos();
    await _cargarDatos();
  }

  Future<void> _recalcularYGuardarPuntos() async {
    final rondas = await rondaRepository.listarHidratadasPorDerby(
      widget.derby.id,
    );
    final puntosMap = <int, int>{};
    for (final p in _partidos) {
      puntosMap[p.id] = 0;
    }

    for (final ronda in rondas) {
      // BYE NO otorga victoria automática (regla del juez).
      for (final e in ronda.enfrentamientos) {
        if (e.resultado == null) continue;
        final pIdA = e.galloA.partidoId;
        final pIdB = e.galloB.partidoId;
        switch (e.resultado!) {
          case domain.ResultadoPelea.ganoA:
            puntosMap[pIdA] = (puntosMap[pIdA] ?? 0) + _puntosVictoria;
            puntosMap[pIdB] = (puntosMap[pIdB] ?? 0) + _puntosDerrota;
          case domain.ResultadoPelea.ganoB:
            puntosMap[pIdB] = (puntosMap[pIdB] ?? 0) + _puntosVictoria;
            puntosMap[pIdA] = (puntosMap[pIdA] ?? 0) + _puntosDerrota;
          case domain.ResultadoPelea.empate:
            puntosMap[pIdA] = (puntosMap[pIdA] ?? 0) + _puntosEmpate;
            puntosMap[pIdB] = (puntosMap[pIdB] ?? 0) + _puntosEmpate;
          case domain.ResultadoPelea.noPeleada:
            break;
        }
      }
    }

    for (final entry in puntosMap.entries) {
      await partidoRepository.actualizarPuntos(entry.key, entry.value);
    }
  }

  // ── Estado del derby ───────────────────────────────────

  int get _rondasCompletadas => _rondas.where((r) => r.completa).length;

  bool get _derbyFinalizado =>
      _rondas.length >= _rondasTotales && _rondas.every((r) => r.completa);

  /// Devuelve true si la ronda [rondaNum] (1-based) puede editarse,
  /// es decir, todas las rondas anteriores ya están completas.
  bool _rondaHabilitada(int rondaNum) {
    for (var i = 0; i < rondaNum - 1 && i < _rondas.length; i++) {
      if (!_rondas[i].completa) return false;
    }
    return true;
  }

  /// ¿Se puede generar la siguiente ronda?
  /// Condiciones: hay rondas guardadas, TODAS están completas (resultados),
  /// y aún faltan rondas por generar.
  bool get _puedeGenerarSiguienteRonda =>
      _rondas.isNotEmpty &&
      _rondas.length < _rondasTotales &&
      _rondas.every((r) => r.completa);

  int get _siguienteRondaNumero => _rondas.length + 1;

  // ── FAB: Generar Siguiente Ronda ───────────────────────

  Widget? _buildFABSiguienteRonda(ColorScheme cs) {
    if (_cargando || !_puedeGenerarSiguienteRonda) return null;

    final nextNum = _siguienteRondaNumero;
    final esBase = nextNum == _rondasTotales;
    final label = esBase
        ? 'Generar Ronda $nextNum (Base)'
        : 'Generar Ronda $nextNum';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _generarSiguienteRonda,
        icon: const Icon(Icons.bolt_rounded, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ── Generar siguiente ronda con eliminación/comodín ────

  Future<void> _generarSiguienteRonda() async {
    final nextNum = _siguienteRondaNumero;

    // 1. Cargar datos frescos (con puntos actualizados)
    final derbyData = await derbyRepository.obtenerPorId(widget.derby.id);
    if (derbyData == null || !mounted) return;

    final partidosDb = await partidoRepository.listarPorDerby(widget.derby.id);
    final galloEntries = await galloRepository.listarPorDerby(widget.derby.id);
    final compadreEntries = await compadresRepository.listarPorDerby(
      widget.derby.id,
    );

    // 2. Convertir a entidades de dominio (con puntos actuales)
    final domPartidos = partidosDb
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

    // 3. Config & Engine
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

    final engine = DerbyEngine(config: config, compadres: domCompadres);

    // 4. Obtener rondas previas ya guardadas
    final rondasPrevias = await rondaRepository.listarHidratadasPorDerby(
      widget.derby.id,
    );

    // 5. Calcular eliminaciones
    final rondasRestantes = config.rondasTotales - nextNum + 1;
    final eliminados = engine.calcularEliminaciones(
      partidos: domPartidos,
      rondasRestantes: rondasRestantes,
    );
    final eliminadosIds = eliminados
        .where((a) => a.eliminado)
        .map((a) => a.partidoId)
        .toSet();

    // Contar activos post-eliminación (excluyendo comodines)
    final activosPostElim = domPartidos
        .where(
          (p) =>
              p.estado == domain.EstadoPartido.activo &&
              !p.eliminado &&
              !p.esComodin &&
              !eliminadosIds.contains(p.id),
        )
        .toList();

    print('\n── Generar Ronda $nextNum (incremental) ──');
    print('  Partidos activos: ${activosPostElim.length}');
    print('  Eliminados: $eliminadosIds');

    // 6. Mostrar info de eliminación al usuario si hay eliminados
    if (eliminadosIds.isNotEmpty && mounted) {
      final nombresElim = domPartidos
          .where((p) => eliminadosIds.contains(p.id))
          .map((p) => p.nombre)
          .toList();
      final esImpar = activosPostElim.length.isOdd;

      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.info_outline, color: Colors.blue, size: 40),
          title: Text('Ronda $nextNum — Eliminaciones'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partidos eliminados matemáticamente:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...nombresElim.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        Text(n),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Partidos activos restantes: ${activosPostElim.length} '
                  '(${esImpar ? "IMPAR — se usará comodín o BYE" : "PAR"})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text('¿Deseas generar la siguiente ronda?'),
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
              child: const Text('Generar'),
            ),
          ],
        ),
      );

      if (continuar != true || !mounted) return;
    }

    // 7. Generar la ronda con el engine (incluye eliminación, comodín, doble, BYE)
    try {
      final nuevaRonda = engine.generarRonda(
        partidos: domPartidos,
        gallos: domGallos,
        compadres: domCompadres,
        rondasPrevias: rondasPrevias,
        rondaNumero: nextNum,
      );

      print(
        '✅ Ronda $nextNum generada: ${nuevaRonda.enfrentamientos.length} peleas',
      );

      // 8. Guardar en DB
      await rondaRepository.crearRondaConEnfrentamientos(
        derbyId: widget.derby.id,
        numero: nuevaRonda.numero,
        esRondaBase: nuevaRonda.esRondaBase,
        enfrentamientos: nuevaRonda.enfrentamientos,
        partidosBye: nuevaRonda.partidosBye,
        partidosDobles: nuevaRonda.partidosDobles,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Ronda $nextNum generada correctamente'
            '${nuevaRonda.partidosBye.isNotEmpty ? " (con BYE)" : ""}'
            '${nuevaRonda.partidosDobles.isNotEmpty ? " (doble pelea)" : ""}',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );

      // 9. Recargar datos
      await _cargarDatos();
    } on domain.DerbyException catch (e) {
      print('❌ Error generando ronda $nextNum: ${e.mensaje}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.mensaje}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('❌ Error inesperado: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Acciones de reporte en AppBar ──────────────────────

  /// Construye los botones que aparecen en la esquina superior derecha:
  /// uno para el reporte completo y un menú desplegable para imprimir por ronda.
  List<Widget> _buildAccionesReporte() {
    return [
      // ── PDF de resultados completos ─────────────────────
      IconButton(
        icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
        tooltip: 'Reporte de resultados',
        onPressed: _mostrarReporteResultados,
      ),
      // ── Imprimir por ronda ──────────────────────────────
      PopupMenuButton<int>(
        icon: const Icon(Icons.print_rounded, size: 22),
        tooltip: 'Imprimir por ronda',
        offset: const Offset(0, 48),
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => [
          const PopupMenuItem<int>(
            enabled: false,
            child: Text(
              'IMPRIMIR POR RONDA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF6B1C2A),
              ),
            ),
          ),
          const PopupMenuDivider(),
          for (var r = 1; r <= _rondasTotales; r++)
            if (r <= _rondas.length)
              PopupMenuItem<int>(
                value: r,
                child: Row(
                  children: [
                    Icon(
                      r == _rondasTotales
                          ? Icons.star_rounded
                          : Icons.format_list_numbered_rounded,
                      size: 18,
                      color: const Color(0xFF6B1C2A),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      r == _rondasTotales ? 'Ronda Base  (R$r)' : 'Ronda $r',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_rondas[r - 1].completa)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Color(0xFF16A34A),
                      ),
                  ],
                ),
              )
            else
              PopupMenuItem<int>(
                enabled: false,
                value: r,
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      r == _rondasTotales
                          ? 'Ronda Base (pendiente)'
                          : 'Ronda $r (pendiente)',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
        ],
        onSelected: (rondaNum) {
          final sorteo = _construirSorteoResultado();
          if (sorteo == null) return;
          ReporteRondaSorteoPdf(
            sorteo: sorteo,
          ).vistaPreviaRonda(context, rondaNum);
        },
      ),
    ];
  }

  /// Construye un [SorteoResultado] a partir de los datos actuales de la pantalla.
  domain.SorteoResultado? _construirSorteoResultado() {
    if (_rows.isEmpty || _rondas.isEmpty) return null;

    // Los partidos ordenados por fila = orden en _rows (por puntos/posición)
    final partidos = _rows.map((r) => r.partido).toList();

    final sorteoUseCase = GenerarSorteo(
      DerbyEngine(
        config: DerbyConfig(
          diferenciaMaxPeso: widget.derby.diferenciaMaxPeso,
          permitirRepeticiones: widget.derby.permitirRepeticiones,
          rondasTotales: _rondasTotales,
        ),
        compadres: const [],
      ),
    );

    return sorteoUseCase.construirResultadoVisual(
      nombreDerby: widget.derby.nombre,
      partidos: partidos,
      rondas: _rondas,
    );
  }

  // ── Reporte de Resultados PDF ────────────────────────

  void _mostrarReporteResultados() {
    if (_rows.isEmpty || _rondas.isEmpty) return;

    // Mapa partidoId → fila (1-based) en la tabla ordenada por puntos
    final filaMap = <int, int>{};
    for (var i = 0; i < _rows.length; i++) {
      filaMap[_rows[i].partido.id] = i + 1;
    }

    final filas = _rows.map((row) {
      final peleas = <int, List<PeleaInfoReporte>>{};
      for (var r = 1; r <= _rondasTotales; r++) {
        final infos = _infoMap[(row.partido.id, r)];
        if (infos != null && infos.isNotEmpty) {
          peleas[r] = infos.map((info) {
            String resultado;
            if (info.resultado == null) {
              resultado = '?';
            } else {
              resultado = _resultadoLabel(info);
            }
            return PeleaInfoReporte(
              anilloPropio: info.galloPropio.anillo,
              anilloRival: info.galloRival.anillo,
              resultado: resultado,
              filaRival: filaMap[info.rivalPartidoId] ?? 0,
            );
          }).toList();
        }
      }
      return FilaResultadoReporte(
        nombre: row.partido.nombre,
        puntos: row.puntos,
        peleas: peleas,
      );
    }).toList();

    final reporte = ReporteResultadosPdf(
      nombreDerby: widget.derby.nombre,
      fecha: DateTime.now(),
      rondasTotales: _rondasTotales,
      filas: filas,
    );
    reporte.vistaPrevia(context);
  }

  // ── Campe\u00f3n ────────────────────────────────────────────

  void _mostrarCampeon() {
    if (_rows.isEmpty) return;
    final campeon = _rows.first;
    final sub = _rows.length > 1 ? _rows[1] : null;
    final tercero = _rows.length > 2 ? _rows[2] : null;

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: const Text('\u{1F3C6}', style: TextStyle(fontSize: 48)),
          title: const Text('\u{00A1}Derby Finalizado!'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _podiumTile(
                  '\u{1F947}',
                  'Campe\u{00F3}n',
                  campeon.partido.nombre,
                  campeon.puntos,
                  const Color(0xFFFFD700),
                ),
                if (sub != null)
                  _podiumTile(
                    '\u{1F948}',
                    'Subcampe\u{00F3}n',
                    sub.partido.nombre,
                    sub.puntos,
                    const Color(0xFFC0C0C0),
                  ),
                if (tercero != null)
                  _podiumTile(
                    '\u{1F949}',
                    'Tercer lugar',
                    tercero.partido.nombre,
                    tercero.puntos,
                    const Color(0xFFCD7F32),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_rondas.length} rondas completadas',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _podiumTile(
    String emoji,
    String titulo,
    String nombre,
    int puntos,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  nombre.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$puntos pts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: _kBgCanvas,
      appBar: (_cargando || _rondas.isEmpty)
          ? AppBar(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              title: Text(widget.derby.nombre),
              elevation: 0,
            )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _rondas.isEmpty
          ? _buildEmpty(cs)
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(cs),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildCard(i),
                      childCount: _rows.length,
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFABSiguienteRonda(cs),
    );
  }

  // ── Sliver AppBar ───────────────────────────────────────

  Widget _buildSliverAppBar(ColorScheme cs) {
    final completadas = _rondasCompletadas;
    final progreso = _rondasTotales > 0 ? completadas / _rondasTotales : 0.0;

    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: _kAccent,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (!_cargando && _rondas.isNotEmpty) ..._buildAccionesReporte(),
        if (_derbyFinalizado)
          IconButton(
            icon: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 24,
            ),
            tooltip: 'Ver Campe\u00f3n',
            onPressed: _mostrarCampeon,
          ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B2131), _kAccent, Color(0xFF4A0E1A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 40, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.derby.nombre.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progreso,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$completadas / $_rondasTotales rondas',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_rows.length} partidos',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_derbyFinalizado) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'FINALIZADO',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: _kAccentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_mma_rounded,
              size: 48,
              color: _kAccent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin rondas a\u00fan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Genera el sorteo desde la grilla del derby',
            style: TextStyle(fontSize: 14, color: _kTextSecondary),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  CARD-BASED PARTIDO ROWS
  // ═════════════════════════════════════════════════════════

  Widget _buildCard(int index) {
    final row = _rows[index];
    final partyColor = _colorMap[row.partido.id] ?? _kPartyColors[0];
    final isChampion = row.posicion == 1 && _derbyFinalizado;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _kCardShadow,
        border: isChampion
            ? Border.all(color: const Color(0xFFFFD700), width: 2.0)
            : Border.all(color: _kDivider, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Contenido principal (determina la altura del Stack)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCardHeader(row, partyColor, isChampion),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: _kDivider,
                    indent: 10,
                    endIndent: 10,
                  ),
                  _buildRoundsRow(row, partyColor),
                ],
              ),
            ),
            // Barra lateral de color (Positioned, se estira a la altura del Stack)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 6, color: partyColor),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card Header (name + pts) ───────────────────────────

  Widget _buildCardHeader(_PeleaRow row, Color partyColor, bool isChampion) {
    final medalColors = [
      const Color(0xFFFFD700), // oro
      const Color(0xFFB0BEC5), // plata
      const Color(0xFFBF8C55), // bronce
    ];
    final isMedal = row.posicion <= 3;
    final medalColor = isMedal ? medalColors[row.posicion - 1] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Position badge — círculo sólido con color de medalla o partido
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isMedal
                  ? medalColor!.withValues(alpha: 0.18)
                  : partyColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: isMedal ? medalColor! : partyColor,
                width: 2.0,
              ),
            ),
            child: Center(
              child: Text(
                '${row.posicion}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isMedal ? medalColor! : partyColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + responsable
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        row.partido.nombre.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _kTextPrimary,
                          letterSpacing: 0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isChampion)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFFFD700),
                          size: 22,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                if (row.partido.responsable != null &&
                    row.partido.responsable!.isNotEmpty)
                  Text(
                    row.partido.responsable!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _kTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  const SizedBox(height: 2),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: row.puntos > 0 ? _kAccent : _kGreyBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: row.puntos > 0 ? _kAccent : _kDivider,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${row.puntos}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: row.puntos > 0 ? Colors.white : _kTextTertiary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: row.puntos > 0
                        ? Colors.white.withValues(alpha: 0.75)
                        : _kTextTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rounds row (horizontal scroll) ────────────────────

  Widget _buildRoundsRow(_PeleaRow row, Color partyColor) {
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        itemCount: _rondasTotales,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, r) => _buildRondaCell(row, r + 1, partyColor),
      ),
    );
  }

  // ── Single round cell ─────────────────────────────────

  Widget _buildRondaCell(_PeleaRow row, int rondaNum, Color partyColor) {
    final resultado = row.resultados[rondaNum - 1];
    final infos = _infoMap[(row.partido.id, rondaNum)];
    final bool tienePelea =
        infos != null && infos.isNotEmpty && resultado != null;
    final bool pendiente =
        resultado == '?' ||
        (resultado != null &&
            resultado.contains('|') &&
            resultado.contains('?'));
    final bool bloqueada = pendiente && !_rondaHabilitada(rondaNum);
    final esBase = rondaNum == _rondasTotales;

    final borderColor = bloqueada
        ? _kTextTertiary.withValues(alpha: 0.35)
        : pendiente
        ? _kBlue.withValues(alpha: 0.6)
        : tienePelea
        ? _kDivider
        : _kDivider.withValues(alpha: 0.5);
    final borderWidth = pendiente && !bloqueada ? 2.0 : 1.0;

    return Opacity(
      opacity: bloqueada ? 0.45 : 1.0,
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: tienePelea
              ? (pendiente && !bloqueada
                    ? _kBlueBg.withValues(alpha: 0.25)
                    : _kBgCanvas)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Etiqueta de ronda con fondo si es activa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: esBase
                    ? _kAccent.withValues(alpha: 0.12)
                    : (pendiente && !bloqueada
                          ? _kBlue.withValues(alpha: 0.12)
                          : _kGreyBg),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                esBase ? 'BASE' : 'RONDA $rondaNum',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: esBase
                      ? _kAccent
                      : (pendiente && !bloqueada ? _kBlue : _kTextSecondary),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _buildRondaContent(
                row,
                rondaNum,
                resultado,
                infos,
                partyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRondaContent(
    _PeleaRow row,
    int rondaNum,
    String? resultado,
    List<_EnfrentamientoInfo>? infos,
    Color partyColor,
  ) {
    // Not generated
    if (resultado == null) {
      return const Center(
        child: Icon(Icons.remove_rounded, color: _kDivider, size: 20),
      );
    }

    // BYE
    if (resultado == 'BYE') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _kGreyBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kDivider, width: 1.0),
          ),
          child: const Text(
            'BYE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kTextSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    }

    // Dash / sobrante
    if (resultado == '\u2014') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _kGreyBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kDivider, width: 1.0),
          ),
          child: const Text(
            'DESCANSA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    // Enfrentamientos
    if (infos == null || infos.isEmpty) {
      return const SizedBox.shrink();
    }

    if (infos.length > 1) {
      // Doble pelea
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < infos.length; i++) ...[
            if (i > 0) const SizedBox(height: 2),
            _buildMatchupLine(
              row.partido.id,
              rondaNum,
              infos[i],
              i,
              partyColor,
              compact: true,
            ),
          ],
        ],
      );
    }

    return _buildMatchupLine(
      row.partido.id,
      rondaNum,
      infos.first,
      0,
      partyColor,
    );
  }

  // ── Matchup line ──────────────────────────────────────

  Widget _buildMatchupLine(
    int partidoId,
    int rondaNum,
    _EnfrentamientoInfo info,
    int enfIdx,
    Color partyColor, {
    bool compact = false,
  }) {
    final rivalColor = _colorMap[info.rivalPartidoId] ?? _kGrey;
    final hasResult = info.resultado != null;
    final label = hasResult ? _resultadoLabel(info) : '?';
    final rivalNombre =
        _partidos
            .where((p) => p.id == info.rivalPartidoId)
            .map((p) => p.nombre)
            .firstOrNull ??
        '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: _galloTag(
                info.galloPropio.anillo,
                partyColor,
                compact: compact,
              ),
            ),
            const SizedBox(width: 4),
            hasResult
                ? _resultChip(label, compact: compact)
                : _pendingChip(
                    partidoId,
                    rondaNum,
                    enfIdx,
                    compact: compact,
                    habilitado: _rondaHabilitada(rondaNum),
                  ),
            const SizedBox(width: 4),
            Flexible(
              child: _galloTag(
                info.galloRival.anillo,
                rivalColor,
                compact: compact,
                subtle: true,
              ),
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          Text(
            'vs ${rivalNombre.toUpperCase()}',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _kTextTertiary,
              letterSpacing: 0.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ],
    );
  }

  // ── Gallo tag ─────────────────────────────────────────

  Widget _galloTag(
    String anillo,
    Color color, {
    bool compact = false,
    bool subtle = false,
  }) {
    final fs = compact ? 11.0 : 13.0;
    final px = compact ? 7.0 : 9.0;
    final py = compact ? 3.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: px, vertical: py),
      decoration: BoxDecoration(
        color: subtle
            ? color.withValues(alpha: 0.10)
            : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: subtle ? 0.35 : 0.55),
          width: 1.5,
        ),
      ),
      child: Text(
        anillo,
        style: TextStyle(
          fontSize: fs,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.3,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  // ── Result chip (G/P/T) ───────────────────────────────

  Widget _resultChip(String label, {bool compact = false}) {
    Color bg;
    Color fg;
    switch (label) {
      case 'G':
        bg = _kGreenBg;
        fg = _kGreen;
      case 'P':
        bg = _kRedBg;
        fg = _kRed;
      case 'T':
        bg = _kAmberBg;
        fg = _kAmber;
      case 'NP':
        bg = _kGreyBg;
        fg = _kGrey;
      default:
        bg = _kGreyBg;
        fg = _kGrey;
    }

    final size = compact ? 22.0 : 32.0;
    final fs = compact ? 11.0 : 15.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 6 : 9),
        border: Border.all(color: fg.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      ),
    );
  }

  // ── Pending chip (clickable) ──────────────────────────

  Widget _pendingChip(
    int partidoId,
    int rondaNum,
    int enfIdx, {
    bool compact = false,
    bool habilitado = true,
  }) {
    final size = compact ? 22.0 : 32.0;
    final fs = compact ? 11.0 : 15.0;

    final Color chipBg = habilitado ? _kBlueBg : _kGreyBg;
    final Color chipFg = habilitado ? _kBlue : _kTextTertiary;
    final Color borderColor = habilitado
        ? _kBlue.withValues(alpha: 0.7)
        : _kDivider;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 6 : 9),
        onTap: habilitado
            ? () => _registrarResultado(partidoId, rondaNum, enfIdx)
            : () {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Completa la ronda ${rondaNum - 1} antes de registrar resultados en la ronda $rondaNum',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(compact ? 6 : 9),
            border: Border.all(color: borderColor, width: 2.0),
          ),
          child: Center(
            child: habilitado
                ? Text(
                    '?',
                    style: TextStyle(
                      fontSize: fs,
                      fontWeight: FontWeight.w900,
                      color: chipFg,
                    ),
                  )
                : Icon(Icons.lock_rounded, size: fs * 0.85, color: chipFg),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Modelo: Info de enfrentamiento para un partido
// ═══════════════════════════════════════════════════════════════

class _EnfrentamientoInfo {
  final int enfrentamientoId;
  final int rivalPartidoId;
  final bool esMiGalloA;
  final domain.ResultadoPelea? resultado;
  final domain.Gallo galloPropio;
  final domain.Gallo galloRival;

  const _EnfrentamientoInfo({
    required this.enfrentamientoId,
    required this.rivalPartidoId,
    required this.esMiGalloA,
    required this.resultado,
    required this.galloPropio,
    required this.galloRival,
  });
}

// ═══════════════════════════════════════════════════════════════
//  Di\u00e1logo: Registrar resultado de una pelea
// ═══════════════════════════════════════════════════════════════

class _ResultadoDialog extends StatelessWidget {
  final String partidoA;
  final String partidoB;
  final domain.Gallo galloA;
  final domain.Gallo galloB;
  final Color colorA;
  final Color colorB;

  const _ResultadoDialog({
    required this.partidoA,
    required this.partidoB,
    required this.galloA,
    required this.galloB,
    required this.colorA,
    required this.colorB,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: _kAccentLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_mma_rounded,
                  color: _kAccent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registrar Resultado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 20),
              // Matchup card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kBgCanvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kDivider),
                ),
                child: Row(
                  children: [
                    Expanded(child: _fighterColumn(partidoA, galloA, colorA)),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _kAccent,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: _fighterColumn(partidoB, galloB, colorB)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '\u00bfQui\u00e9n gan\u00f3?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              _resultButton(
                context,
                label: 'Gan\u00f3 ${partidoA.toUpperCase()}',
                icon: Icons.emoji_events_rounded,
                bg: _kGreenBg,
                fg: _kGreen,
                resultado: domain.ResultadoPelea.ganoA,
              ),
              const SizedBox(height: 8),
              _resultButton(
                context,
                label: 'Gan\u00f3 ${partidoB.toUpperCase()}',
                icon: Icons.emoji_events_rounded,
                bg: _kGreenBg,
                fg: _kGreen,
                resultado: domain.ResultadoPelea.ganoB,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _resultButton(
                      context,
                      label: 'Tablas',
                      icon: Icons.handshake_rounded,
                      bg: _kAmberBg,
                      fg: _kAmber,
                      resultado: domain.ResultadoPelea.empate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _resultButton(
                      context,
                      label: 'No Peleada',
                      icon: Icons.block_rounded,
                      bg: _kGreyBg,
                      fg: _kGrey,
                      resultado: domain.ResultadoPelea.noPeleada,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: _kTextSecondary),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fighterColumn(String nombre, domain.Gallo gallo, Color color) {
    return Column(
      children: [
        Text(
          nombre.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: _kTextPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            gallo.anillo,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${gallo.pesoGramos.toStringAsFixed(0)}g',
          style: const TextStyle(fontSize: 11, color: _kTextTertiary),
        ),
      ],
    );
  }

  Widget _resultButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required domain.ResultadoPelea resultado,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context, resultado),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
