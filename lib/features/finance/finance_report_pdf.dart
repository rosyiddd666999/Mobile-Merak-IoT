import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/finance_entry.dart';

/// Membangun dokumen PDF laporan keuangan (1 jenis [kind]).
/// Isi: kop + tanggal cetak, ringkasan masuk/keluar/saldo, tabel semua entri.
Future<Uint8List> buildFinanceReportPdf({
  required String kind,
  required List<FinanceEntry> entries,
}) async {
  final rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final printedAt = DateFormat(
    'd MMM yyyy, HH:mm',
  ).format(DateTime.now());

  final masuk = entries
      .where((e) => e.tipe.toLowerCase() == 'pemasukan')
      .fold<double>(0, (s, e) => s + e.jumlah);
  final keluar = entries
      .where((e) => e.tipe.toLowerCase() != 'pemasukan')
      .fold<double>(0, (s, e) => s + e.jumlah);

  const ink = PdfColors.teal800;
  final doc = pw.Document();

  pw.Widget summaryBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Laporan $kind',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: ink),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Media Edukasi Kampung Merak Gentan Hijau Berseri',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            'Dicetak: $printedAt · ${entries.length} entri',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: ink, thickness: 1.5),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300, thickness: 0.5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Kerjasama PT Pertamina Patra Niaga FT Madiun',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Hal. ${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        pw.Row(
          children: [
            summaryBox('Total Pemasukan', rupiah.format(masuk)),
            pw.SizedBox(width: 8),
            summaryBox('Total Pengeluaran', rupiah.format(keluar)),
            pw.SizedBox(width: 8),
            summaryBox('Saldo', rupiah.format(masuk - keluar)),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Rincian Transaksi',
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (entries.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Belum ada data transaksi.',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          )
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Tanggal', 'Tipe', 'Kategori', 'Jumlah', 'Catatan'],
            data: [
              for (final e in entries)
                [
                  e.tanggal,
                  e.tipe,
                  e.kategori,
                  rupiah.format(e.jumlah),
                  _shortNote(e.catatan),
                ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: ink),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerLeft,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(1.4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(2),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerHeight: 24,
            cellHeight: 20,
          ),
      ],
    ),
  );

  return doc.save();
}

String _shortNote(String? note) {
  final n = (note == null || note.trim().isEmpty) ? '-' : note.replaceAll('\n', ' ').trim();
  return n.length > 60 ? '${n.substring(0, 60)}…' : n;
}
