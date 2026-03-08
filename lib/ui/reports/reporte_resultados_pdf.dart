import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  Constantes de marca
// ═══════════════════════════════════════════════════════════════

const _kAppName = 'DerbyPro Manager';
const _kVersion = 'v1.0';

// Colores PDF
final _kVino = PdfColor.fromHex('#6B1C2A');
final _kVinoClaro = PdfColor.fromHex('#8B2131');
final _kGris = PdfColor.fromHex('#F5F5F5');
final _kGrisTexto = PdfColor.fromHex('#666666');
final _kBlanco = PdfColors.white;
final _kNegro = PdfColors.black;

// Colores de resultado
final _kVerde = PdfColor.fromHex('#2E7D32');
final _kRojo = PdfColor.fromHex('#C62828');
final _kGrisRes = PdfColor.fromHex('#555555');
final _kNaranja = PdfColor.fromHex('#E65100');
final _kAzulRival = PdfColor.fromHex('#1565C0');
final _kRojoFila = PdfColor.fromHex('#D32F2F');

// ═══════════════════════════════════════════════════════════════
//  Modelos de datos para el reporte
// ═══════════════════════════════════════════════════════════════

/// Información de una pelea individual dentro de una ronda.
class PeleaInfoReporte {
  /// Anillo del gallo propio.
  final String anilloPropio;

  /// Anillo del gallo rival.
  final String anilloRival;

  /// Resultado: 'G' (ganó), 'P' (perdió), 'T' (tablas), 'NP', '?', '—'.
  final String resultado;

  /// Fila (1-based) del partido rival en la tabla ordenada por puntos.
  final int filaRival;

  const PeleaInfoReporte({
    required this.anilloPropio,
    required this.anilloRival,
    required this.resultado,
    required this.filaRival,
  });
}

/// Fila del reporte: un partido con sus resultados por ronda.
class FilaResultadoReporte {
  /// Nombre del partido.
  final String nombre;

  /// Puntos acumulados.
  final int puntos;

  /// rondaNum (1-based) → lista de peleas en esa ronda.
  /// Normalmente 1 pelea; 2 para doble pelea.
  final Map<int, List<PeleaInfoReporte>> peleas;

  const FilaResultadoReporte({
    required this.nombre,
    required this.puntos,
    required this.peleas,
  });
}

// ═══════════════════════════════════════════════════════════════
//  Generador de PDF — Hoja de Resultados
// ═══════════════════════════════════════════════════════════════

class ReporteResultadosPdf {
  final String nombreDerby;
  final DateTime fecha;
  final int rondasTotales;

  /// Filas ya ordenadas por puntos (descendente).
  final List<FilaResultadoReporte> filas;

  ReporteResultadosPdf({
    required this.nombreDerby,
    required this.fecha,
    required this.rondasTotales,
    required this.filas,
  });

