import '../../data/models/finance_entry.dart';

/// Sumber kebenaran filter 4 jenis laporan — dipakai PDF + CSV + subtitle.
/// - Ringkasan: semua entri.
/// - Arus Kas: semua entri (outputnya rekap bulanan, lihat [groupMonthly]).
/// - Penjualan: hanya pemasukan dengan kategori Penjualan*.
/// - Operasional: hanya pengeluaran.
List<FinanceEntry> filterReportEntries(
  String kind,
  List<FinanceEntry> entries,
) {
  switch (kind.toLowerCase()) {
    case 'penjualan':
      return entries
          .where(
            (e) =>
                e.tipe.toLowerCase() == 'pemasukan' &&
                e.kategori.toLowerCase().startsWith('penjualan'),
          )
          .toList();
    case 'operasional':
      return entries
          .where((e) => e.tipe.toLowerCase() != 'pemasukan')
          .toList();
    case 'arus kas':
    case 'ringkasan':
    default:
      return List<FinanceEntry>.of(entries);
  }
}

bool _isIncome(FinanceEntry e) => e.tipe.toLowerCase() == 'pemasukan';

/// Kunci bulan `yyyy-MM` dari [FinanceEntry.tanggal], null bila tak terparse.
String? parseReportMonth(FinanceEntry e) {
  final dt = DateTime.tryParse(e.tanggal);
  if (dt == null) return null;
  final m = dt.month.toString().padLeft(2, '0');
  return '${dt.year}-$m';
}

class MonthlyCashflow {
  final String monthKey;
  double masuk = 0;
  double keluar = 0;

  MonthlyCashflow(this.monthKey);

  double get bersih => masuk - keluar;
}

/// Grouping bulanan urut naik. Entri tanpa tanggal valid digabung ke
/// grup terakhir berlabel sesuai [invalidLabel] agar tidak hilang.
Map<String, MonthlyCashflow> groupMonthly(
  List<FinanceEntry> entries, {
  String invalidLabel = 'Tanpa tanggal',
}) {
  final map = <String, MonthlyCashflow>{};
  MonthlyCashflow bucket(String key) =>
      map.putIfAbsent(key, () => MonthlyCashflow(key));

  for (final e in entries) {
    final key = parseReportMonth(e);
    if (key == null) {
      final b = bucket(invalidLabel);
      if (_isIncome(e)) {
        b.masuk += e.jumlah;
      } else {
        b.keluar += e.jumlah;
      }
      continue;
    }
    final b = bucket(key);
    if (_isIncome(e)) {
      b.masuk += e.jumlah;
    } else {
      b.keluar += e.jumlah;
    }
  }

  // Urut: yyyy-MM naik, label invalid selalu paling akhir.
  final keys = map.keys.toList()
    ..sort((a, b) {
      if (a == invalidLabel) return 1;
      if (b == invalidLabel) return -1;
      return a.compareTo(b);
    });
  return {for (final k in keys) k: map[k]!};
}

/// Breakdown total per kategori (urut nominal desc).
Map<String, double> breakdownByKategori(List<FinanceEntry> entries) {
  final map = <String, double>{};
  for (final e in entries) {
    final key = e.kategori.trim().isEmpty ? '-' : e.kategori.trim();
    map[key] = (map[key] ?? 0) + e.jumlah;
  }
  final keys = map.keys.toList()
    ..sort((a, b) => map[b]!.compareTo(map[a]!));
  return {for (final k in keys) k: map[k]!};
}
