import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

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

// ═══════════════════════════════════════════════════════════════
//  Modelo de datos para el reporte
// ═══════════════════════════════════════════════════════════════

class _ReporteRow {
  final int numero;
  final String nombrePartido;
  final String? anilloBase;
  final double? pesoBase;
  final String? anillo1;
  final double? peso1;
  final String? anillo2;
  final double? peso2;
  final String? anillo3;
  final double? peso3;

  _ReporteRow({
    required this.numero,
    required this.nombrePartido,
    this.anilloBase,
    this.pesoBase,
    this.anillo1,
    this.peso1,
    this.anillo2,
    this.peso2,
    this.anillo3,
    this.peso3,
  });
}

// ═══════════════════════════════════════════════════════════════
//  Modos de impresión
// ═══════════════════════════════════════════════════════════════

enum ModoReporte {
  conDatos,
  limpio,
}

// ═══════════════════════════════════════════════════════════════
//  Generador de PDF
// ═══════════════════════════════════════════════════════════════

class ReporteAnillosPdf {
  final String nombreDerby;
  final DateTime fecha;
  final List<Partido> partidos;
  final Map<int, List<GalloEntry>> gallosPorPartido;

  ReporteAnillosPdf({
    required this.nombreDerby,
    required this.fecha,
    required this.partidos,
    required this.gallosPorPartido,
  });

