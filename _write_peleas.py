#!/usr/bin/env python3
"""Write the new derby_peleas_screen.dart file."""

content = r'''import 'package:flutter/material.dart';
import '../../main.dart'
    show
        partidoRepository,
        rondaRepository,
        derbyRepository;
import '../../data/database/app_database.dart' show Derby;
import '../../domain/domain.dart' as domain;

// ═══════════════════════════════════════════════════════════════
//  Constantes de estilo – réplica del diseño referencia
// ═══════════════════════════════════════════════════════════════

const _kHeaderBg = Color(0xFF6B1C2A); // vino oscuro
const _kRowHeight = 88.0;
const _kHeaderHeight = 46.0;

// Anchos de columna
const _kColPos = 55.0;
const _kColPartido = 195.0;
const _kColRonda = 148.0; // 2 chips apilados con "vs"
const _kColResult = 62.0; // Badge G/P/T/?
const _kColPts = 62.0;

// Colores de resultado
const _kGreen = Color(0xFF2E7D32);
const _kRed = Color(0xFFC62828);
const _kOrange = Color(0xFFE65100);
const _kBlue = Color(0xFF1565C0);
const _kGrey = Color(0xFF757575);

// Colores de fila (tema claro estilo torneo)
const _kRowEven = Color(0xFFFFFFFF);
const _kRowOdd = Color(0xFFF5F0EB);
const _kTextDark = Color(0xFF2C2C2C);
const _kVsColor = Color(0xFF999999);
const _kBorderColor = Color(0xFFE0D8D0);

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

  /// Mapa: (partidoId, rondaNumero) -> info completa del enfrentamiento
  final Map<(int, int), _EnfrentamientoInfo> _infoMap = {};

  /// Partidos que tienen BYE por ronda
  final Map<int, Set<int>> _byesPorRonda = {};

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

    final partidosDb =
        await partidoRepository.listarPorDerby(widget.derby.id);
    _partidos = partidosDb
        .map((p) => domain.Partido(
              id: p.id,
              nombre: p.nombre,
              responsable: p.responsable,
              telefono: p.telefono,
              puntos: p.puntos,
              eliminado: p.eliminado,
              depositoPagado: p.depositoPagado,
              depositoCantidad: p.depositoCantidad,
            ))
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

    for (final ronda in _rondas) {
      for (final e in ronda.enfrentamientos) {
        final pIdA = e.galloA.partidoId;
        final pIdB = e.galloB.partidoId;

        _enfrentamientoMap[(pIdA, ronda.numero)] = e.id;
        _enfrentamientoMap[(pIdB, ronda.numero)] = e.id;

        _infoMap[(pIdA, ronda.numero)] = _EnfrentamientoInfo(
          enfrentamientoId: e.id,
          rivalPartidoId: pIdB,
          esMiGalloA: true,
          resultado: e.resultado,
          galloPropio: e.galloA,
          galloRival: e.galloB,
        );

        _infoMap[(pIdB, ronda.numero)] = _EnfrentamientoInfo(
          enfrentamientoId: e.id,
          rivalPartidoId: pIdA,
          esMiGalloA: false,
          resultado: e.resultado,
          galloPropio: e.galloB,
          galloRival: e.galloA,
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
      for (final byeId in ronda.partidosBye) {
        puntosMap[byeId] = (puntosMap[byeId] ?? 0) + _puntosVictoria;
      }
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
          final info = _infoMap[(p.id, r)];
          if (info == null) {
            resultados[r - 1] = '\u2014';
          } else if (info.resultado == null) {
            resultados[r - 1] = '?';
          } else {
            resultados[r - 1] = _resultadoLabel(info);
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

  Future<void> _registrarResultado(int partidoId, int rondaNum) async {
    final info = _infoMap[(partidoId, rondaNum)];
    if (info == null || info.resultado != null) return;

    final rivalPartido =
        _partidos.firstWhere((p) => p.id == info.rivalPartidoId);
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
    final rondas =
        await rondaRepository.listarHidratadasPorDerby(widget.derby.id);
    final puntosMap = <int, int>{};
    for (final p in _partidos) {
      puntosMap[p.id] = 0;
    }

    for (final ronda in rondas) {
      for (final byeId in ronda.partidosBye) {
        puntosMap[byeId] = (puntosMap[byeId] ?? 0) + _puntosVictoria;
      }
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
                _podiumTile('\u{1F947}', 'Campe\u{00F3}n', campeon.partido.nombre,
                    campeon.puntos, const Color(0xFFFFD700)),
                if (sub != null)
                  _podiumTile('\u{1F948}', 'Subcampe\u{00F3}n', sub.partido.nombre,
                      sub.puntos, const Color(0xFFC0C0C0)),
                if (tercero != null)
                  _podiumTile('\u{1F949}', 'Tercer lugar', tercero.partido.nombre,
                      tercero.puntos, const Color(0xFFCD7F32)),
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
                      Text('${_rondas.length} rondas completadas',
                          style: TextStyle(
                              color: cs.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar')),
          ],
        );
      },
    );
  }

  Widget _podiumTile(
      String emoji, String titulo, String nombre, int puntos, Color color) {
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
                Text(titulo,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold)),
                Text(nombre.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$puntos pts',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════

  double get _totalWidth =>
      _kColPos +
      _kColPartido +
      (_rondasTotales * _kColRonda) +
      (_rondasTotales * _kColResult) +
      _kColPts;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completadas = _rondasCompletadas;

    return Scaffold(
      appBar: AppBar(
        title: Text('Peleas \u2013 ${widget.derby.nombre}'),
        centerTitle: true,
        actions: [
          if (!_cargando && _rondas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rondas: $completadas / $_rondasTotales',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            ),
          if (_derbyFinalizado)
            IconButton(
              icon: const Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
              tooltip: 'Ver Campe\u{00F3}n',
              onPressed: _mostrarCampeon,
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _rondas.isEmpty
              ? _buildEmpty(cs)
              : _buildContent(),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_mma,
              size: 80, color: cs.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No hay rondas generadas',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Primero genera el sorteo desde la grilla del derby'),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════
  //  GRILLA ESTILO TORNEO (tema claro)
  // ═════════════════════════════════════════════════════════

  Widget _buildContent() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _totalWidth,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                color: _kRowEven,
                child: ListView.builder(
                  itemCount: _rows.length,
                  itemBuilder: (_, i) => _buildRow(i),
                ),
              ),
            ),
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
        border: Border(
          bottom: BorderSide(color: Color(0xFF4A0E1A), width: 2),
        ),
      ),
      child: Row(
        children: [
          _hCell('#', _kColPos),
          _hCell('PARTIDO', _kColPartido),
          for (var r = 1; r <= _rondasTotales; r++)
            _hCell('RONDA $r', _kColRonda),
          for (var r = 1; r <= _rondasTotales; r++)
            _hCell('R$r', _kColResult),
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
            fontSize: 12,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ── Row ────────────────────────────────────────────────

  Widget _buildRow(int index) {
    final row = _rows[index];
    final isOdd = index.isOdd;

    return Container(
      height: _kRowHeight,
      decoration: BoxDecoration(
        color: isOdd ? _kRowOdd : _kRowEven,
        border: const Border(
          bottom: BorderSide(color: _kBorderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          _posCell(row.posicion),
          _nombreCell(row),
          for (var r = 1; r <= _rondasTotales; r++)
            _rondaMatchupCell(row, r),
          for (var r = 1; r <= _rondasTotales; r++)
            _resultBadgeCell(row, r),
          _puntosCell(row.puntos),
        ],
      ),
    );
  }

  // ── Celda # ────────────────────────────────────────────

  Widget _posCell(int pos) {
    return Container(
      width: _kColPos,
      color: _kHeaderBg,
      child: Center(
        child: Text(
          '$pos',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  // ── Celda PARTIDO ──────────────────────────────────────

  Widget _nombreCell(_PeleaRow row) {
    return Container(
      width: _kColPartido,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.partido.nombre.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: _kTextDark,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if (row.posicion == 1 && _derbyFinalizado)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('\u{1F3C6}', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }

  // ── Celda RONDA (chips de gallos apilados) ─────────────

  Widget _rondaMatchupCell(_PeleaRow row, int rondaNum) {
    final resultado = row.resultados[rondaNum - 1];

    // Ronda no generada
    if (resultado == null) {
      return SizedBox(
        width: _kColRonda,
        child: Center(
          child: Text('\u2014',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 18)),
        ),
      );
    }

    // BYE
    if (resultado == 'BYE') {
      return SizedBox(
        width: _kColRonda,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'BYE',
              style: TextStyle(
                color: _kTextDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      );
    }

    // Sobrante
    if (resultado == '\u2014') {
      return SizedBox(
        width: _kColRonda,
        child: Center(
          child: Text('\u2014',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 18)),
        ),
      );
    }

    // Enfrentamiento (con o sin resultado)
    final info = _infoMap[(row.partido.id, rondaNum)];
    if (info == null) {
      return SizedBox(width: _kColRonda);
    }

    final miColor = _colorMap[row.partido.id] ?? Colors.grey;
    final rivalColor = _colorMap[info.rivalPartidoId] ?? Colors.grey;

    return SizedBox(
      width: _kColRonda,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _galloChip(info.galloPropio.anillo, miColor),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 1),
            child: Text('vs',
                style: TextStyle(
                    fontSize: 10,
                    color: _kVsColor,
                    fontStyle: FontStyle.italic)),
          ),
          _galloChip(info.galloRival.anillo, rivalColor),
        ],
      ),
    );
  }

  /// Chip coloreado mostrando anillo de un gallo.
  Widget _galloChip(String anillo, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        anillo,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Celda R (badge resultado) ──────────────────────────

  Widget _resultBadgeCell(_PeleaRow row, int rondaNum) {
    final resultado = row.resultados[rondaNum - 1];

    // Sin ronda / sobrante
    if (resultado == null || resultado == '\u2014') {
      return SizedBox(
        width: _kColResult,
        child: Center(
          child: Text('\u2014',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        ),
      );
    }

    // BYE -> G autom\u00e1tico
    if (resultado == 'BYE') {
      return SizedBox(
        width: _kColResult,
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _kGreen,
            ),
            child: const Center(
              child: Text('G',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
        ),
      );
    }

    // Pendiente - clickeable
    if (resultado == '?') {
      return SizedBox(
        width: _kColResult,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _registrarResultado(row.partido.id, rondaNum),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kBlue, width: 2),
                ),
                child: const Center(
                  child: Text('?',
                      style: TextStyle(
                          color: _kBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Resultado definido
    final Color bg;
    final Color textColor;
    final Color? borderClr;
    String label = resultado;

    switch (resultado) {
      case 'G':
        bg = _kGreen;
        textColor = Colors.white;
        borderClr = null;
      case 'P':
        bg = _kRed;
        textColor = Colors.white;
        borderClr = null;
      case 'T':
        bg = Colors.transparent;
        textColor = _kOrange;
        borderClr = _kOrange;
      case 'NP':
        bg = _kGrey;
        textColor = Colors.white;
        borderClr = null;
        label = 'NP';
      default:
        bg = Colors.transparent;
        textColor = Colors.grey;
        borderClr = Colors.grey;
    }

    return SizedBox(
      width: _kColResult,
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: borderClr != null
                ? Border.all(color: borderClr, width: 2.5)
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: label.length > 1 ? 11 : 17,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Celda PTS ──────────────────────────────────────────

  Widget _puntosCell(int pts) {
    return SizedBox(
      width: _kColPts,
      child: Center(
        child: Text(
          '$pts',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: pts > 0 ? _kTextDark : Colors.grey.shade400,
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
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: const Icon(Icons.sports_mma, size: 36),
      title: const Text('Registrar Resultado'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enfrentamiento visual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          partidoA.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: colorA,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            galloA.anillo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${galloA.pesoGramos.toStringAsFixed(0)}g',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('VS',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.primary)),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          partidoB.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: colorB,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            galloB.anillo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${galloB.pesoGramos.toStringAsFixed(0)}g',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '\u00bfQui\u00e9n gan\u00f3?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            _resultButton(
              context,
              label: 'Gan\u00f3 ${partidoA.toUpperCase()}',
              icon: Icons.emoji_events,
              color: _kGreen,
              resultado: domain.ResultadoPelea.ganoA,
            ),
            const SizedBox(height: 8),
            _resultButton(
              context,
              label: 'Gan\u00f3 ${partidoB.toUpperCase()}',
              icon: Icons.emoji_events,
              color: _kGreen,
              resultado: domain.ResultadoPelea.ganoB,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _resultButton(
                    context,
                    label: 'Tablas',
                    icon: Icons.handshake,
                    color: _kOrange,
                    resultado: domain.ResultadoPelea.empate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _resultButton(
                    context,
                    label: 'No Peleada',
                    icon: Icons.block,
                    color: _kGrey,
                    resultado: domain.ResultadoPelea.noPeleada,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  Widget _resultButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required domain.ResultadoPelea resultado,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context, resultado),
        icon: Icon(icon, size: 20, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
'''

with open('/Volumes/mcOS/derby2_flutter/lib/ui/screens/derby_peleas_screen.dart', 'w') as f:
    f.write(content)

print(f"Written {len(content.splitlines())} lines")
