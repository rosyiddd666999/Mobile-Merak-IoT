import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/breeder.dart';
import '../../../data/models/chick.dart';
import '../../../data/models/dashboard_summary.dart';
import '../../../shared/design_kit.dart';
import '../../../shared/loading_widget.dart';

/// Ringkasan 3 indukan teratas. Tap item = detail, tap "tab" via header induk.
class BreederPreview extends StatelessWidget {
  final AsyncValue<List<Breeder>> breedersAsync;
  final VoidCallback onOpenTab;
  final ValueChanged<String> onOpenDetail;

  const BreederPreview({
    super.key,
    required this.breedersAsync,
    required this.onOpenTab,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return breedersAsync.when(
      loading: () => const LoadingWidget(),
      error: (_, _) => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: EmptyState(
            icon: Icons.pets,
            message: 'Data indukan tidak tersedia',
          ),
        ),
      ),
      data: (breeders) {
        if (breeders.isEmpty) {
          return const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.pets,
                message: 'Belum ada data indukan',
              ),
            ),
          );
        }
        final top = breeders.take(3).toList();
        return Card(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < top.length; i++) ...[
                ListTile(
                  dense: true,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 20,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  title: Text(
                    top[i].nama?.isNotEmpty == true ? top[i].nama! : top[i].id,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${top[i].generasi} · ${top[i].jenisKelamin}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: StatusChip(
                    label: top[i].status,
                    status: top[i].status == 'ready_for_sale'
                        ? AppStatus.ready
                        : top[i].status == 'breeding'
                        ? AppStatus.active
                        : AppStatus.pending,
                  ),
                  onTap: () => onOpenDetail(top[i].id),
                ),
                if (i < top.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
              ListTile(
                dense: true,
                title: Text(
                  breeders.length > 3
                      ? 'Lihat ${breeders.length - 3} indukan lainnya'
                      : 'Buka tab Indukan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryTeal,
                ),
                onTap: onOpenTab,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Ringkasan 3 anakan terbaru. Tap item = detail.
class ChickPreview extends StatelessWidget {
  final AsyncValue<List<Chick>> chicksAsync;
  final ValueChanged<String> onOpenDetail;

  const ChickPreview({
    super.key,
    required this.onOpenDetail,
    required this.chicksAsync,
  });

  @override
  Widget build(BuildContext context) {
    return chicksAsync.when(
      loading: () => const LoadingWidget(),
      error: (_, _) => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: EmptyState(
            icon: Icons.flutter_dash,
            message: 'Data anakan tidak tersedia',
          ),
        ),
      ),
      data: (chicks) {
        if (chicks.isEmpty) {
          return const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.flutter_dash,
                message: 'Belum ada anakan menetas',
              ),
            ),
          );
        }
        final top = chicks.take(3).toList();
        return Card(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < top.length; i++) ...[
                ListTile(
                  dense: true,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.egg_outlined,
                      size: 20,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  title: Text(
                    top[i].id,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${top[i].beratAwal.toStringAsFixed(0)}g',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                  onTap: () => onOpenDetail(top[i].id),
                ),
                if (i < top.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class FinanceMiniCard extends StatelessWidget {
  final DashboardSummary summary;

  const FinanceMiniCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final f = summary.financeSummary!;
    final total = f.totalPemasukan + f.totalPengeluaran;
    final sections = total <= 0
        ? [
            PieChartSectionData(
              value: 1,
              color: AppColors.divider,
              radius: 14,
              showTitle: false,
            ),
          ]
        : [
            PieChartSectionData(
              value: f.totalPemasukan,
              color: AppColors.statusActive,
              radius: 14,
              showTitle: false,
            ),
            PieChartSectionData(
              value: f.totalPengeluaran,
              color: AppColors.statusAlert,
              radius: 14,
              showTitle: false,
            ),
          ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Keuangan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                StatusChip(
                  label: total <= 0 ? 'Kosong' : 'Live',
                  status: total <= 0 ? AppStatus.neutral : AppStatus.active,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatRupiah(f.saldo),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Saldo kas',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 26,
                      startDegreeOffset: -90,
                      sections: sections,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      FlowRow(
                        icon: Icons.south_west,
                        color: AppColors.statusActive,
                        label: 'Pemasukan',
                        value: formatRupiah(f.totalPemasukan),
                      ),
                      const SizedBox(height: 10),
                      FlowRow(
                        icon: Icons.north_east,
                        color: AppColors.statusAlert,
                        label: 'Pengeluaran',
                        value: formatRupiah(f.totalPengeluaran),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris legenda arus kas: ikon arah + label + nominal.
class FlowRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const FlowRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
