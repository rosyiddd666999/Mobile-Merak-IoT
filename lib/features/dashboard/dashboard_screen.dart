import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_routes.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../data/models/incubator_settings.dart';
import '../../data/models/incubator_status.dart';
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
import 'widgets/dashboard_hero.dart';
import 'widgets/egg_cycle_card.dart';
import 'widgets/incubator_status_card.dart';
import 'widgets/mini_trend_card.dart';
import 'widgets/preview_cards.dart';

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
                DarkHero(
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
                  NoIncubatorCard(
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
                MiniTrendCard(
                  logsAsync: logsAsync,
                  onTap: () => context.go('/incubator'),
                ),
                if (isPemilik && summary.financeSummary != null) ...[
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Keuangan'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/finance'),
                    child: FinanceMiniCard(summary: summary),
                  ),
                ],
                const SizedBox(height: 20),
                const SectionHeader(title: 'Siklus Telur'),
                const SizedBox(height: 12),
                EggCycleCard(summary: summary),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Indukan'),
                const SizedBox(height: 12),
                BreederPreview(
                  breedersAsync: breedersAsync,
                  onOpenTab: () => context.go('/breeders'),
                  onOpenDetail: (id) => context.push(AppRoutes.breederDetail(id)),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Anakan'),
                const SizedBox(height: 12),
                ChickPreview(
                  chicksAsync: chicksAsync,
                  onOpenDetail: (id) => context.push(AppRoutes.chickDetail(id)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
