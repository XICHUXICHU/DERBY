import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

import '../../domain/domain.dart' as domain;

class ReporteRondaPdf {
  final String nombreDerby;
  final domain.Ronda ronda;
  final List<domain.Partido> partidos;

  ReporteRondaPdf({
    required this.nombreDerby,
    required this.ronda,
    required this.partidos,
  });

  Future<void> imprimir(BuildContext context) async {
    final pdf = await _generarPdf();
    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) => pdf,
      name: 'Ronda_${ronda.numero}_$nombreDerby',
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
            title: Text(ronda.esRondaBase ? 'Ronda Base — $nombreDerby' : 'Ronda ${ronda.numero} — $nombreDerby'),
            centerTitle: true,
          ),
          body: PdfPreview(
            build: (_) => pdf,
            pdfFileName: 'Ronda_${ronda.numero}_$nombreDerby.pdf',
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _generarPdf() async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final headerStyle = pw.TextStyle(
      font: fontBold,
      fontSize: 10,
      color: PdfColors.white,
    );

    final cellStyle = pw.TextStyle(font: fontRegular, fontSize: 10);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 10);

    final mapPartidos = {for (final p in partidos) p.id: p};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(fontBold),
        build: (ctx) {
          return [
            pw.SizedBox(height: 16),
            _buildTable(headerStyle, cellStyle, boldStyle, mapPartidos),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Derby: $nombreDerby',
          style: pw.TextStyle(font: fontBold, fontSize: 16),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          ronda.esRondaBase 
            ? 'ROLES DE PELEA - RONDA BASE'
            : 'ROLES DE PELEA - RONDA ${ronda.numero}',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 18,
            color: PdfColor.fromHex('#6B1C2A'),
          ),
        ),
        pw.Divider(color: PdfColors.grey),
      ],
    );
  }

  pw.Widget _buildTable(
    pw.TextStyle headerStyle,
    pw.TextStyle cellStyle,
    pw.TextStyle boldStyle,
    Map<int, domain.Partido> mapPartidos,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FixedColumnWidth(30),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#6B1C2A')),
          children: [
            _headerCell('#', headerStyle),
            _headerCell('Partido A', headerStyle),
            _headerCell('Gallo A', headerStyle),
            _headerCell('VS', headerStyle),
            _headerCell('Gallo B', headerStyle),
            _headerCell('Partido B', headerStyle),
          ],
        ),
        // Fila de cada pelea
        for (var i = 0; i < ronda.enfrentamientos.length; i++)
          _buildRow(
            i + 1,
            ronda.enfrentamientos[i],
            cellStyle,
            boldStyle,
            mapPartidos,
          ),
      ],
    );
  }

  pw.TableRow _buildRow(
    int numPelea,
    domain.Enfrentamiento e,
    pw.TextStyle cellStyle,
    pw.TextStyle boldStyle,
    Map<int, domain.Partido> mapPartidos,
  ) {
    final pA = mapPartidos[e.galloA.partidoId]?.nombre ?? 'Desconocido';
    final pB = mapPartidos[e.galloB.partidoId]?.nombre ?? 'Desconocido';

    return pw.TableRow(
      children: [
        _cell(numPelea.toString(), boldStyle, align: pw.Alignment.center),
        _cell(pA, cellStyle, align: pw.Alignment.centerLeft),
        _cellPeleador(e.galloA.anillo, e.galloA.pesoGramos, cellStyle, boldStyle),
        _cell('VS', boldStyle.copyWith(color: PdfColor.fromHex('#C62828')), align: pw.Alignment.center),
        _cellPeleador(e.galloB.anillo, e.galloB.pesoGramos, cellStyle, boldStyle),
        _cell(pB, cellStyle, align: pw.Alignment.centerLeft),
      ],
    );
  }

  pw.Widget _cellPeleador(String anillo, double peso, pw.TextStyle txt, pw.TextStyle bld) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      alignment: pw.Alignment.center,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(anillo, style: bld),
          pw.Text('${peso.toStringAsFixed(0)}g', style: txt.copyWith(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _headerCell(String text, pw.TextStyle style, {pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }

  pw.Widget _cell(String text, pw.TextStyle style, {pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: align,
      child: pw.Text(text, style: style),
    );
  }
}
