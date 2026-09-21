import 'package:flutter/material.dart';
import '../../../core/status_mapper.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/chick.dart';
import '../../../shared/app_card.dart';
import '../../../shared/design_kit.dart';

class ChickCard extends StatelessWidget {
  final Chick chick;
  final VoidCallback? onTap;

  const ChickCard({super.key, required this.chick, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = StatusMapper.chick(chick.status);
    return AppRowCard(
      onTap: onTap,
      leading: const AppLeadingBox(
        size: 48,
        color: AppColors.tertiary,
        child: Icon(Icons.cruelty_free, color: AppColors.tertiary, size: 24),
      ),
      title: chick.id,
      subtitle:
          '${formatDate(chick.tanggalMenetas)} · ${chick.beratAwal.toStringAsFixed(0)} g',
      meta: Row(
        children: [
          StatusChip(label: status.$1, status: status.$2),
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
    );
  }
}