  /// Abre diálogo de impresión.
  Future<void> imprimir(BuildContext context) async {
    final pdf = await _generarPdf();
    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) => pdf,
      name: 'Resultados_$nombreDerby',
    );
  }

  /// Abre vista previa en pantalla.
  Future<void> vistaPrevia(BuildContext context) async {
    final pdf = await _generarPdf();
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('Resultados — $nombreDerby'),
            centerTitle: true,
          ),
          body: PdfPreview(
            build: (_) => pdf,
            canDebug: false,
            pdfFileName: 'Resultados_$nombreDerby.pdf',
          ),
        ),
      ),
    );
  }

  // ── Construcción del PDF ───────────────────────────────

  Future<Uint8List> _generarPdf() async {
    final doc = pw.Document(
      author: _kAppName,
      title: 'Resultados — $nombreDerby',
      creator: '$_kAppName $_kVersion',
    );

    final fontBold = await PdfGoogleFonts.robotoCondensedBold();
    final fontRegular = await PdfGoogleFonts.robotoCondensedRegular();
    final fontLight = await PdfGoogleFonts.robotoCondensedLight();

    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (ctx) => _buildHeader(ctx, fechaStr, fontBold, fontLight),
        footer: (ctx) => _buildFooter(ctx, fontLight),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          _buildTabla(fontBold, fontRegular, fontLight),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  // ── Header ─────────────────────────────────────────────

  pw.Widget _buildHeader(
    pw.Context ctx,
    String fechaStr,
    pw.Font fontBold,
    pw.Font fontLight,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: _kVino,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'DERBY PRO',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      color: _kBlanco,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.Text(
                    'MANAGER',
                    style: pw.TextStyle(
                      font: fontLight,
                      fontSize: 8,
                      color: _kBlanco,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'RESULTADOS',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: _kVino,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _kVinoClaro,
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      nombreDerby.toUpperCase(),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        color: _kBlanco,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${filas.length} PARTIDOS  •  $rondasTotales RONDAS',
                    style: pw.TextStyle(
                      font: fontLight,
                      fontSize: 8,
                      color: _kGrisTexto,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  fechaStr,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 11,
                    color: _kNegro,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'REPORTE DE RESULTADOS',
                  style: pw.TextStyle(
                    font: fontLight,
                    fontSize: 7,
                    color: _kGrisTexto,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: _kVino, thickness: 1.5),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context ctx, pw.Font fontLight) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '$_kAppName $_kVersion',
          style: pw.TextStyle(font: fontLight, fontSize: 7, color: _kGrisTexto),
        ),
        pw.Text(
          'Pág ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: pw.TextStyle(font: fontLight, fontSize: 8, color: _kGrisTexto),
        ),
      ],
    );
  }

  // ── Tabla principal ────────────────────────────────────

  pw.Widget _buildTabla(
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontLight,
  ) {
    // Landscape letter: ~730pt usables
    const filaWidth = 25.0;
    const partidoWidth = 140.0;
    const puntosWidth = 55.0;
    final rondaWidth =
        (730.0 - filaWidth - partidoWidth - puntosWidth) / rondasTotales;

    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(filaWidth),
      1: const pw.FixedColumnWidth(partidoWidth),
    };
    for (var r = 0; r < rondasTotales; r++) {
      colWidths[2 + r] = pw.FixedColumnWidth(rondaWidth);
    }
    colWidths[2 + rondasTotales] = const pw.FixedColumnWidth(puntosWidth);

    final headerStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 9,
      color: _kBlanco,
    );

    final partidoStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 9,
      color: _kNegro,
    );

    final puntosStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 12,
      color: _kNegro,
    );

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('#CCCCCC'),
        width: 0.5,
      ),
      columnWidths: colWidths,
      children: [
        // ── Encabezado ──
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _kVino),
          children: [
            _headerCell('#', headerStyle),
            _headerCell('Partido', headerStyle, align: pw.Alignment.centerLeft),
            for (var r = 1; r <= rondasTotales; r++)
              _headerCell('RONDA $r', headerStyle),
            _headerCell('Puntos', headerStyle),
          ],
        ),
        // ── Filas de datos ──
        for (var i = 0; i < filas.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? pw.BoxDecoration(color: _kGris) : null,
            children: [
              // Columna # (número de fila)
              _cellContainer(
                pw.Text(
                  '${i + 1}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9,
                    color: _kNegro,
                  ),
                ),
              ),
              // Columna Partido
              _cellContainer(
                pw.Text(
                  '  ${filas[i].nombre.toUpperCase()}',
                  style: partidoStyle,
                ),
                align: pw.Alignment.centerLeft,
              ),
              // Columnas de Rondas
              for (var r = 1; r <= rondasTotales; r++)
                _buildCeldaRonda(filas[i], r, fontBold, fontRegular, fontLight),
              // Columna Puntos
              _cellContainer(pw.Text('${filas[i].puntos}', style: puntosStyle)),
            ],
          ),
      ],
    );
  }

  // ── Celda de ronda ─────────────────────────────────────

  pw.Widget _buildCeldaRonda(
    FilaResultadoReporte fila,
    int rondaNum,
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontLight,
  ) {
    final peleas = fila.peleas[rondaNum];

    // Sin pelea en esta ronda
    if (peleas == null || peleas.isEmpty) {
      return _cellContainer(
        pw.Text('', style: pw.TextStyle(fontSize: 8, color: _kGrisTexto)),
      );
    }

    final widgets = <pw.Widget>[];
    for (var idx = 0; idx < peleas.length; idx++) {
      if (idx > 0) widgets.add(pw.SizedBox(height: 2));
      widgets.add(
        _buildPeleaWidget(peleas[idx], fontBold, fontRegular, fontLight),
      );
    }

    return _cellContainer(
      pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: widgets,
      ),
    );
  }

  /// Renderiza una pelea individual:
  ///   anilloPropio  RESULTADO  ᶠ
  ///                            anilloRival
  pw.Widget _buildPeleaWidget(
    PeleaInfoReporte pelea,
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontLight,
  ) {
    // Color del resultado
    final PdfColor colorResultado;
    switch (pelea.resultado) {
      case 'G':
        colorResultado = _kVerde;
      case 'P':
        colorResultado = _kRojo;
      case 'T':
        colorResultado = _kGrisRes;
      case '?':
        colorResultado = _kNaranja;
      default:
        colorResultado = _kGrisTexto;
    }

    // Estilo para resultado pendiente
    if (pelea.resultado == '—' || pelea.resultado == 'NP') {
      return pw.Text(
        pelea.resultado == '—' ? '—' : 'NP',
        style: pw.TextStyle(font: fontLight, fontSize: 8, color: _kGrisTexto),
      );
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Anillo propio
        pw.Text(
          pelea.anilloPropio,
          style: pw.TextStyle(font: fontRegular, fontSize: 8, color: _kNegro),
        ),
        pw.SizedBox(width: 4),
        // Resultado (G/P/T/?) — grande y en color
        pw.Text(
          pelea.resultado,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 12,
            color: colorResultado,
          ),
        ),
        pw.SizedBox(width: 3),
        // Fila rival (superscript) + anillo rival
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            // Fila rival como "superscript"
            pw.Text(
              '${pelea.filaRival}',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 5.5,
                color: _kRojoFila,
              ),
            ),
            // Anillo rival
            pw.Text(
              pelea.anilloRival,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 7,
                color: _kAzulRival,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────

  pw.Widget _headerCell(
    String text,
    pw.TextStyle style, {
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(text, style: style),
    );
  }

  pw.Widget _cellContainer(
    pw.Widget child, {
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      child: child,
    );
  }
}
