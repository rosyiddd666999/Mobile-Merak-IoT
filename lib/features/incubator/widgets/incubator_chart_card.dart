import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/utils/api_error.dart';
import '../../../data/models/telemetry_log.dart';
import '../../../data/providers/incubator_provider.dart';
import '../../../data/providers/mqtt_provider.dart';
import '../../../shared/design_kit.dart';
import '../../../shared/error_widget.dart';
import '../../../shared/loading_widget.dart';
import 'telemetry_chart.dart';

enum _ChartMode { suhu, kelembapan }

/// Satu kartu grafik dengan toggle Suhu | Kelembapan + chip sumber
/// (Riwayat server vs Live MQTT).
class ChartCard extends ConsumerStatefulWidget {
  final AsyncValue<List<TelemetryLog>> logsAsync;

  const ChartCard({super.key, required this.logsAsync});

  @override
  ConsumerState<ChartCard> createState() => ChartCardState();
}

class ChartCardState extends ConsumerState<ChartCard> {
  _ChartMode _mode = _ChartMode.suhu;

  @override
  Widget build(BuildContext context) {
    // Fallback Jalur B: bila riwayat server kosong, pakai buffer live
    // 24 titik dari MQTT (hilang saat restart, tergantikan otomatis
    // begitu endpoint history backend hidup).
    final mqtt = ref.watch(mqttProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_ChartMode>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
                segments: const [
                  ButtonSegment(value: _ChartMode.suhu, label: Text('Suhu')),
                  ButtonSegment(
                    value: _ChartMode.kelembapan,
                    label: Text('Kelembapan'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: widget.logsAsync.when(
                loading: () => const LoadingWidget(),
                error: (err, _) => AppErrorWidget(
                  message: friendlyApiError(err),
                  onRetry: () => ref.refresh(incubatorStatusHistoryProvider),
                ),
                data: (logs) {
                  final bool live;
                  final List<TelemetryLog> source;
                  if (logs.isNotEmpty) {
                    source = logs;
                    live = false;
                  } else if (mqtt.trend.isNotEmpty) {
                    source = mqtt.trend;
                    live = true;
                  } else {
                    final waiting =
                        mqtt.status == 'connecting' ||
                        mqtt.status == 'reconnecting';
                    return Center(
                      child: Text(
                        waiting
                            ? 'Menunggu data live…'
                            : 'Belum ada data telemetry',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusChip(
                        label: live ? 'Live' : 'Riwayat',
                        status: live ? AppStatus.active : AppStatus.neutral,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _mode == _ChartMode.suhu
                            ? TelemetryTempChart(logs: source)
                            : TelemetryHumidityChart(logs: source),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
