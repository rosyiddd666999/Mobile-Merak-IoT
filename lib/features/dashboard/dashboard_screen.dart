import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/models/breeder.dart';
import '../../data/models/chick.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/models/incubator_settings.dart';
import '../../data/models/incubator_status.dart';
import '../../data/models/telemetry_log.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../data/providers/demo_provider.dart';
import '../../data/providers/incubator_provider.dart';
import '../../data/providers/mqtt_provider.dart';
import '../../shared/design_kit.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/root_app_bar.dart';
import '../incubator/widgets/mqtt_status_badge.dart';
import '../incubator/widgets/telemetry_chart.dart';
import 'widgets/incubator_status_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final demo = ref.watch(demoProvider);
    final mqtt = ref.watch(mqttProvider);
    final restStatusAsync = ref.watch(incubatorStatusProvider);
    final breedersAsync = ref.watch(breedersListProvider);
    final chicksAsync = ref.watch(chicksListProvider);
    final logsAsync = ref.watch(incubatorStatusHistoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mqttProvider.notifier).connectIfNeeded();
    });
    final settingsAsync = ref.watch(incubatorSettingsProvider);

    return Scaffold(
      appBar: const RootAppBar(title: 'Dashboard'),
      body: RefreshIndicator(
        onRefresh: () async {
          unawaited(ref.read(mqttProvider.notifier).refreshConnection());
          ref.invalidate(dashboardProvider);
          ref.invalidate(breedersListProvider);
          ref.invalidate(chicksListProvider);
          ref.invalidate(incubatorStatusHistoryProvider);
          await ref.read(dashboardProvider.future);
        },
        child: dashboardAsync.when(
          loading: () => const LoadingWidget(message: 'Memuat dashboard...'),
          error: (err, _) => AppErrorWidget(
            message: friendlyApiError(err),
            onRetry: () => ref.refresh(dashboardProvider),
          ),
          data: (summary) {
            final isPemilik = user?.role == 'pemilik';
            IncubatorStatus? mqttStatus;
            if (mqtt.hasTelemetry) {
              mqttStatus = IncubatorStatus(
                id: 0,
                suhuSekarang: mqtt.temperature!,
                kelembapanSekarang: mqtt.humidity!,
                lampuStatus: mqtt.statusLamp ?? 'OFF',
              );
            }
            final restStatus = restStatusAsync.valueOrNull;
            final effectiveStatus = demo.active
                ? demo.status
                : (mqttStatus ?? summary.inkubatorStatus ?? restStatus);

            final indukanTotal = breedersAsync.maybeWhen(
              data: (list) => list.length,
              orElse: () => null,
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _DarkHero(
                  nama: user?.nama ?? 'Pengguna',
                  summary: summary,
                  indukanTotal: indukanTotal,
                  onTelur: () => context.go('/eggs'),
                  onAnakan: () => context.go('/eggs'),
                  onIndukan: () => context.go('/breeders'),
                ),
                const SizedBox(height: 12),
                const MqttStatusBadge(compact: true),
                if (summary.isLocal) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ringkasan lokal dari data telur/anakan',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                const SectionHeader(title: 'Status Inkubator'),
                const SizedBox(height: 12),
                if (effectiveStatus != null)
                  GestureDetector(
                    onTap: () => context.go('/incubator'),
                    child: IncubatorStatusCard(status: effectiveStatus),
                  )
                else
                  _NoIncubatorCard(
                    onDemo: () {
                      final settings =
                          settingsAsync.valueOrNull ??
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
                  ),
                const SizedBox(height: 12),
                _MiniTrendCard(
                  logsAsync: logsAsync,
                  onTap: () => context.go('/incubator'),
                ),
                if (isPemilik && summary.financeSummary != null) ...[
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Keuangan'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/finance'),
                    child: _FinanceMiniCard(summary: summary),
                  ),
                ],
                const SizedBox(height: 20),
                const SectionHeader(title: 'Siklus Telur'),
                const SizedBox(height: 12),
                _EggCycleCard(summary: summary),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Indukan'),
                const SizedBox(height: 12),
                _BreederPreview(
                  breedersAsync: breedersAsync,
                  onOpenTab: () => context.go('/breeders'),
                  onOpenDetail: (id) => context.push('/breeders/$id'),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Anakan'),
                const SizedBox(height: 12),
                _ChickPreview(
                  chicksAsync: chicksAsync,
                  onOpenDetail: (id) => context.push('/chicks/$id'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 1 dark hero di paling atas (DESIGN.md §5): sapaan + 3 baris penuh.
/// Baris = tombol pindah tab; suhu tidak di sini (sudah ada kartunya sendiri).
class _DarkHero extends StatelessWidget {
  final String nama;
  final DashboardSummary summary;
  final int? indukanTotal;
  final VoidCallback onTelur;
  final VoidCallback onAnakan;
  final VoidCallback onIndukan;

  const _DarkHero({
    required this.nama,
    required this.summary,
    required this.indukanTotal,
    required this.onTelur,
    required this.onAnakan,
    required this.onIndukan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $nama',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Ringkasan peternakan hari ini',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          _HeroRow(
            icon: Icons.egg_outlined,
            value: '${summary.totalTelurAktif}',
            label: 'Telur Aktif',
            onTap: onTelur,
          ),
          const SizedBox(height: 8),
          _HeroRow(
            icon: Icons.flutter_dash,
            value: '${summary.totalAnakanBulanIni}',
            label: 'Anakan Bulan Ini',
            onTap: onAnakan,
          ),
          const SizedBox(height: 8),
          _HeroRow(
            icon: Icons.pets,
            value: indukanTotal != null ? '$indukanTotal' : '-',
            label: 'Indukan',
            onTap: onIndukan,
          ),
        ],
      ),
    );
  }
}

class _HeroRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _HeroRow({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

/// Egg Cycle Card dengan progress ring (DESIGN.md §3.3).
class _EggCycleCard extends StatelessWidget {
  final DashboardSummary summary;

  const _EggCycleCard({required this.summary});

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

class _NoIncubatorCard extends StatelessWidget {
  final VoidCallback onDemo;

  const _NoIncubatorCard({required this.onDemo});

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

enum _MiniMode { suhu, kelembapan }

/// Mini grafik (12 titik terakhir) + toggle Suhu | Kelembapan.
/// Tap area grafik = pindah ke tab Inkubator.
/// Fallback Jalur B: riwayat server kosong -> buffer live MQTT.
class _MiniTrendCard extends ConsumerStatefulWidget {
  final AsyncValue<List<TelemetryLog>> logsAsync;
  final VoidCallback onTap;

  const _MiniTrendCard({required this.logsAsync, required this.onTap});

  @override
  ConsumerState<_MiniTrendCard> createState() => _MiniTrendCardState();
}

class _MiniTrendCardState extends ConsumerState<_MiniTrendCard> {
  _MiniMode _mode = _MiniMode.suhu;

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
              child: SegmentedButton<_MiniMode>(
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                segments: const [
                  ButtonSegment(value: _MiniMode.suhu, label: Text('Suhu')),
                  ButtonSegment(
                    value: _MiniMode.kelembapan,
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

  Widget _miniChart(List<TelemetryLog> logs) => _mode == _MiniMode.suhu
      ? TelemetryTempChart(logs: logs)
      : TelemetryHumidityChart(logs: logs);
}

/// Ringkasan 3 indukan teratas. Tap item = detail, tap "tab" via header induk.
class _BreederPreview extends StatelessWidget {
  final AsyncValue<List<Breeder>> breedersAsync;
  final VoidCallback onOpenTab;
  final ValueChanged<String> onOpenDetail;

  const _BreederPreview({
    required this.breedersAsync,
    required this.onOpenTab,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return breedersAsync.when(
      loading: () => const LoadingWidget(),
      error: (_, _) => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: EmptyState(
            icon: Icons.pets,
            message: 'Data indukan tidak tersedia',
          ),
        ),
      ),
      data: (breeders) {
        if (breeders.isEmpty) {
          return const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.pets,
                message: 'Belum ada data indukan',
              ),
            ),
          );
        }
        final top = breeders.take(3).toList();
        return Card(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < top.length; i++) ...[
                ListTile(
                  dense: true,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 20,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  title: Text(
                    top[i].nama?.isNotEmpty == true ? top[i].nama! : top[i].id,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${top[i].generasi} · ${top[i].jenisKelamin}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: StatusChip(
                    label: top[i].status,
                    status: top[i].status == 'ready_for_sale'
                        ? AppStatus.ready
                        : top[i].status == 'breeding'
                        ? AppStatus.active
                        : AppStatus.pending,
                  ),
                  onTap: () => onOpenDetail(top[i].id),
                ),
                if (i < top.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
              ListTile(
                dense: true,
                title: Text(
                  breeders.length > 3
                      ? 'Lihat ${breeders.length - 3} indukan lainnya'
                      : 'Buka tab Indukan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryTeal,
                ),
                onTap: onOpenTab,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Ringkasan 3 anakan terbaru. Tap item = detail.
class _ChickPreview extends StatelessWidget {
  final AsyncValue<List<Chick>> chicksAsync;
  final ValueChanged<String> onOpenDetail;

  const _ChickPreview({required this.onOpenDetail, required this.chicksAsync});

  @override
  Widget build(BuildContext context) {
    return chicksAsync.when(
      loading: () => const LoadingWidget(),
      error: (_, _) => const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: EmptyState(
            icon: Icons.cruelty_free,
            message: 'Data anakan tidak tersedia',
          ),
        ),
      ),
      data: (chicks) {
        if (chicks.isEmpty) {
          return const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: EmptyState(
                icon: Icons.cruelty_free,
                message: 'Belum ada anakan menetas',
              ),
            ),
          );
        }
        final top = chicks.take(3).toList();
        return Card(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < top.length; i++) ...[
                ListTile(
                  dense: true,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.egg_outlined,
                      size: 20,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                  title: Text(
                    top[i].id,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${top[i].beratAwal.toStringAsFixed(0)}g',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                  onTap: () => onOpenDetail(top[i].id),
                ),
                if (i < top.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FinanceMiniCard extends StatelessWidget {
  final DashboardSummary summary;

  const _FinanceMiniCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final f = summary.financeSummary!;
    final total = f.totalPemasukan + f.totalPengeluaran;
    final sections = total <= 0
        ? [
            PieChartSectionData(
              value: 1,
              color: AppColors.divider,
              radius: 14,
              showTitle: false,
            ),
          ]
        : [
            PieChartSectionData(
              value: f.totalPemasukan,
              color: AppColors.statusActive,
              radius: 14,
              showTitle: false,
            ),
            PieChartSectionData(
              value: f.totalPengeluaran,
              color: AppColors.statusAlert,
              radius: 14,
              showTitle: false,
            ),
          ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Keuangan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                StatusChip(
                  label: total <= 0 ? 'Kosong' : 'Live',
                  status: total <= 0 ? AppStatus.neutral : AppStatus.active,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatRupiah(f.saldo),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Saldo kas',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 26,
                      startDegreeOffset: -90,
                      sections: sections,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _FlowRow(
                        icon: Icons.south_west,
                        color: AppColors.statusActive,
                        label: 'Pemasukan',
                        value: formatRupiah(f.totalPemasukan),
                      ),
                      const SizedBox(height: 10),
                      _FlowRow(
                        icon: Icons.north_east,
                        color: AppColors.statusAlert,
                        label: 'Pengeluaran',
                        value: formatRupiah(f.totalPengeluaran),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris legenda arus kas: ikon arah + label + nominal.
class _FlowRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _FlowRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
