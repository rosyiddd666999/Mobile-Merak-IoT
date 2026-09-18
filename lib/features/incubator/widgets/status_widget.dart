import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../data/models/incubator_settings.dart';
import '../../../data/models/incubator_status.dart';
import '../../../data/providers/demo_provider.dart';
import '../../../data/providers/incubator_provider.dart';
import '../../../data/providers/mqtt_provider.dart';
import 'mqtt_status_badge.dart';

class StatusWidget extends ConsumerWidget {
  const StatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoProvider);
    final mqtt = ref.watch(mqttProvider);
    // MQTT realtime utama; fallback REST di bawah (MOBILE.md §6.3/§7.4.5).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mqttProvider.notifier).connectIfNeeded();
    });

    if (demo.active && demo.status != null) {
      return _StatusContent(
        status: demo.status!,
        isDemo: true,
        onDeactivate: () => ref.read(demoProvider.notifier).deactivate(),
      );
    }

    if (mqtt.hasTelemetry) {
      return _StatusContent(
        status: IncubatorStatus(
          id: 0,
          suhuSekarang: mqtt.temperature!,
          kelembapanSekarang: mqtt.humidity!,
          lampuStatus: mqtt.statusLamp ?? 'OFF',
        ),
        isDemo: false,
        isRealtime: true,
        onReconnect: () => ref.read(mqttProvider.notifier).reconnect(),
      );
    }

    final statusAsync = ref.watch(incubatorStatusProvider);
    return statusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _EmptyState(),
      data: (status) {
        if (status == null) return const _EmptyState();
        return _StatusContent(status: status, isDemo: false);
      },
    );
  }
}

class _StatusContent extends StatelessWidget {
  final IncubatorStatus status;
  final bool isDemo;
  final bool isRealtime;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReconnect;

  const _StatusContent({
    required this.status,
    required this.isDemo,
    this.isRealtime = false,
    this.onDeactivate,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final settings = _approxSettings(status);
    final suhuNormal = status.suhuSekarang >= settings.suhuMin &&
        status.suhuSekarang <= settings.suhuMax;
    final lembapNormal = status.kelembapanSekarang >= settings.kelembapanMin &&
        status.kelembapanSekarang <= settings.kelembapanMax;
    final statusColor =
        (suhuNormal && lembapNormal) ? AppColors.success : AppColors.critical;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const MqttStatusBadge(),
          const SizedBox(height: 12),
          if (isDemo) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.science, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  const Text(
                    'Mode Demo Aktif',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (isRealtime) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 14, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'Realtime MQTT',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _statusBanner(statusColor, suhuNormal && lembapNormal),
          const SizedBox(height: 24),
          _bigDisplay(
            '${status.suhuSekarang.toStringAsFixed(1)}°C',
            'Suhu',
            suhuNormal ? AppColors.success : AppColors.critical,
            Icons.thermostat,
          ),
          const SizedBox(height: 16),
          _bigDisplay(
            '${status.kelembapanSekarang.toStringAsFixed(0)}%',
            'Kelembapan',
            lembapNormal ? AppColors.success : AppColors.critical,
            Icons.water_drop,
          ),
          const SizedBox(height: 24),
          Center(
            child: _chip(
              Icons.lightbulb,
              'Lampu ${status.lampuStatus}',
              status.lampuStatus == 'ON'
                  ? AppColors.secondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IncubatorSettings _approxSettings(IncubatorStatus s) {
    return IncubatorSettings(
      id: 1,
      suhuMin: 37.0,
      suhuMax: 38.0,
      kelembapanMin: 55.0,
      kelembapanMax: 65.0,
      intervalRotasiMenit: 240,
    );
  }

  Widget _statusBanner(Color color, bool normal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(normal ? Icons.check_circle : Icons.warning, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              normal ? 'Kondisi inkubator normal' : 'Ada kondisi yang perlu diperhatikan',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigDisplay(String value, String label, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(incubatorSettingsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.thermostat, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data inkubator',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan perangkat inkubator terhubung dan sedang mengirim data sensornya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                final settings = settingsAsync.valueOrNull ??
                    IncubatorSettings(
                      id: 1,
                      suhuMin: 37,
                      suhuMax: 38,
                      kelembapanMin: 55,
                      kelembapanMax: 65,
                      intervalRotasiMenit: 240,
                    );
                ref.read(demoProvider.notifier).activate(settings);
              },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Aktifkan Mode Demo'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
              child: const Text('Nanti saja'),
            ),
          ],
        ),
      ),
    );
  }
}
