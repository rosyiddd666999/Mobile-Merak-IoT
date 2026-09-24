import 'dart:typed_data';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/finance_entry.dart';
import 'finance_report_filter.dart';

/// Membangun dokumen PDF laporan keuangan (1 jenis [kind]).
/// - Ringkasan: semua entri + 3 box total.
/// - Arus Kas: rekap bulanan (Bulan|Masuk|Keluar|Bersih) + rincian urut tanggal.
/// - Penjualan: hanya pemasukan Penjualan* + breakdown per kategori.
/// - Operasional: hanya pengeluaran + breakdown per kategori.
Future<Uint8List> buildFinanceReportPdf({
  required String kind,
  required List<FinanceEntry> entries,
}) async {
  // Data simbol tanggal id_ID wajib di-init sebelum DateFormat ber-locale,
  // kalau tidak Arus Kas (satu-satunya yang format nama bulan) lempar
  // LocaleDataException. Di-cache intl setelah panggilan pertama.
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {
    // Abaikan: prettyMonth punya fallback manual di bawah.
  }
  final rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  final printedAt = DateFormat(
    'd MMM yyyy, HH:mm',
  ).format(DateTime.now());
  final monthLabel = DateFormat('MMM yyyy', 'id_ID');

  final normalized = kind.toLowerCase();
  final isCashflow = normalized == 'arus kas';
  final filtered = filterReportEntries(kind, entries);

  // Arus kas: rincian diurut tanggal naik agar saldo mengalir kronologis.
  final ordered = List<FinanceEntry>.of(filtered)
    ..sort((a, b) {
      final da = DateTime.tryParse(a.tanggal);
      final db = DateTime.tryParse(b.tanggal);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

  final masuk = filtered
      .where((e) => e.tipe.toLowerCase() == 'pemasukan')
      .fold<double>(0, (s, e) => s + e.jumlah);
  final keluar = filtered
      .where((e) => e.tipe.toLowerCase() != 'pemasukan')
      .fold<double>(0, (s, e) => s + e.jumlah);

  final monthly = isCashflow ? groupMonthly(filtered) : const <String, MonthlyCashflow>{};
  final showBreakdown =
      normalized == 'penjualan' || normalized == 'operasional';
  final breakdown =
      showBreakdown ? breakdownByKategori(filtered) : const <String, double>{};

  String prettyMonth(String key) {
    if (key == 'Tanpa tanggal') return key;
    final dt = DateTime.tryParse('$key-01');
    if (dt == null) return key;
    try {
      return monthLabel.format(dt);
    } catch (_) {
      // Fallback tanpa intl: Jan Feb ... Des + tahun.
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      final m = dt.month >= 1 && dt.month <= 12
          ? months[dt.month - 1]
          : '${dt.month}';
      return '$m ${dt.year}';
    }
  }

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

  pw.Widget sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget emptyBox(String text) => pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      );

  pw.Widget transactionTable(List<FinanceEntry> rows) {
    if (rows.isEmpty) return emptyBox('Belum ada data transaksi.');
    return pw.TableHelper.fromTextArray(
      headers: const ['Tanggal', 'Tipe', 'Kategori', 'Jumlah', 'Catatan'],
      data: [
        for (final e in rows)
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
            'Dicetak: $printedAt · ${filtered.length} entri',
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
        if (isCashflow) ...[
          sectionTitle('Rekap Bulanan'),
          if (monthly.isEmpty)
            emptyBox('Belum ada data transaksi.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Bulan', 'Masuk', 'Keluar', 'Bersih'],
              data: [
                for (final entry in monthly.entries)
                  [
                    prettyMonth(entry.key),
                    rupiah.format(entry.value.masuk),
                    rupiah.format(entry.value.keluar),
                    rupiah.format(entry.value.bersih),
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
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              border:
                  pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerHeight: 24,
              cellHeight: 20,
            ),
        ],
        if (showBreakdown) ...[
          sectionTitle('Rincian per Kategori'),
          if (breakdown.isEmpty)
            emptyBox('Belum ada data transaksi.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Kategori', 'Total'],
              data: [
                for (final entry in breakdown.entries)
                  [entry.key, rupiah.format(entry.value)],
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
                1: pw.Alignment.centerRight,
              },
              border:
                  pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerHeight: 24,
              cellHeight: 20,
            ),
        ],
        sectionTitle(
          isCashflow ? 'Rincian Transaksi (urut tanggal)' : 'Rincian Transaksi',
        ),
        transactionTable(ordered),
      ],
    ),
  );

  return doc.save();
}

String _shortNote(String? note) {
  final n = (note == null || note.trim().isEmpty) ? '-' : note.replaceAll('\n', ' ').trim();
  return n.length > 60 ? '${n.substring(0, 60)}…' : n;
}
