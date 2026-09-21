import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/models/telemetry_log.dart';
import '../../../data/providers/mqtt_provider.dart';
import '../../../shared/loading_widget.dart';
import '../../incubator/widgets/telemetry_chart.dart';

enum MiniMode { suhu, kelembapan }

/// Mini grafik (12 titik terakhir) + toggle Suhu | Kelembapan.
/// Tap area grafik = pindah ke tab Inkubator.
/// Fallback Jalur B: riwayat server kosong -> buffer live MQTT.
class MiniTrendCard extends ConsumerStatefulWidget {
  final AsyncValue<List<TelemetryLog>> logsAsync;
  final VoidCallback onTap;

  const MiniTrendCard({
    super.key,
    required this.logsAsync,
    required this.onTap,
  });

  @override
  ConsumerState<MiniTrendCard> createState() => _MiniTrendCardState();
}

class _MiniTrendCardState extends ConsumerState<MiniTrendCard> {
  MiniMode _mode = MiniMode.suhu;

  List<TelemetryLog> _slice(List<TelemetryLog> source) =>
      source.length > 12 ? source.sublist(source.length - 12) : source;

  @override
  Widget build(BuildContext context) {
    final mqtt = ref.watch(mqttProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<MiniMode>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                segments: const [
                  ButtonSegment(value: MiniMode.suhu, label: Text('Suhu')),
                  ButtonSegment(
                    value: MiniMode.kelembapan,
                    label: Text('Kelembapan'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onTap,
              child: SizedBox(
                height: 120,
                child: widget.logsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (_, _) {
                    if (mqtt.trend.isNotEmpty) {
                      return _miniChart(_slice(mqtt.trend));
                    }
                    return const Center(
                      child: Text(
                        'Grafik tidak tersedia',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                  data: (logs) {
                    final source = logs.isNotEmpty ? logs : mqtt.trend;
                    if (source.isEmpty) {
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
                    return _miniChart(_slice(source));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChart(List<TelemetryLog> logs) => _mode == MiniMode.suhu
      ? TelemetryTempChart(logs: logs)
      : TelemetryHumidityChart(logs: logs);
}