  /// Genera el PDF y abre el diálogo de impresión / vista previa.
  Future<void> imprimir(BuildContext context, ModoReporte modo) async {
    final pdf = await _generarPdf(modo);

    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) => pdf,
      name: modo == ModoReporte.conDatos
          ? 'Hoja_Anillos_$nombreDerby'
          : 'Hoja_Anillos_Limpia_$nombreDerby',
    );
  }

  /// Genera el PDF y abre vista previa en pantalla.
  Future<void> vistaPrevia(BuildContext context, ModoReporte modo) async {
    final pdf = await _generarPdf(modo);

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(modo == ModoReporte.conDatos
                ? 'Hoja de Anillos — $nombreDerby'
                : 'Hoja de Anillos (Limpia)'),
            centerTitle: true,
          ),
          body: PdfPreview(
            build: (_) => pdf,
            canDebug: false,
            pdfFileName: modo == ModoReporte.conDatos
                ? 'Hoja_Anillos_$nombreDerby.pdf'
                : 'Hoja_Anillos_Limpia_$nombreDerby.pdf',
          ),
        ),
      ),
    );
  }

  // ── Construcción PDF ───────────────────────────────────

  Future<Uint8List> _generarPdf(ModoReporte modo) async {
    final doc = pw.Document(
      author: _kAppName,
      title: 'Hoja de Anillos — $nombreDerby',
      creator: '$_kAppName $_kVersion',
    );

    // Preparar filas
    final rows = _prepararFilas(modo);

    // Fuentes
    final fontBold = await PdfGoogleFonts.robotoCondensedBold();
    final fontRegular = await PdfGoogleFonts.robotoCondensedRegular();
    final fontLight = await PdfGoogleFonts.robotoCondensedLight();

    // Fecha formateada
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (ctx) => _buildHeader(ctx, fechaStr, modo, fontBold, fontLight),
        footer: (ctx) => _buildFooter(ctx, fontLight),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          _buildTabla(rows, modo, fontBold, fontRegular, fontLight),
          if (modo == ModoReporte.limpio) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Observaciones: ____________________________________________'
              '______________________________________________',
              style: pw.TextStyle(font: fontLight, fontSize: 9, color: _kGrisTexto),
            ),
          ],
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  // ── Header del PDF ─────────────────────────────────────

  pw.Widget _buildHeader(
    pw.Context ctx,
    String fechaStr,
    ModoReporte modo,
    pw.Font fontBold,
    pw.Font fontLight,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            // Logo / Nombre del programa
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
            // Título central
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'HOJA DE ANILLOS DE CADA GALLO',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                      color: _kVino,
                      letterSpacing: 1.5,
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
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            // Fecha
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
                  modo == ModoReporte.conDatos
                      ? 'CON DATOS'
                      : 'FORMATO EN BLANCO',
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

  // ── Footer del PDF ─────────────────────────────────────

  pw.Widget _buildFooter(pw.Context ctx, pw.Font fontLight) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '$_kAppName $_kVersion',
          style: pw.TextStyle(
            font: fontLight,
            fontSize: 7,
            color: _kGrisTexto,
          ),
        ),
        pw.Text(
          'Pág ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: pw.TextStyle(
            font: fontLight,
            fontSize: 8,
            color: _kGrisTexto,
          ),
        ),
      ],
    );
  }

  // ── Tabla principal ────────────────────────────────────

  pw.Widget _buildTabla(
    List<_ReporteRow> rows,
    ModoReporte modo,
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontLight,
  ) {
    final headerStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 9,
      color: _kBlanco,
    );

    // Anchos relativos de columnas
    const colWidths = {
      0: pw.FixedColumnWidth(32),  // #
      1: pw.FixedColumnWidth(180), // Partido
      2: pw.FixedColumnWidth(95),  // Gallo Base
      3: pw.FixedColumnWidth(95),  // Gallo 1 P.L.
      4: pw.FixedColumnWidth(95),  // Gallo 2 P.L.
      5: pw.FixedColumnWidth(95),  // Gallo 3 P.L.
    };

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#CCCCCC'), width: 0.5),
      columnWidths: colWidths,
      headerCount: 1,
      headerDecoration: pw.BoxDecoration(color: _kVino),
      headerAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
      headerStyle: headerStyle,
      headerPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      headers: [
        '#',
        '   PARTIDO',
        'GALLO BASE',
        'GALLO 1 P.L.',
        'GALLO 2 P.L.',
        'GALLO 3 P.L.',
      ],
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      oddRowDecoration: pw.BoxDecoration(color: _kGris),
      cellHeight: modo == ModoReporte.conDatos ? 28 : 22,
      data: rows.map((r) {
        if (modo == ModoReporte.conDatos) {
          return [
            '${r.numero}',
            '  ${r.nombrePartido.toUpperCase()}',
            _formatGallo(r.anilloBase, r.pesoBase),
            _formatGallo(r.anillo1, r.peso1),
            _formatGallo(r.anillo2, r.peso2),
            _formatGallo(r.anillo3, r.peso3),
          ];
        } else {
          return [
            '${r.numero}',
            '',
            '',
            '',
            '',
            '',
          ];
        }
      }).toList(),
    );
  }

  String _formatGallo(String? anillo, double? peso) {
    if (anillo == null || anillo.isEmpty) return '—';
    final pesoStr = peso != null ? ' (${peso.toStringAsFixed(0)}g)' : '';
    return '$anillo$pesoStr';
  }

  // ── Preparación de datos ───────────────────────────────

  List<_ReporteRow> _prepararFilas(ModoReporte modo) {
    if (modo == ModoReporte.limpio) {
      // Generar filas vacías basadas en la cantidad de partidos (mínimo 20)
      final cant = partidos.length > 20 ? partidos.length : 20;
      return List.generate(
        cant,
        (i) => _ReporteRow(numero: i + 1, nombrePartido: ''),
      );
    }

    // Con datos
    final rows = <_ReporteRow>[];
    for (var i = 0; i < partidos.length; i++) {
      final p = partidos[i];
      final gallos = gallosPorPartido[p.id] ?? [];
      final base = gallos.where((g) => g.esBase).firstOrNull;
      final pls = gallos.where((g) => !g.esBase).toList();

      rows.add(_ReporteRow(
        numero: i + 1,
        nombrePartido: p.nombre,
        anilloBase: base?.anillo,
        pesoBase: base?.pesoGramos,
        anillo1: pls.isNotEmpty ? pls[0].anillo : null,
        peso1: pls.isNotEmpty ? pls[0].pesoGramos : null,
        anillo2: pls.length > 1 ? pls[1].anillo : null,
        peso2: pls.length > 1 ? pls[1].pesoGramos : null,
        anillo3: pls.length > 2 ? pls[2].anillo : null,
        peso3: pls.length > 2 ? pls[2].pesoGramos : null,
      ));
    }
    return rows;
  }
}
