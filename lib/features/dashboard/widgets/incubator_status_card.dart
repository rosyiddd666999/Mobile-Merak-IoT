import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/incubator_status.dart';
import '../../../shared/design_kit.dart';

class IncubatorStatusCard extends StatelessWidget {
  final IncubatorStatus status;

  const IncubatorStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final suhuNormal = status.suhuSekarang >= 37.0 && status.suhuSekarang <= 38.0;
    final lembapNormal = status.kelembapanSekarang >= 55.0 && status.kelembapanSekarang <= 65.0;
    final normal = suhuNormal && lembapNormal;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Inkubator',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                StatusChip(
                  label: normal ? 'Normal' : 'Perhatian',
                  status: normal ? AppStatus.active : AppStatus.alert,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Item(
                  icon: Icons.thermostat,
                  value: '${status.suhuSekarang.toStringAsFixed(1)}°C',
                  label: 'Suhu',
                  ok: suhuNormal,
                ),
                _Item(
                  icon: Icons.water_drop,
                  value: '${status.kelembapanSekarang.toStringAsFixed(0)}%',
                  label: 'Lembap',
                  ok: lembapNormal,
                ),
                _Item(
                  icon: status.lampuStatus == 'ON' ? Icons.lightbulb : Icons.lightbulb_outline,
                  value: status.lampuStatus,
                  label: 'Lampu',
                  ok: status.lampuStatus == 'ON',
                  neutralOff: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool ok;
  final bool neutralOff;

  const _Item({
    required this.icon,
    required this.value,
    required this.label,
    required this.ok,
    this.neutralOff = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok
        ? AppColors.statusActive
        : (neutralOff ? AppColors.textMuted : AppColors.statusAlert);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
