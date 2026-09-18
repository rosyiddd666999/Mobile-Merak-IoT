import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../data/models/telemetry_log.dart';

/// Label waktu aman: HH:MM bila ISO penuh, apa adanya bila pendek.
String _timeLabel(String timestamp) {
  final t = timestamp.trim();
  if (t.length >= 16) return t.substring(11, 16);
  return t.isEmpty ? '-' : t;
}

/// Tepat 5 label X genap (0, n/4, n/2, 3n/4, n-1).
List<int> _labelIndexes(int n) {
  if (n <= 1) return [0];
  if (n <= 5) return List.generate(n, (i) => i);
  return [0, n ~/ 4, n ~/ 2, (3 * n) ~/ 4, n - 1];
}

/// Cangkang garis simple: sumbu fix, grid hanya di ticks, tanpa vertikal.
class _SimpleLineChart extends StatelessWidget {
  final List<TelemetryLog> logs;
  final List<FlSpot> spots;
  final Color color;
  final double minY;
  final double maxY;
  final List<double> yTicks;
  final String ySuffix;

  const _SimpleLineChart({
    required this.logs,
    required this.spots,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.yTicks,
    required this.ySuffix,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Text('Belum ada data telemetry'));
    }
    final labelIdx = _labelIndexes(logs.length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            checkToShowHorizontalLine: (value) => yTicks.any(
              (t) => (value - t).abs() < 0.001,
            ),
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppColors.divider, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: (v, _) => yTicks.any(
                  (t) => (v - t).abs() < 0.001,
                )
                    ? Text(
                        '${v % 1 == 0 ? v.toInt() : v}$ySuffix',
                        style: const TextStyle(fontSize: 10),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (!labelIdx.contains(idx) || idx >= logs.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _timeLabel(logs[idx].timestamp),
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grafik suhu: sumbu fix 35-41, ticks 36°/38°/40°.
class TelemetryTempChart extends StatelessWidget {
  final List<TelemetryLog> logs;

  const TelemetryTempChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return _SimpleLineChart(
      logs: logs,
      spots: logs.asMap().entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.temperature))
          .toList(),
      color: AppColors.critical,
      minY: 35,
      maxY: 41,
      yTicks: const [36, 38, 40],
      ySuffix: '°',
    );
  }
}

/// Grafik kelembapan: batas dinamis "nice" + tepat 3 ticks.
/// min = puluhan ke bawah dari (min-5), max = puluhan ke atas dari (max+5),
/// dijepit 0-100 agar spike tidak terpotong.
class TelemetryHumidityChart extends StatelessWidget {
  final List<TelemetryLog> logs;

  const TelemetryHumidityChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    var minY = 0.0;
    var maxY = 100.0;
    if (logs.isNotEmpty) {
      final values = logs.map((e) => e.humidity);
      final dmin = values.reduce((a, b) => a < b ? a : b);
      final dmax = values.reduce((a, b) => a > b ? a : b);
      minY = (((dmin - 5) / 10).floorToDouble() * 10).clamp(0, 100).toDouble();
      maxY = (((dmax + 5) / 10).ceilToDouble() * 10).clamp(0, 100).toDouble();
      if ((maxY - minY) < 10) {
        minY = (minY - 10).clamp(0, 100).toDouble();
        maxY = (maxY + 10).clamp(0, 100).toDouble();
      }
    }
    final midY = ((minY + maxY) / 2 / 10).roundToDouble() * 10;
    return _SimpleLineChart(
      logs: logs,
      spots: logs.asMap().entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.humidity))
          .toList(),
      color: AppColors.primaryTeal,
      minY: minY,
      maxY: maxY,
      yTicks: [minY, midY.clamp(minY, maxY), maxY],
      ySuffix: '%',
    );
  }
}

/// Kompatibilitas: grafik gabungan lama (suhu merah + lembap teal).
/// Dipakai di tempat yang belum migrasi ke split.
class TelemetryChart extends StatelessWidget {
  final List<TelemetryLog> logs;

  const TelemetryChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(child: Text('Belum ada data telemetry'));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppColors.divider, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) =>
                      Text('${v.toInt()}°', style: const TextStyle(fontSize: 10))),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: (logs.length / 5).ceilToDouble().clamp(1, double.infinity),
                  getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx >= logs.length) return const SizedBox();
                return Text(_timeLabel(logs[idx].timestamp),
                    style: const TextStyle(fontSize: 9));
              }),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: (logs.map((e) => e.temperature).reduce((a, b) => a < b ? a : b) - 2)
              .floorToDouble(),
          maxY: (logs.map((e) => e.temperature).reduce((a, b) => a > b ? a : b) + 2)
              .ceilToDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: logs.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.temperature))
                  .toList(),
              color: AppColors.critical,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.critical.withValues(alpha: 0.1),
                    AppColors.critical.withValues(alpha: 0.0)
                  ],
                ),
              ),
            ),
            LineChartBarData(
              spots: logs.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.humidity))
                  .toList(),
              color: AppColors.tertiary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.tertiary.withValues(alpha: 0.1),
                    AppColors.tertiary.withValues(alpha: 0.0)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
