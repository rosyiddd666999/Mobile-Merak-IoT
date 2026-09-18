import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/chick.dart';

class ChickCard extends StatelessWidget {
  final Chick chick;
  final VoidCallback? onTap;

  const ChickCard({super.key, required this.chick, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.tertiary.withValues(alpha: 0.12),
                child: const Icon(Icons.cruelty_free, color: AppColors.tertiary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chick.id,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(chick.tanggalMenetas),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.monitor_weight_outlined, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${chick.beratAwal.toStringAsFixed(0)} g',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _statusChip(_statusColor(chick.status), _statusLabel(chick.status)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            chick.skorKesehatan,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'newborn':
        return AppColors.info;
      case 'growing':
        return AppColors.success;
      case 'ready_for_sale':
        return AppColors.secondary;
      case 'sold':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'newborn':
        return 'Baru';
      case 'growing':
        return 'Tumbuh';
      case 'ready_for_sale':
        return 'Jual';
      case 'sold':
        return 'Terjual';
      default:
        return status;
    }
  }
}
