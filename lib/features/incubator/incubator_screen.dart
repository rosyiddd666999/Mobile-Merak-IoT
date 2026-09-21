import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/incubator_status.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/demo_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../data/providers/incubator_provider.dart';
import '../../data/providers/mqtt_provider.dart';
import '../../shared/design_kit.dart';
import '../../shared/root_app_bar.dart';
import '../../shared/demo_banner.dart';
import '../../shared/cctv_live_card.dart';
import 'widgets/incubator_hero.dart';
import 'widgets/incubator_controls.dart';
import 'widgets/incubator_chart_card.dart';
import 'widgets/hatch_log.dart';

/// Inkubator — tab monitoring IoT (DESIGN.md §3): satu scroll menyatu.
class IncubatorScreen extends ConsumerWidget {
  const IncubatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoProvider);
    final mqtt = ref.watch(mqttProvider);
    final statusAsync = ref.watch(incubatorStatusProvider);
    final rotationAsync = ref.watch(rotationLogsProvider);
    final logsAsync = ref.watch(incubatorStatusHistoryProvider);
    final eggsAsync = ref.watch(eggsListProvider);
    final chicksAsync = ref.watch(chicksListProvider);
    final user = ref.watch(currentUserProvider);
    final canEdit = user?.role == 'pemilik' || user?.role == 'staff';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mqttProvider.notifier).connectIfNeeded();
    });

    IncubatorStatus? effective;
    if (demo.active) {
      effective = demo.status;
    } else if (mqtt.hasTelemetry) {
      effective = IncubatorStatus(
        id: 0,
        suhuSekarang: mqtt.temperature!,
        kelembapanSekarang: mqtt.humidity!,
        lampuStatus: mqtt.statusLamp ?? 'OFF',
      );
    } else {
      effective = statusAsync.valueOrNull;
    }

    // Rotasi terakhir: field status dulu, fallback entri "sukses" terbaru
    // dari riwayat (kontrak backend: status log "sukses"/"gagal", case-insensitive).
    DateTime? lastRotation = effective?.terakhirRotasi;
    String? lastRotationRaw;
    if (lastRotation == null) {
      final rotations = rotationAsync.valueOrNull;
      if (rotations != null && rotations.isNotEmpty) {
        final sukses = rotations
            .where((r) => r.status.trim().toLowerCase() == 'sukses')
            .toList();
        DateTime? latest;
        String? latestRaw;
        for (final r in sukses) {
          final t = DateTime.tryParse(r.timestamp);
          if (t != null) {
            if (latest == null || t.isAfter(latest)) {
              latest = t;
              latestRaw = null;
            }
          } else if (latest == null &&
              latestRaw == null &&
              r.timestamp.isNotEmpty) {
            // Tak terparse: tampilkan raw apa adanya daripada "-".
            latestRaw = r.timestamp;
          }
        }
        lastRotation = latest;
        lastRotationRaw = latest == null ? latestRaw : null;
      }
    }

    // Menangkan yang terbaru: picu manual lokal mengalahkan nilai basi
    // dari tabel status/log (keduanya hanya berubah bila ada yang menulis).
    if (!demo.active) {
      final manual = mqtt.lastManualRotation;
      if (manual != null &&
          (lastRotation == null || manual.isAfter(lastRotation))) {
        lastRotation = manual;
        lastRotationRaw = null;
      }
    }

    return Scaffold(
      appBar: RootAppBar(
        title: 'Inkubator',
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Pengaturan',
              onPressed: () => context.push('/incubator/settings'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          unawaited(ref.read(mqttProvider.notifier).refreshConnection());
          ref.invalidate(incubatorStatusProvider);
          ref.invalidate(rotationLogsProvider);
          ref.invalidate(incubatorStatusHistoryProvider);
          ref.invalidate(eggsListProvider);
          ref.invalidate(chicksListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const DemoBanner(),
            HeaderStats(status: effective),
            const SizedBox(height: 16),
            BioDomeHero(
              status: effective,
              isLive: mqtt.hasTelemetry && !demo.active,
              lastRotation: lastRotation,
              lastRotationRaw: lastRotationRaw,
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Fase Embrio'),
            const SizedBox(height: 12),
            EmbryoCard(eggsAsync: eggsAsync),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Kontrol Telemetri'),
            const SizedBox(height: 12),
            TelemetryControls(
              mqttLamp: mqtt.statusLamp,
              mqttMist: mqtt.statusMist,
              mqttMotor: mqtt.statusMotor,
              mqttLive: mqtt.isLive,
              canControl: canEdit,
              demoActive: demo.active,
              lastRotation: lastRotation,
              lastRotationRaw: lastRotationRaw,
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Grafik'),
            const SizedBox(height: 12),
            ChartCard(logsAsync: logsAsync),
            const SizedBox(height: 20),
            const SectionHeader(title: 'CCTV Live'),
            const SizedBox(height: 12),
            const CctvLiveCard(),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Log Penetasan',
              trailing: 'Lihat semua',
            ),
            const SizedBox(height: 12),
            HatchLog(chicksAsync: chicksAsync),
            const SizedBox(height: 12),
            if (canEdit)
              ElevatedButton.icon(
                onPressed: () => context.push('/eggs/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Catat Telur'),
              ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Kesiapan Brooder'),
            const SizedBox(height: 12),
            BrooderCard(status: effective),
          ],
        ),
      ),
    );
  }
}
