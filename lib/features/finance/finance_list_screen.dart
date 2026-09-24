import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../core/app_routes.dart';
import '../../core/theme.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/models/finance_entry.dart';
import '../../data/providers/finance_provider.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/async_state_view.dart';
import '../../shared/design_kit.dart';
import '../../shared/root_app_bar.dart';
import 'finance_report_filter.dart';
import 'finance_report_pdf.dart';
import 'widgets/finance_entry_card.dart';

/// Keuangan (DESIGN.md §4): hero valuasi, banner BKSDA, komersial horizontal,
/// riwayat transaksi, ekspor 1 card.
class FinanceListScreen extends ConsumerWidget {
  const FinanceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeAsync = ref.watch(financeListProvider);
    final breedersAsync = ref.watch(breedersListProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = user?.role == 'pemilik';

    return Scaffold(
      appBar: const RootAppBar(title: 'Keuangan'),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              heroTag: null,
              onPressed: () => context.push(AppRoutes.financeNew),
              backgroundColor: AppColors.darkCard,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(financeListProvider.future),
        child: AsyncStateView(
          async: financeAsync,
          actionLabel: 'memuat data keuangan',
          loadingMessage: 'Memuat data keuangan...',
          emptyIcon: Icons.receipt_long_outlined,
          emptyMessage: 'Belum ada data keuangan',
          onRetry: () => ref.refresh(financeListProvider),
          isEmpty: (entries) => entries.isEmpty,
          dataBuilder: (entries) {
            final masuk = entries
                .where((e) => e.tipe.toLowerCase() == 'pemasukan')
                .fold<double>(0, (s, e) => s + e.jumlah);
            final keluar = entries
                .where((e) => e.tipe.toLowerCase() != 'pemasukan')
                .fold<double>(0, (s, e) => s + e.jumlah);
            final ready = breedersAsync.maybeWhen(
              data: (list) =>
                  list.where((b) => b.status == 'ready_for_sale').toList(),
              orElse: () => [],
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                _ValuationHero(masuk: masuk, keluar: keluar),
                const SizedBox(height: 12),
                const CollapsibleBanner(
                  collapsedLabel: 'Regulasi BKSDA →',
                  title: 'Regulasi BKSDA',
                  body:
                      'Perdagangan merak diatur perizinan BKSDA. '
                      'Pastikan setiap penjualan indukan/anakan dilampiri dokumen resmi sebelum serah terima.',
                  icon: Icons.verified_outlined,
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Kesiapan Komersial'),
                const SizedBox(height: 12),
                if (ready.isEmpty)
                  const Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: EmptyState(
                        icon: Icons.storefront_outlined,
                        message: 'Belum ada data di kategori ini',
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 155,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: ready.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final b = ready[i];
                        return _ProductCard(
                          title: (b.nama?.isNotEmpty == true) ? b.nama! : b.id,
                          subtitle: '${b.generasi} · ${b.varianWarna}',
                          onTap: () => context.push(AppRoutes.breederDetail(b.id)),
                          onSph: () => context.push(
                            Uri(
                              path: AppRoutes.saleNew,
                              queryParameters: {
                                'item': 'Indukan ${b.nama ?? b.id}',
                                'ref': b.id,
                              },
                            ).toString(),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Riwayat Transaksi'),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'Belum ada data di kategori ini',
                      ),
                    ),
                  )
                else
                  ...entries.map(
                    (FinanceEntry e) => FinanceEntryCard(
                      entry: e,
                      onTap: () => context.push(AppRoutes.financeDetail(e.id)),
                    ),
                  ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Ekspor Laporan'),
                const SizedBox(height: 12),
                _ExportCard(entries: entries),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ValuationHero extends StatelessWidget {
  final double masuk;
  final double keluar;

  const _ValuationHero({required this.masuk, required this.keluar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Valuasi',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(masuk - keluar),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Sub(label: 'Pendapatan', value: formatCompact(masuk)),
              _Sub(label: 'Biaya', value: formatCompact(keluar)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sub extends StatelessWidget {
  final String label;
  final String value;

  const _Sub({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onSph;

  const _ProductCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onSph,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: const Color(0xFFE6ECEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(label: 'Siap Jual', status: AppStatus.ready),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSph,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Buat SPH', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Detail', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 1 card 4 baris list (DESIGN.md §4.5) — salin CSV ke clipboard
/// + ekspor PDF langsung (preview/share/print via paket printing).
class _ExportCard extends StatefulWidget {
  final List<FinanceEntry> entries;

  const _ExportCard({required this.entries});

  @override
  State<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends State<_ExportCard> {
  /// Jenis laporan yang sedang dibuat PDF-nya (null = idle).
  String? _exportingKind;

  List<FinanceEntry> get entries => widget.entries;

  Future<void> _exportPdf(String kind) async {
    if (_exportingKind != null) return;
    setState(() => _exportingKind = kind);
    try {
      final bytes = await buildFinanceReportPdf(kind: kind, entries: entries);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'laporan-${kind.toLowerCase().replaceAll(' ', '-')}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
    } finally {
      if (mounted) setState(() => _exportingKind = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const reports = ['Ringkasan', 'Arus Kas', 'Penjualan', 'Operasional'];
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < reports.length; i++) ...[
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.primaryTeal,
                  size: 20,
                ),
              ),
              title: Text(
                'Laporan ${reports[i]}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: Text(
                _reportSubtitle(reports[i]),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      size: 20,
                      color: AppColors.primaryTeal,
                    ),
                    tooltip: 'Salin CSV',
                    onPressed: () {
                      final csv = _buildCsv(reports[i]);
                      Clipboard.setData(ClipboardData(text: csv));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Laporan ${reports[i]} disalin (CSV)'),
                        ),
                      );
                    },
                  ),
                  if (_exportingKind == reports[i])
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 20,
                        color: AppColors.primaryTeal,
                      ),
                      tooltip: 'Ekspor PDF',
                      onPressed: () => _exportPdf(reports[i]),
                    ),
                ],
              ),
            ),
            if (i < reports.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  String _reportSubtitle(String kind) {
    final count = filterReportEntries(kind, entries).length;
    switch (kind.toLowerCase()) {
      case 'arus kas':
        return '$count entri · rekap per bulan';
      case 'penjualan':
        return '$count entri · khusus penjualan';
      case 'operasional':
        return '$count entri · khusus biaya';
      default:
        return '$count entri · semua transaksi';
    }
  }

  String _buildCsv(String kind) {
    if (kind.toLowerCase() == 'arus kas') {
      final monthly = groupMonthly(filterReportEntries(kind, entries));
      final buf = StringBuffer('laporan,bulan,masuk,keluar,bersih\n');
      for (final entry in monthly.entries) {
        buf.writeln(
          '$kind,${entry.key},${entry.value.masuk},${entry.value.keluar},${entry.value.bersih}',
        );
      }
      return buf.toString();
    }
    final filtered = filterReportEntries(kind, entries);
    final buf = StringBuffer(
      'laporan,id,tanggal,tipe,kategori,jumlah,catatan\n',
    );
    for (final e in filtered) {
      buf.writeln(
        '$kind,${e.id},${e.tanggal},${e.tipe},${e.kategori},${e.jumlah},${(e.catatan ?? '-').replaceAll(',', ' ')}',
      );
    }
    return buf.toString();
  }
}
