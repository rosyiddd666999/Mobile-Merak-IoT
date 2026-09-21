import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_routes.dart';
import '../../core/status_mapper.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../shared/async_state_view.dart';
import '../../shared/app_photo.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/design_kit.dart';
import '../../shared/detail_app_bar.dart';
import '../../shared/detail_section.dart';

class ChickDetailScreen extends ConsumerWidget {
  final String id;

  const ChickDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chickAsync = ref.watch(chickDetailProvider(id));
    final user = ref.watch(currentUserProvider);
    final canDelete =
        user?.role == 'pemilik' || user?.role == 'staff';

    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Anakan'),
      body: AsyncStateView(
        async: chickAsync,
        onRetry: () => ref.refresh(chickDetailProvider(id)),
        dataBuilder: (chick) {
          final deleting = ref.watch(chickDeleteProvider).isLoading;
          final status = StatusMapper.chick(chick.status);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      AppPhotoCircle(
                        radius: 32,
                        url: chick.fotoUrl,
                        backgroundColor: AppColors.tertiary,
                        fallback: const Icon(Icons.cruelty_free, color: AppColors.tertiary, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chick.id,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDate(chick.tanggalMenetas),
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            StatusChip(label: status.$1, status: status.$2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DetailSection(
                title: 'Informasi',
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        DetailRow(icon: Icons.egg_outlined, label: 'Egg ID', value: chick.eggId),
                        if (chick.indukJantanId != null) ...[
                          const DetailDivider(),
                          DetailRow(icon: Icons.male, label: 'Indukan Jantan', value: chick.indukJantanId!),
                        ],
                        if (chick.indukBetinaId != null) ...[
                          const DetailDivider(),
                          DetailRow(icon: Icons.female, label: 'Indukan Betina', value: chick.indukBetinaId!),
                        ],
                        const DetailDivider(),
                        DetailRow(icon: Icons.monitor_weight_outlined, label: 'Berat Awal', value: '${chick.beratAwal.toStringAsFixed(0)} gram'),
                        const DetailDivider(),
                        DetailRow(icon: Icons.health_and_safety_outlined, label: 'Skor Kesehatan', value: chick.skorKesehatan),
                        const DetailDivider(),
                        DetailRow(icon: Icons.flag_outlined, label: 'Status', value: status.$1),
                      ],
                    ),
                  ),
                ],
              ),
              if (chick.catatan != null && chick.catatan!.isNotEmpty) ...[
                const SizedBox(height: 16),
                DetailNote(chick.catatan),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push('${AppRoutes.chickDetail(chick.id)}/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit nomor'),
              ),
              if (canDelete) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: deleting
                      ? null
                      : () => _onDelete(context, ref, chick.id),
                  icon: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline,
                          color: AppColors.critical),
                  label: Text(
                    deleting ? 'Menghapus…' : 'Hapus anakan',
                    style: const TextStyle(color: AppColors.critical),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.critical),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Anakan = leaf (tanpa anak relasi): konfirmasi langsung.
  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    String chickId,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus anakan?',
      message: 'Anakan $chickId akan dihapus permanen dan tidak bisa dibatalkan.',
      confirmText: 'Hapus',
    );
    if (!ok || !context.mounted) return;
    await ref.read(chickDeleteProvider.notifier).deleteChick(chickId);
    if (!context.mounted) return;
    final state = ref.read(chickDeleteProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: ${friendlyApiError(state.error!)}'),
          backgroundColor: AppColors.critical,
        ),
      );
      ref.read(chickDeleteProvider.notifier).reset();
      return;
    }
    ref.invalidate(chicksListProvider);
    ref.invalidate(dashboardProvider);
    ref.read(chickDeleteProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anakan berhasil dihapus')),
    );
    context.pop();
  }
}
