import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/threshold_classifier.dart';
import '../../../data/models/incubator_settings.dart';
import '../../../data/models/incubator_status.dart';
import '../../../shared/design_kit.dart';

/// Kartu status inkubator di dashboard: ambang ikut DB ([settings]),
/// chip 3-state (Ideal/Waspada/Perhatian) cermin backend.
class IncubatorStatusCard extends StatelessWidget {
  final IncubatorStatus status;
  final IncubatorSettings settings;

  const IncubatorStatusCard({
    super.key,
    required this.status,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final suhuState = classifyTemp(
      status.suhuSekarang,
      settings.suhuMin,
      settings.suhuMax,
    );
    final lembapState = classifyHum(
      status.kelembapanSekarang,
      settings.kelembapanMin,
      settings.kelembapanMax,
    );
    final overall = classifyOverall(
      suhu: status.suhuSekarang,
      lembap: status.kelembapanSekarang,
      settings: settings,
    );

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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                StatusChip(label: overall.label, status: overall.appStatus),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Item(
                  icon: Icons.thermostat,
                  value: '${status.suhuSekarang.toStringAsFixed(1)}°C',
                  label: 'Suhu',
                  state: suhuState,
                ),
                _Item(
                  icon: Icons.water_drop,
                  value: '${status.kelembapanSekarang.toStringAsFixed(0)}%',
                  label: 'Lembap',
                  state: lembapState,
                ),
                _Item(
                  icon: status.lampuStatus == 'ON'
                      ? Icons.lightbulb
                      : Icons.lightbulb_outline,
                  value: status.lampuStatus,
                  label: 'Lampu',
                  state: ThresholdState.ideal,
                  neutralOff: status.lampuStatus != 'ON',
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
  final ThresholdState state;
  final bool neutralOff;

  const _Item({
    required this.icon,
    required this.value,
    required this.label,
    required this.state,
    this.neutralOff = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = state == ThresholdState.ideal
        ? (neutralOff ? AppColors.textMuted : AppColors.statusActive)
        : state.color;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
