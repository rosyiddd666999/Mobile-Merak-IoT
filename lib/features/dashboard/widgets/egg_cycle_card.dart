import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/dashboard_summary.dart';

/// Egg Cycle Card dengan progress ring (DESIGN.md §3.3).
class EggCycleCard extends StatelessWidget {
  final DashboardSummary summary;

  const EggCycleCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.totalTelurAktif + summary.totalAnakanBulanIni;
    final progress = total == 0 ? 0.0 : summary.totalAnakanBulanIni / total;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    backgroundColor: AppColors.primaryTeal.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryTeal,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Siklus Bulan Ini',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalAnakanBulanIni} menetas dari $total telur',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoIncubatorCard extends StatelessWidget {
  final VoidCallback onDemo;

  const NoIncubatorCard({super.key, required this.onDemo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.thermostat, size: 32, color: AppColors.textMuted),
            const SizedBox(height: 8),
            const Text(
              'Belum ada data inkubator',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Suhu: - · Kelembapan: - · Lampu: -',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onDemo,
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('Mode Demo'),
            ),
          ],
        ),
      ),
    );
  }
}
