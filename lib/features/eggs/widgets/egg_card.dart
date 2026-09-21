import 'package:flutter/material.dart';
import '../../../core/status_mapper.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/egg.dart';
import '../../../shared/app_card.dart';
import '../../../shared/design_kit.dart';

class EggCard extends StatelessWidget {
  final Egg egg;
  final VoidCallback? onTap;

  const EggCard({super.key, required this.egg, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fertil = StatusMapper.eggFertility(egg.fertilitas);
    final akhir = StatusMapper.eggOutcome(egg.akhir);
    return AppRowCard(
      onTap: onTap,
      leading: AppLeadingBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Slot',
              style: TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1),
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
      title: egg.id,
      subtitle: formatDate(egg.tanggalMasuk),
      meta: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          StatusChip(label: fertil.$1, status: fertil.$2),
          StatusChip(label: akhir.$1, status: akhir.$2),
        ],
      ),
    );
  }
}
