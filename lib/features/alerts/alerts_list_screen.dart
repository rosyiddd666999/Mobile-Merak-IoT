import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../data/models/alert.dart';
import '../../data/providers/alerts_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/demo_provider.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/design_kit.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';
import 'widgets/alert_tile.dart';

class AlertsListScreen extends ConsumerStatefulWidget {
  const AlertsListScreen({super.key});

  @override
  ConsumerState<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends ConsumerState<AlertsListScreen> {
  bool _bulkCancelled = false;

  List<Alert> _olderThan(List<Alert> alerts, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final result = alerts
        .where((a) => a.createdAt != null && a.createdAt!.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
    return result;
  }

  Future<void> _showCleanupSheet(List<Alert> alerts) async {
    var days = 30;
    final picked = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final count = _olderThan(alerts, days).length;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bersihkan notifikasi lama',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hanya yang lebih tua dari ambang yang dipilih.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total ${alerts.length} notifikasi di server.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                RadioGroup<int>(
                  groupValue: days,
                  onChanged: (v) => setSheet(() => days = v ?? 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final d in [1, 7, 30, 90])
                        RadioListTile<int>(
                          value: d,
                          title: Text(
                            'Lebih dari $d hari (${_olderThan(alerts, d).length})',
                            style: const TextStyle(fontSize: 14),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: count == 0 ? null : () => Navigator.pop(ctx, days),
                    child: Text(count == 0
                        ? 'Tidak ada yang perlu dibersihkan'
                        : 'Lanjut ($count)'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (picked == null || !mounted) return;
    final targets = _olderThan(alerts, picked);
    if (targets.isEmpty || !mounted) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus ${targets.length} notifikasi?',
      message:
          'Notifikasi lebih dari $picked hari akan dihapus permanen dan tidak bisa dibatalkan.',
      confirmText: 'Hapus',
    );
    if (!ok || !mounted) return;
    _bulkCancelled = false;
    var dialogOpen = true;
    ref.read(alertBulkProgressProvider.notifier).state = 0;
    final future = ref.read(alertDeleteProvider.notifier).deleteMany(
          targets.map((a) => a.id).toList(),
          isCancelled: () => _bulkCancelled,
        );
    // Dialog tidak di-await: ditutup otomatis saat pekerjaan selesai.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Membersihkan…'),
          content: Consumer(
            builder: (ctx, ref, _) {
              final p = ref.watch(alertBulkProgressProvider) ?? 0;
              final done = (p * targets.length).round();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: p),
                  const SizedBox(height: 8),
                  Text('$done/${targets.length}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _bulkCancelled = true;
                dialogOpen = false;
                Navigator.pop(ctx);
              },
              child: const Text('Batal'),
            ),
          ],
        ),
      ).then((_) => dialogOpen = false),
    );
    final result = await future;
    ref.read(alertBulkProgressProvider.notifier).state = null;
    if (!mounted) return;
    // Pekerjaan selesai -> tutup dialog bila masih terbuka (pasca Batal
    // sudah tertutup sendiri, jangan pop halaman di bawahnya).
    if (dialogOpen) {
      dialogOpen = false;
      Navigator.pop(context);
    }
    final wasCancelled = _bulkCancelled;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasCancelled
            ? 'Dibatalkan: ${result.deleted} terhapus'
            : result.failed == 0
                ? '${result.deleted} notifikasi lama dihapus'
                : '${result.deleted} dihapus, ${result.failed} gagal — coba lagi'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoProvider);
    final alertsAsync = ref.watch(alertsListProvider);
    final user = ref.watch(currentUserProvider);
    final isPemilik = user?.role == 'pemilik';

    final demoAlerts = demo.alerts;
    final realAlerts = alertsAsync.maybeWhen(
      data: (l) => l,
      orElse: () => <Alert>[],
    );

    final alerts = demo.active ? demoAlerts : realAlerts;
    final isLoading = !demo.active && alertsAsync.isLoading;
    final hasError = !demo.active && alertsAsync.hasError;
    final errorMsg = alertsAsync.hasError ? friendlyApiError(alertsAsync.error!) : null;

    return Scaffold(
      appBar: DetailAppBar(
        title: 'Notifikasi',
        actions: [
          if (isPemilik && !demo.active)
            IconButton(
              icon: const Icon(Icons.cleaning_services_outlined),
              tooltip: 'Bersihkan notifikasi lama',
              onPressed: () => _showCleanupSheet(realAlerts),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (demo.active) return;
          await ref.read(alertsListProvider.future);
        },
        child: isLoading
            ? const LoadingWidget()
            : hasError
                ? AppErrorWidget(
                    message: errorMsg!,
                    onRetry: () async {
                      await ref.read(alertsListProvider.future);
                    },
                  )
                : alerts.isEmpty
                    ? const EmptyState(
                        icon: Icons.notifications_outlined,
                        message: 'Tidak ada notifikasi',
                      )
                    : ListView.builder(
                        itemCount: alerts.length,
                        itemBuilder: (_, i) {
                          final alert = alerts[i];
                          return AlertTile(
                            alert: alert,
                            onMarkRead: () {
                              if (demo.active) {
                                ref.read(demoProvider.notifier).markAlertRead(alert.id);
                              }
                            },
                            onDelete: null,
                          );
                        },
                      ),
      ),
    );
  }
}
