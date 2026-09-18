import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/egg.dart';
import '../../../shared/design_kit.dart';

class EggCard extends StatelessWidget {
  final Egg egg;
  final VoidCallback? onTap;

  const EggCard({super.key, required this.egg, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Slot',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textMuted,
                        height: 1,
                      ),
                    ),
                    Text(
                      '${egg.slot}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryTeal,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      egg.id,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDate(egg.tanggalMasuk),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusChip(
                          label: _fertilLabel(egg.fertilitas),
                          status: _fertilStatus(egg.fertilitas),
                        ),
                        StatusChip(
                          label: _akhirLabel(egg.akhir),
                          status: _akhirStatus(egg.akhir),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  AppStatus _fertilStatus(String fertilitas) {
    switch (fertilitas.toLowerCase()) {
      case 'fertil':
        return AppStatus.active;
      case 'infertil':
        return AppStatus.alert;
      case 'belum dicek':
        return AppStatus.pending;
      default:
        return fertilitas.isEmpty ? AppStatus.neutral : AppStatus.pending;
    }
  }

  String _fertilLabel(String fertilitas) {
    switch (fertilitas.toLowerCase()) {
      case 'fertil':
        return 'Fertil';
      case 'infertil':
        return 'Infertil';
      case 'belum dicek':
        return 'Belum dicek';
      default:
        return fertilitas.isEmpty ? '-' : fertilitas;
    }
  }

  AppStatus _akhirStatus(String akhir) {
    switch (akhir.toLowerCase()) {
      case 'menetas':
        return AppStatus.ready;
      case 'gagal':
        return AppStatus.alert;
      case 'proses':
        return AppStatus.pending;
      default:
        return akhir.isEmpty ? AppStatus.neutral : AppStatus.pending;
    }
  }

  String _akhirLabel(String akhir) {
    switch (akhir.toLowerCase()) {
      case 'menetas':
        return 'Menetas';
      case 'gagal':
        return 'Gagal';
      case 'proses':
        return 'Proses';
      default:
        return akhir.isEmpty ? '-' : akhir;
    }
  }
}
