import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/egg.dart';
import '../../../data/models/incubator_status.dart';
import '../../../shared/design_kit.dart';

/// Header stat row — 3 kolom card tipis (DESIGN.md §3.1).
class HeaderStats extends StatelessWidget {
  final IncubatorStatus? status;

  const HeaderStats({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Mini(
          icon: Icons.thermostat,
          value: status != null
              ? '${status!.suhuSekarang.toStringAsFixed(1)}°'
              : '-',
          label: 'Suhu',
        ),
        const SizedBox(width: 8),
        _Mini(
          icon: Icons.water_drop,
          value: status != null
              ? '${status!.kelembapanSekarang.toStringAsFixed(0)}%'
              : '-',
          label: 'Lembap',
        ),
        const SizedBox(width: 8),
        _Mini(
          icon: Icons.lightbulb,
          value: status != null ? status!.lampuStatus : '-',
          label: 'Lampu',
        ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Mini({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: const Color(0xFFE6ECEA)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryTeal),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bio-Dome hero: 1 card menyatu, overlay stat semi-transparan (DESIGN.md §3.2).
class BioDomeHero extends StatelessWidget {
  final IncubatorStatus? status;
  final bool isLive;
  final DateTime? lastRotation;
  final String? lastRotationRaw;

  const BioDomeHero({
    super.key,
    required this.status,
    required this.isLive,
    this.lastRotation,
    this.lastRotationRaw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bio-Dome Inkubator',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                StatusChip(
                  label: isLive
                      ? 'Live'
                      : (status != null ? 'Data Terakhir' : 'Offline'),
                  status: isLive
                      ? AppStatus.active
                      : (status != null
                            ? AppStatus.pending
                            : AppStatus.neutral),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _OverlayStat(
                  'Suhu',
                  status != null
                      ? '${status!.suhuSekarang.toStringAsFixed(1)}°C'
                      : '-',
                ),
                _OverlayStat(
                  'Lembap',
                  status != null
                      ? '${status!.kelembapanSekarang.toStringAsFixed(0)}%'
                      : '-',
                ),
                _OverlayStat('Lampu', status?.lampuStatus ?? '-'),
                _OverlayStat(
                  'Rotasi',
                  rotationLabel(lastRotation, lastRotationRaw),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayStat extends StatelessWidget {
  final String label;
  final String value;

  const _OverlayStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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

/// Fase embrio + candling dalam 1 card (DESIGN.md §3.3-3.4).
class EmbryoCard extends StatelessWidget {
  final AsyncValue<List<Egg>> eggsAsync;

  const EmbryoCard({super.key, required this.eggsAsync});

  @override
  Widget build(BuildContext context) {
    final activeCount = eggsAsync.maybeWhen(
      data: (eggs) =>
          eggs.where((e) => e.akhir.toLowerCase() == 'proses').length,
      orElse: () => null,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 0.64,
                    strokeWidth: 8,
                    backgroundColor: AppColors.primaryTeal.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryTeal,
                    ),
                  ),
                  const Center(
                    child: Text(
                      '18/28',
                      style: TextStyle(
                        fontSize: 14,
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
                    'Fase Pertumbuhan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeCount != null
                        ? '$activeCount telur dalam proses'
                        : '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.statusActive,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Candling: -',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
