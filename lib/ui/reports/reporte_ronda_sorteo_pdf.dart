import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/sorteo_resultado.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Colores de marca
// ─────────────────────────────────────────────────────────────────────────────
final _kVino = PdfColor.fromHex('#6B1C2A');
final _kVinoClaro = PdfColor.fromHex('#8B2131');
final _kVinoUltraLight = PdfColor.fromHex('#F9EFF1');
final _kAzul = PdfColor.fromHex('#1565C0');
final _kAzulLight = PdfColor.fromHex('#E3F2FD');
final _kGris = PdfColor.fromHex('#F7F7F7');
final _kGrisMedio = PdfColor.fromHex('#E0E0E0');
final _kGrisTexto = PdfColor.fromHex('#555555');
final _kNegro = PdfColors.black;
final _kBlanco = PdfColors.white;
final _kVerde = PdfColor.fromHex('#2E7D32');
final _kVerdeBg = PdfColor.fromHex('#E8F5E9');
final _kRojo = PdfColor.fromHex('#B71C1C');

const _kAppName = 'DerbyPro Manager';
const _kVersion = 'v1.0';

// ─────────────────────────────────────────────────────────────────────────────
//  Modelo interno de pelea ya desduplicada
// ─────────────────────────────────────────────────────────────────────────────
class _Pelea {
  final int numero;
  final int filaA;
  final String nombreA;
  final String anilloA;
  final double pesoA;
  final int filaB;
  final String nombreB;
  final String anilloB;
  final double pesoB;
  final double diff;
  final bool aEsDoble;
  final bool bEsDoble;

  _Pelea({
    required this.numero,
    required this.filaA,
    required this.nombreA,
    required this.anilloA,
    required this.pesoA,
    required this.filaB,
    required this.nombreB,
    required this.anilloB,
    required this.pesoB,
    required this.diff,
    this.aEsDoble = false,
    this.bEsDoble = false,
  });
}

class _PartidoBye {
  final int fila;
  final String nombre;
  const _PartidoBye(this.fila, this.nombre);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reporte por ronda — usa SorteoResultado (post-sorteo)
// ─────────────────────────────────────────────────────────────────────────────
class ReporteRondaSorteoPdf {
  final SorteoResultado sorteo;

  const ReporteRondaSorteoPdf({required this.sorteo});

  // ── API pública ────────────────────────────────────────

  Future<void> imprimirRonda(BuildContext context, int rondaNum) async {
    final pdf = await _generarPdf(rondaNum);
    if (!context.mounted) return;
    await Printing.layoutPdf(
      onLayout: (_) => pdf,
      name:
          'Ronda_${_labelRonda(rondaNum, sorteo.rondasGeneradas)}_${sorteo.nombreDerby}',
    );
  }

