import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/database/app_database.dart';

// ═══════════════════════════════════════════════════════════════
//  Constantes de diseño
// ═══════════════════════════════════════════════════════════════

const _kVino = PdfColor.fromInt(0xFF6B1C2A);
const _kBlanco = PdfColor.fromInt(0xFFFFFFFF);
const _kGrisFondo = PdfColor.fromInt(0xFFF5F5F5);
const _kGrisBorde = PdfColor.fromInt(0xFFE0E0E0);
const _kTextoOscuro = PdfColor.fromInt(0xFF1E293B);
const _kVerdeExito = PdfColor.fromInt(0xFF0F766E);
const _kRojoPeligro = PdfColor.fromInt(0xFFB91C1C);

const _kAppName = 'Derby Pro G.E.';
const _kVersion = 'v1.0';

// ═══════════════════════════════════════════════════════════════

class ReporteCompadresPdf {
  final String nombreDerby;
  final DateTime fecha;
  final List<Partido> partidos; // Partidos que tienen compadres
  final Map<int, List<Partido>>
  compadresPorPartido; // Mapa partidoId -> lista de partidos compadres
  final Map<int, int> partidoFila; // Mapa partidoId -> fila/numero original

  ReporteCompadresPdf({
    required this.nombreDerby,
    required this.fecha,
    required this.partidos,
    required this.compadresPorPartido,
    required this.partidoFila,
  });

  Future<void> imprimir(BuildContext context) async {
    final pdf = await _generarPdf();
    if (!context.mounted) return;
    await Printing.layoutPdf(
      onLayout: (_) => pdf,
      name: 'Lista_Compadres_$nombreDerby',
    );
  }

  Future<void> vistaPrevia(BuildContext context) async {
    final pdf = await _generarPdf();
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('Equipos y Compadres — $nombreDerby'),
            centerTitle: true,
          ),
          body: PdfPreview(
            build: (_) => pdf,
            canDebug: false,
            pdfFileName: 'Lista_Compadres_$nombreDerby.pdf',
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _generarPdf() async {
    final doc = pw.Document(
      author: _kAppName,
      title: 'Lista de Compadres — $nombreDerby',
      creator: '$_kAppName $_kVersion',
    );

    final fontBold = await PdfGoogleFonts.robotoCondensedBold();
    final fontRegular = await PdfGoogleFonts.robotoCondensedRegular();
    final fontLight = await PdfGoogleFonts.robotoCondensedLight();

    // Iconos de Material
    final iconDataUser = await PdfGoogleFonts.materialIcons();

    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';

    // Ordenar los partidos por fila (1, 2, 3...)
    final partidosOrdenados = List<Partido>.from(partidos)
      ..sort(
        (a, b) =>
            (partidoFila[a.id] ?? 999).compareTo(partidoFila[b.id] ?? 999),
      );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter, // Formato vertical para este reporte
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          icons: iconDataUser,
        ),
        header: (ctx) => _buildHeader(ctx, fechaStr, fontBold, fontLight),
        footer: (ctx) => _buildFooter(ctx, fontLight),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          ..._buildCardsList(partidosOrdenados, fontBold, fontRegular),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFFBEB'),
              border: pw.Border.all(color: PdfColor.fromHex('#FDE68A')),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.Icon(
                  const pw.IconData(0xe88f),
                  color: PdfColor.fromHex('#D97706'),
                  size: 24,
                ), // info_outline
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    'NOTA: Los equipos indicados como compadres NO PUDEN EMPAREJARSE ENTRE SÍ durante el sorteo, independientemente de la ronda y diferencia de pesos.',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 9,
                      color: PdfColor.fromHex('#92400E'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

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
                      fontSize: 16,
                      color: _kBlanco,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'GESTIÓN DE EMPAREJAMIENTOS',
                    style: pw.TextStyle(
                      font: fontLight,
                      fontSize: 6,
                      color: _kBlanco,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    nombreDerby.toUpperCase(),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      color: _kVino,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'REPORTE DE EQUIPOS Y COMPADRES',
                    style: pw.TextStyle(
                      font: fontLight,
                      fontSize: 10,
                      color: _kTextoOscuro,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Fecha de impresión:',
                  style: pw.TextStyle(
                    font: fontLight,
                    fontSize: 8,
                    color: _kTextoOscuro,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  fechaStr,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: _kVino,
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

  pw.Widget _buildFooter(pw.Context ctx, pw.Font fontLight) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '$_kAppName $_kVersion',
          style: pw.TextStyle(
            font: fontLight,
            fontSize: 7,
            color: _kTextoOscuro,
          ),
        ),
        pw.Text(
          'Pág ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: pw.TextStyle(
            font: fontLight,
            fontSize: 8,
            color: _kTextoOscuro,
          ),
        ),
      ],
    );
  }

  List<pw.Widget> _buildCardsList(
    List<Partido> equipos,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return equipos.map((partido) {
      final compadres = compadresPorPartido[partido.id] ?? [];
      final numFila = partidoFila[partido.id] ?? '?';

      // Ordenar compadres por fila
      compadres.sort(
        (a, b) =>
            (partidoFila[a.id] ?? 999).compareTo(partidoFila[b.id] ?? 999),
      );

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        decoration: pw.BoxDecoration(
          color: _kBlanco,
          border: pw.Border.all(color: _kGrisBorde, width: 0.8),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left colored bar that holds the row number (fila)
            pw.Container(
              width: 50,
              padding: const pw.EdgeInsets.symmetric(vertical: 16),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: _kVino,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(5.2),
                  bottomLeft: pw.Radius.circular(5.2),
                ),
              ),
              child: pw.Center(
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'FILA',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: PdfColor.fromHex('#E2E8F0'),
                      ),
                    ),
                    pw.Text(
                      '#$numFila',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 18,
                        color: _kBlanco,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Middle section with party name
            pw.Expanded(
              flex: 3,
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Row(
                      children: [
                        pw.Icon(
                          const pw.IconData(0xe7fd),
                          size: 16,
                          color: _kVino,
                        ), // person
                        pw.SizedBox(width: 6),
                        pw.Text(
                          partido.nombre.toUpperCase(),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            color: _kTextoOscuro,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${compadres.length} COMPADRE${compadres.length == 1 ? '' : 'S'} REGISTRADO${compadres.length == 1 ? '' : 'S'}',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 9,
                        color: _kVerdeExito,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right section: list of compadres
            pw.Expanded(
              flex: 4,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  color: _kGrisFondo,
                  border: pw.Border(
                    left: pw.BorderSide(color: _kGrisBorde, width: 0.8),
                  ),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: compadres.map((compadre) {
                    final filaC = partidoFila[compadre.id] ?? '?';
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _kBlanco,
                        border: pw.Border.all(
                          color: PdfColor.fromHex('#E2C4C9'),
                          width: 0.5,
                        ),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Icon(
                            const pw.IconData(0xe8e2),
                            color: _kRojoPeligro,
                            size: 11,
                          ), // compare_arrows / sync
                          pw.SizedBox(width: 4),
                          pw.Text(
                            '[#$filaC]',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 10,
                              color: _kVino,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            compadre.nombre.toUpperCase(),
                            style: pw.TextStyle(
                              font: fontRegular,
                              fontSize: 10,
                              color: _kTextoOscuro,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
