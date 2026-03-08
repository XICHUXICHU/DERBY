import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/sorteo_resultado.dart';

// ═══════════════════════════════════════════════════════════════
//  Constantes de marca (mismas que reporte_anillos_pdf)
// ═══════════════════════════════════════════════════════════════

const _kAppName = 'DerbyPro Manager';
const _kVersion = 'v1.0';

final _kVino = PdfColor.fromHex('#6B1C2A');
final _kVinoClaro = PdfColor.fromHex('#8B2131');
final _kGris = PdfColor.fromHex('#F5F5F5');
final _kGrisTexto = PdfColor.fromHex('#666666');
final _kBlanco = PdfColors.white;
final _kNegro = PdfColors.black;
final _kAzulRival = PdfColor.fromHex('#1565C0');

// ═══════════════════════════════════════════════════════════════
//  Generador de PDF — Hoja de Estilo (Sorteo)
// ═══════════════════════════════════════════════════════════════

class ReporteEstiloPdf {
  final SorteoResultado sorteo;

  ReporteEstiloPdf({required this.sorteo});

  /// Abre diálogo de impresión.
  Future<void> imprimir(BuildContext context) async {
    final pdf = await _generarPdf();
    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) => pdf,
      name: 'Hoja_Estilo_${sorteo.nombreDerby}',
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
            title: Text('Hoja de Estilo — ${sorteo.nombreDerby}'),
            centerTitle: true,
          ),
          body: PdfPreview(
            build: (_) => pdf,
            canDebug: false,
            pdfFileName: 'Hoja_Estilo_${sorteo.nombreDerby}.pdf',
          ),
        ),
      ),
    );
  }

  // ── Construcción PDF ───────────────────────────────────

  Future<Uint8List> _generarPdf() async {
    final doc = pw.Document(
      author: _kAppName,
      title: 'Hoja de Estilo — ${sorteo.nombreDerby}',
      creator: '$_kAppName $_kVersion',
    );

    final fontBold = await PdfGoogleFonts.robotoCondensedBold();
    final fontRegular = await PdfGoogleFonts.robotoCondensedRegular();
    final fontLight = await PdfGoogleFonts.robotoCondensedLight();

    final fechaStr =
        '${sorteo.fecha.day.toString().padLeft(2, '0')}/'
        '${sorteo.fecha.month.toString().padLeft(2, '0')}/'
        '${sorteo.fecha.year}';

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
          if (sorteo.advertencias.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromHex('#FFA000'),
                  width: 0.8,
                ),
                borderRadius: pw.BorderRadius.circular(4),
                color: PdfColor.fromHex('#FFF8E1'),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ADVERTENCIAS:',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 8,
                      color: PdfColor.fromHex('#E65100'),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  ...sorteo.advertencias.map(
                    (a) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 1),
                      child: pw.Text(
                        '• $a',
                        style: pw.TextStyle(
                          font: fontLight,
                          fontSize: 7,
                          color: PdfColor.fromHex('#BF360C'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                    'HOJA DE ESTILO',
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
                      sorteo.nombreDerby.toUpperCase(),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        color: _kBlanco,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${sorteo.rondasGeneradas} RONDAS  •  ${sorteo.partidos.length} PARTIDOS',
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
                  'SORTEO GENERADO',
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

  // ── Tabla principal (vista por partido, estilo tuums) ──

  pw.Widget _buildTabla(
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontLight,
  ) {
    final nRondas = sorteo.rondasGeneradas;

    // Estilos
    final headerStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 9,
      color: _kBlanco,
    );
    final partidoStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 8,
      color: _kNegro,
    );
    final puntosStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 9,
      color: _kNegro,
    );

    // Anchos: # (25), Partido (150), Rondas repartidas, Puntos (50)
    // Landscape letter: ~730pt usables
    const filaWidth = 25.0;
    const partidoWidth = 150.0;
    const puntosWidth = 50.0;
    final rondaWidth =
        (730.0 - filaWidth - partidoWidth - puntosWidth) / nRondas;

    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(filaWidth),
      1: const pw.FixedColumnWidth(partidoWidth),
    };
    for (var r = 0; r < nRondas; r++) {
      colWidths[2 + r] = pw.FixedColumnWidth(rondaWidth);
    }
    colWidths[2 + nRondas] = const pw.FixedColumnWidth(puntosWidth);

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
            for (var r = 1; r <= nRondas; r++)
              _headerCell('RONDA $r', headerStyle),
            _headerCell('Puntos', headerStyle),
          ],
        ),
        // ── Filas de datos (1 por partido) ──
        for (var i = 0; i < sorteo.partidos.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? pw.BoxDecoration(color: _kGris) : null,
            children: [
              // Columna # (número de fila)
              _cellContainer(
                pw.Text(
                  '${sorteo.partidos[i].fila}',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 8,
                    color: _kNegro,
                  ),
                ),
              ),
              // Columna Partido (nombre)
              _cellContainer(
                pw.Text(
                  '  ${sorteo.partidos[i].nombrePartido.toUpperCase()}',
                  style: partidoStyle,
                ),
                align: pw.Alignment.centerLeft,
              ),
              // Columnas de Rondas
              for (var r = 1; r <= nRondas; r++)
                _buildCeldaRonda(
                  sorteo.partidos[i],
                  r,
                  fontBold,
                  fontRegular,
                  fontLight,
                ),
              // Columna Puntos
              _cellContainer(pw.Text('0', style: puntosStyle)),
            ],
          ),
      ],
    );
  }

  /// Celda de ronda estilo tuums: anilloPropio VS anilloRival + fila rival.
  ///
  /// Layout:
  ///   anilloPropio  VS  filaRival
  ///                     anilloRival
  pw.Widget _buildCeldaRonda(
    PartidoResultado partido,
    int rondaNum,
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontLight,
  ) {
    // Un partido puede tener múltiples resultados en la misma ronda (doble pelea)
    final rondas = partido.rondas
        .where((r) => r.numeroRonda == rondaNum)
        .toList();

    if (rondas.isEmpty) {
      return _cellContainer(
        pw.Text('—', style: pw.TextStyle(fontSize: 8, color: _kGrisTexto)),
      );
    }

    // BYE
    if (rondas.length == 1 && rondas.first.esBye) {
      return _cellContainer(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E8F5E9'),
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border.all(
              color: PdfColor.fromHex('#4CAF50'),
              width: 0.5,
            ),
          ),
          child: pw.Text(
            'BYE',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9,
              color: PdfColor.fromHex('#2E7D32'),
            ),
          ),
        ),
      );
    }

    final anilloPropioStyle = pw.TextStyle(
      font: fontRegular,
      fontSize: 9,
      color: _kNegro,
    );
    final vsStyle = pw.TextStyle(font: fontBold, fontSize: 8, color: _kNegro);
    final filaRivalStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 7,
      color: PdfColor.fromHex('#D84315'), // rojo-naranja para la fila
    );
    final anilloRivalStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 8,
      color: _kAzulRival,
    );
    final difStyle = pw.TextStyle(
      font: fontLight,
      fontSize: 7,
      color: PdfColor.fromHex('#757575'),
    );

    // Si hay doble pelea (2 enfrentamientos en la misma ronda), apilar ambos
    final widgets = <pw.Widget>[];
    for (var idx = 0; idx < rondas.length; idx++) {
      final ronda = rondas[idx];
      if (idx > 0) widgets.add(pw.SizedBox(height: 3));

      // Calcular diferencia de peso
      final dif = (ronda.pesoPropio - ronda.pesoRival).abs();
      final difStr = '${dif.toStringAsFixed(0)}g';

      widgets.add(
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Anillo propio
                pw.Text(ronda.anilloPropio, style: anilloPropioStyle),
                pw.SizedBox(width: 6),
                // VS
                pw.Text('VS', style: vsStyle),
                pw.SizedBox(width: 6),
                // Fila rival (superscript-style, arriba) + anillo rival (abajo)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${ronda.filaPartidoRival}', style: filaRivalStyle),
                    pw.Text(ronda.anilloRival, style: anilloRivalStyle),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 1),
            pw.Text('dif $difStr', style: difStyle),
          ],
        ),
      );
    }

    return _cellContainer(
      pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: widgets,
      ),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      child: child,
    );
  }
}