  Future<void> vistaPreviaRonda(BuildContext context, int rondaNum) async {
    final pdf = await _generarPdf(rondaNum);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              '${_labelRonda(rondaNum, sorteo.rondasGeneradas)} — ${sorteo.nombreDerby}',
            ),
            centerTitle: true,
          ),
          body: PdfPreview(
            build: (_) => pdf,
            canDebug: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            pdfFileName:
                'Ronda_${_labelRonda(rondaNum, sorteo.rondasGeneradas)}_${sorteo.nombreDerby}.pdf',
          ),
        ),
      ),
    );
  }

  // ── Generación del PDF ─────────────────────────────────

  Future<Uint8List> _generarPdf(int rondaNum) async {
    final doc = pw.Document(
      author: _kAppName,
      title:
          '${_labelRonda(rondaNum, sorteo.rondasGeneradas)} — ${sorteo.nombreDerby}',
      creator: '$_kAppName $_kVersion',
    );

    final fontBold = await PdfGoogleFonts.robotoCondensedBold();
    final fontRegular = await PdfGoogleFonts.robotoCondensedRegular();
    final fontLight = await PdfGoogleFonts.robotoCondensedLight();

    final fechaStr = _formatFecha(sorteo.fecha);
    final peleas = _extraerPeleas(rondaNum);
    final byes = _extraerByes(rondaNum);
    final esBase = rondaNum == sorteo.rondasGeneradas;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 28),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (ctx) => _buildHeader(
          ctx,
          rondaNum,
          esBase,
          fechaStr,
          peleas.length,
          fontBold,
          fontLight,
        ),
        footer: (ctx) => _buildFooter(ctx, rondaNum, fontLight),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          _buildTabla(peleas, fontBold, fontRegular, fontLight),
          if (byes.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _buildSeccionByes(byes, fontBold, fontLight),
          ],
          pw.SizedBox(height: 6),
          _buildLeyenda(peleas, fontLight),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  // ── Header ─────────────────────────────────────────────

  pw.Widget _buildHeader(
    pw.Context ctx,
    int rondaNum,
    bool esBase,
    String fechaStr,
    int numPeleas,
    pw.Font fontBold,
    pw.Font fontLight,
  ) {
    final labelRonda = esBase ? 'RONDA BASE' : 'RONDA  $rondaNum';

    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // ── Logo badge ───────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: _kVino,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'DERBY PRO',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 13,
                      color: _kBlanco,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.Text(
                    'MANAGER',
                    style: pw.TextStyle(
                      font: fontLight,
                      fontSize: 7,
                      color: _kBlanco,
                      letterSpacing: 4.5,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 18),

            // ── Centro: título ───────────────────────────
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'ROLES DE PELEA',
                    style: pw.TextStyle(
                      font: fontLight,
                      fontSize: 9,
                      color: _kGrisTexto,
                      letterSpacing: 3,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _kVino,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      labelRonda,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 22,
                        color: _kBlanco,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _kVinoUltraLight,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(color: _kVinoClaro, width: 0.4),
                    ),
                    child: pw.Text(
                      sorteo.nombreDerby.toUpperCase(),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: _kVino,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(width: 18),

            // ── Info derecha ─────────────────────────────
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
                pw.SizedBox(height: 3),
                _pill(
                  '$numPeleas ${numPeleas == 1 ? 'PELEA' : 'PELEAS'}',
                  _kVino,
                  fontBold,
                  fontLight,
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Ronda $rondaNum de ${sorteo.rondasGeneradas}',
                  style: pw.TextStyle(
                    font: fontLight,
                    fontSize: 8,
                    color: _kGrisTexto,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Container(height: 2, color: _kVino),
        pw.Container(height: 2),
        pw.Container(height: 0.5, color: _kGrisMedio),
      ],
    );
  }

  // ── Footer ─────────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context ctx, int rondaNum, pw.Font fontLight) {
    return pw.Column(
      children: [
        pw.Divider(color: _kGrisMedio, thickness: 0.5),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '$_kAppName $_kVersion — Ronda $rondaNum de ${sorteo.rondasGeneradas}',
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
        ),
      ],
    );
  }

  // ── Tabla de peleas ────────────────────────────────────

  pw.Widget _buildTabla(
    List<_Pelea> peleas,
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontLight,
  ) {
    final hStyle = pw.TextStyle(font: fontBold, fontSize: 8, color: _kBlanco);

    return pw.Table(
      border: pw.TableBorder.all(color: _kGrisMedio, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28), // #
        1: const pw.FixedColumnWidth(18), // fila A
        2: const pw.FlexColumnWidth(2.2), // nombre A
        3: const pw.FixedColumnWidth(70), // gallo A (anillo + peso)
        4: const pw.FixedColumnWidth(52), // VS + diff
        5: const pw.FixedColumnWidth(70), // gallo B (anillo + peso)
        6: const pw.FlexColumnWidth(2.2), // nombre B
        7: const pw.FixedColumnWidth(18), // fila B
      },
      children: [
        // ── Encabezado ────────────────────────────────────
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _kVino),
          children: [
            _hCell('#', hStyle),
            _hCell('No.', hStyle),
            _hCell('PARTIDO', hStyle, align: pw.Alignment.centerLeft),
            _hCell('GALLO  /  PESO', hStyle),
            _hCell('VS', hStyle),
            _hCell('GALLO  /  PESO', hStyle),
            _hCell('PARTIDO', hStyle, align: pw.Alignment.centerRight),
            _hCell('No.', hStyle),
          ],
        ),
        // ── Sub-encabezado descriptivo ────────────────────
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F0E4E7')),
          children: [
            _hCell(
              '',
              pw.TextStyle(font: fontLight, fontSize: 6, color: _kVino),
            ),
            _hCell(
              '',
              pw.TextStyle(font: fontLight, fontSize: 6, color: _kVino),
            ),
            _hCell(
              '  EQUIPO  A',
              pw.TextStyle(
                font: fontLight,
                fontSize: 6.5,
                color: _kVino,
                letterSpacing: 1,
              ),
              align: pw.Alignment.centerLeft,
            ),
            _hCell(
              'ANILLO',
              pw.TextStyle(font: fontLight, fontSize: 6.5, color: _kVino),
            ),
            _hCell(
              'DIFERENCIA',
              pw.TextStyle(font: fontLight, fontSize: 6, color: _kVino),
            ),
            _hCell(
              'ANILLO',
              pw.TextStyle(font: fontLight, fontSize: 6.5, color: _kVino),
            ),
            _hCell(
              'EQUIPO  B  ',
              pw.TextStyle(
                font: fontLight,
                fontSize: 6.5,
                color: _kVino,
                letterSpacing: 1,
              ),
              align: pw.Alignment.centerRight,
            ),
            _hCell(
              '',
              pw.TextStyle(font: fontLight, fontSize: 6, color: _kVino),
            ),
          ],
        ),
        // ── Filas de peleas ───────────────────────────────
        for (var i = 0; i < peleas.length; i++)
          _buildFila(peleas[i], i.isOdd, fontBold, fontRegular, fontLight),
      ],
    );
  }

  pw.TableRow _buildFila(
    _Pelea p,
    bool sombreada,
    pw.Font fontBold,
    pw.Font fontRegular,
    pw.Font fontLight,
  ) {
    final bg = sombreada ? _kGris : _kBlanco;
    final diffStr = p.diff.toStringAsFixed(0);

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        // # pelea
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 3),
          child: pw.Text(
            '${p.numero}',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 9,
              color: _kGrisTexto,
            ),
          ),
        ),
        // Fila A
        _filaBadge(p.filaA, fontBold, side: 'A'),
        // Nombre A
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(6, 6, 4, 6),
          alignment: pw.Alignment.centerLeft,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                p.nombreA.toUpperCase(),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8.5,
                  color: _kNegro,
                ),
              ),
              if (p.aEsDoble)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: _etiquetaDoble(fontBold),
                ),
            ],
          ),
        ),
        // Gallo A
        _galloCell(p.anilloA, p.pesoA, fontBold, fontLight, esA: true),
        // VS + diff
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'VS',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: _kRojo,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: _kGris,
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(color: _kGrisMedio, width: 0.5),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'dif ',
                      style: pw.TextStyle(
                        font: fontLight,
                        fontSize: 6,
                        color: _kGrisTexto,
                      ),
                    ),
                    pw.Text(
                      '${diffStr}g',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: _kNegro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Gallo B
        _galloCell(p.anilloB, p.pesoB, fontBold, fontLight, esA: false),
        // Nombre B
        pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(4, 6, 6, 6),
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                p.nombreB.toUpperCase(),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8.5,
                  color: _kNegro,
                ),
              ),
              if (p.bEsDoble)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: _etiquetaDoble(fontBold),
                ),
            ],
          ),
        ),
        // Fila B
        _filaBadge(p.filaB, fontBold, side: 'B'),
      ],
    );
  }

  // ── Sección BYEs ───────────────────────────────────────

  pw.Widget _buildSeccionByes(
    List<_PartidoBye> byes,
    pw.Font fontBold,
    pw.Font fontLight,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: pw.BoxDecoration(
        color: _kVerdeBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _kVerde, width: 0.6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: _kVerde,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              'BYE',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8,
                color: _kBlanco,
                letterSpacing: 1,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            'Partidos con descanso en esta ronda:  ',
            style: pw.TextStyle(font: fontLight, fontSize: 8, color: _kVerde),
          ),
          pw.Expanded(
            child: pw.Wrap(
              spacing: 8,
              children: byes
                  .map(
                    (b) => pw.Text(
                      '${b.fila}. ${b.nombre.toUpperCase()}',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8,
                        color: _kVerde,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Leyenda inferior ───────────────────────────────────

  pw.Widget _buildLeyenda(List<_Pelea> peleas, pw.Font fontLight) {
    final hayDobles = peleas.any((p) => p.aEsDoble || p.bEsDoble);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          '* Pesos en gramos  ',
          style: pw.TextStyle(font: fontLight, fontSize: 7, color: _kGrisTexto),
        ),
        if (hayDobles) ...[
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFF8E1'),
              borderRadius: pw.BorderRadius.circular(2),
              border: pw.Border.all(
                color: PdfColor.fromHex('#F9A825'),
                width: 0.5,
              ),
            ),
            child: pw.Text(
              '×2',
              style: pw.TextStyle(
                font: fontLight,
                fontSize: 7,
                color: PdfColor.fromHex('#F9A825'),
              ),
            ),
          ),
          pw.Text(
            '  = Pelea doble (mismo partido usa 2 gallos)',
            style: pw.TextStyle(
              font: fontLight,
              fontSize: 7,
              color: _kGrisTexto,
            ),
          ),
        ],
      ],
    );
  }

  // ── Helpers de widgets ─────────────────────────────────

  pw.Widget _galloCell(
    String anillo,
    double peso,
    pw.Font fontBold,
    pw.Font fontLight, {
    required bool esA,
  }) {
    final bgColor = esA ? PdfColor.fromHex('#F5F5F5') : _kAzulLight;
    final fgAnillo = esA ? _kNegro : _kAzul;
    final fgPeso = esA ? _kGrisTexto : PdfColor.fromHex('#1976D2');

    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(
            color: esA ? _kGrisMedio : PdfColor.fromHex('#90CAF9'),
            width: 0.7,
          ),
        ),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              anillo,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
                color: fgAnillo,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              '${peso.toStringAsFixed(0)} g',
              style: pw.TextStyle(
                font: fontLight,
                fontSize: 7.5,
                color: fgPeso,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _filaBadge(int fila, pw.Font fontBold, {required String side}) {
    final bg = side == 'A' ? _kGris : _kAzulLight;
    final fg = side == 'A' ? _kGrisTexto : _kAzul;
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      child: pw.Container(
        width: 20,
        height: 20,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: bg,
          shape: pw.BoxShape.circle,
          border: pw.Border.all(
            color: side == 'A' ? _kGrisMedio : PdfColor.fromHex('#90CAF9'),
            width: 0.7,
          ),
        ),
        child: pw.Text(
          '$fila',
          style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: fg),
        ),
      ),
    );
  }

  pw.Widget _etiquetaDoble(pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF8E1'),
        borderRadius: pw.BorderRadius.circular(2),
        border: pw.Border.all(color: PdfColor.fromHex('#F9A825'), width: 0.5),
      ),
      child: pw.Text(
        '×2  PELEA DOBLE',
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 6,
          color: PdfColor.fromHex('#E65100'),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  pw.Widget _pill(
    String text,
    PdfColor bg,
    pw.Font fontBold,
    pw.Font fontLight,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 8,
          color: _kBlanco,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  pw.Widget _hCell(
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

  // ── Extracción de datos desde SorteoResultado ──────────

  /// Construye la lista de peleas desduplicadas para la ronda [rondaNum].
  /// Solo incluye la pelea una vez (cuando filaPropio < filaRival).
  List<_Pelea> _extraerPeleas(int rondaNum) {
    final map = <int, PartidoResultado>{
      for (final p in sorteo.partidos) p.partidoId: p,
    };

    final peleas = <_Pelea>[];
    int numeroPelea = 1;

    for (final partido in sorteo.partidos) {
      final rondasDeEstaRonda = partido.rondas
          .where((r) => r.numeroRonda == rondaNum && !r.esBye)
          .toList();

      for (final ronda in rondasDeEstaRonda) {
        // Deduplicar: solo incluir si fila propia < fila rival
        if (partido.fila >= ronda.filaPartidoRival) continue;

        // Obtener el PartidoResultado del rival para saber si también juega doble
        final rivalPartido = map[_buscarIdPorFila(ronda.filaPartidoRival)];
        final rivalEsDoble =
            rivalPartido != null &&
            rivalPartido.rondas
                .where((r) => r.numeroRonda == rondaNum)
                .any((r) => r.esDoble);

        peleas.add(
          _Pelea(
            numero: numeroPelea++,
            filaA: partido.fila,
            nombreA: partido.nombrePartido,
            anilloA: ronda.anilloPropio,
            pesoA: ronda.pesoPropio,
            filaB: ronda.filaPartidoRival,
            nombreB: ronda.nombrePartidoRival,
            anilloB: ronda.anilloRival,
            pesoB: ronda.pesoRival,
            diff: (ronda.pesoPropio - ronda.pesoRival).abs(),
            aEsDoble: ronda.esDoble,
            bEsDoble: rivalEsDoble,
          ),
        );
      }
    }

    return peleas;
  }

  List<_PartidoBye> _extraerByes(int rondaNum) {
    return sorteo.partidos
        .where((p) => p.rondas.any((r) => r.numeroRonda == rondaNum && r.esBye))
        .map((p) => _PartidoBye(p.fila, p.nombrePartido))
        .toList();
  }

  int _buscarIdPorFila(int fila) {
    try {
      return sorteo.partidos.firstWhere((p) => p.fila == fila).partidoId;
    } catch (_) {
      return -1;
    }
  }

  // ── Utils ──────────────────────────────────────────────

  static String _labelRonda(int num, int total) =>
      num == total ? 'Ronda Base' : 'Ronda $num';

  static String _formatFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
