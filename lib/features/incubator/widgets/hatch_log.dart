import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/chick.dart';
import '../../../data/models/incubator_status.dart';
import '../../../data/providers/chicks_provider.dart';
import '../../../shared/design_kit.dart';
import '../../../shared/error_widget.dart';
import '../../../shared/loading_widget.dart';

/// Log penetasan: icon + kode + tanggal + berat (DESIGN.md §3.6).
class HatchLog extends ConsumerWidget {
  final AsyncValue<List<Chick>> chicksAsync;

  const HatchLog({super.key, required this.chicksAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return chicksAsync.when(
      loading: () => const LoadingWidget(),
      error: (err, _) => AppErrorWidget(
        message: friendlyApiError(err),
        onRetry: () => ref.refresh(chicksListProvider),
      ),
      data: (chicks) {
        final recent = chicks.take(5).toList();
        if (recent.isEmpty) {
          return const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.egg_outlined,
                message: 'Belum ada data di kategori ini',
              ),
            ),
          );
        }
        return Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < recent.length; i++) ...[
                _HatchItem(chick: recent[i]),
                if (i < recent.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HatchItem extends StatelessWidget {
  final Chick chick;

  const _HatchItem({required this.chick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chick.id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatDate(chick.tanggalMenetas),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${chick.beratAwal.toStringAsFixed(0)}g',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const StatusChip(label: 'Prima', status: AppStatus.active),
            ],
          ),
        ],
      ),
    );
  }
}

/// Brooder checklist 1 card ber-divider (DESIGN.md §3.7).
class BrooderCard extends StatelessWidget {
  final IncubatorStatus? status;

  const BrooderCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Suhu Stabil', status != null ? 'AKTIF' : '-'),
      ('Kelembapan', status != null ? 'AKTIF' : '-'),
      ('Lampu Cadangan', status?.lampuStatus ?? '-'),
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
                    'Brooder',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                StatusChip(
                  label: status != null ? 'STANDBY' : '-',
                  status: status != null
                      ? AppStatus.pending
                      : AppStatus.neutral,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < items.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.statusActive,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i].$1,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      items[i].$2,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusActive,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}
