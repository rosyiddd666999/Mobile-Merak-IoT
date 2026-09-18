import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';

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
      body: chickAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => AppErrorWidget(
          message: friendlyApiError(err),
          onRetry: () => ref.refresh(chickDetailProvider(id)),
        ),
        data: (chick) {
          final deleting = ref.watch(chickDeleteProvider).isLoading;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.tertiary.withValues(alpha: 0.12),
                        child: const Icon(Icons.cruelty_free, color: AppColors.tertiary, size: 32),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Informasi'),
              Card(
                child: Column(
                  children: [
                    _infoRow(Icons.egg_outlined, 'Egg ID', chick.eggId),
                    _divider(),
                    if (chick.indukJantanId != null)
                      _infoRow(Icons.male, 'Indukan Jantan', chick.indukJantanId!),
                    if (chick.indukJantanId != null && chick.indukBetinaId != null) _divider(),
                    if (chick.indukBetinaId != null)
                      _infoRow(Icons.female, 'Indukan Betina', chick.indukBetinaId!),
                    if (chick.indukBetinaId != null) _divider(),
                    _infoRow(Icons.monitor_weight_outlined, 'Berat Awal', '${chick.beratAwal.toStringAsFixed(0)} gram'),
                    _divider(),
                    _infoRow(Icons.health_and_safety_outlined, 'Skor Kesehatan', chick.skorKesehatan),
                    _divider(),
                    _infoRow(Icons.flag_outlined, 'Status', chick.status),
                  ],
                ),
              ),
              if (chick.catatan != null && chick.catatan!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'Catatan'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(chick.catatan!, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push('/chicks/${chick.id}/edit'),
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

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Flexible(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 0.5);

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
