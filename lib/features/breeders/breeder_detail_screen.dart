import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';

class BreederDetailScreen extends ConsumerWidget {
  final String id;

  const BreederDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breederAsync = ref.watch(breederDetailProvider(id));
    final user = ref.watch(currentUserProvider);
    final canDelete =
        user?.role == 'pemilik' || user?.role == 'staff';

    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Indukan'),
      body: breederAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => AppErrorWidget(
          message: friendlyApiError(err),
          onRetry: () => ref.refresh(breederDetailProvider(id)),
        ),
        data: (breeder) {
          final isJantan = breeder.jenisKelamin == 'jantan';
          final genderColor = isJantan ? AppColors.info : AppColors.secondary;
          final statusColor = _statusColor(breeder.status);
          final deleting = ref.watch(breederDeleteProvider).isLoading;
          // Relasi anak (dihitung lokal, pola sama seperti stats list).
          final eggs = ref.watch(eggsListProvider).valueOrNull ?? const [];
          final allBreeders =
              ref.watch(breedersListProvider).valueOrNull ?? const [];
          final chicks = ref.watch(chicksListProvider).valueOrNull ?? const [];
          final eggById = {for (final e in eggs) e.id: e};
          final childEggs = eggs
              .where((e) =>
                  e.indukJantanId == breeder.id ||
                  e.indukBetinaId == breeder.id)
              .length;
          final childBreeders = allBreeders
              .where((b) =>
                  b.parentJantanId == breeder.id ||
                  b.parentBetinaId == breeder.id)
              .length;
          final childChicks = chicks.where((c) {
            final egg = eggById[c.eggId];
            return egg != null &&
                (egg.indukJantanId == breeder.id ||
                    egg.indukBetinaId == breeder.id);
          }).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: genderColor.withValues(alpha: 0.12),
                        child: Icon(
                          isJantan ? Icons.male : Icons.female,
                          color: genderColor,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              breeder.nama ?? breeder.id,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (breeder.nama != null && breeder.nama!.isNotEmpty)
                              Text(
                                breeder.id,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _statusLabel(breeder.status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                    _infoRow(Icons.wc, 'Jenis Kelamin', isJantan ? 'Jantan' : 'Betina'),
                    _divider(),
                    _infoRow(Icons.layers_outlined, 'Generasi', breeder.generasi),
                    _divider(),
                    _infoRow(Icons.palette_outlined, 'Varian Warna', breeder.varianWarna),
                    _divider(),
                    _infoRow(Icons.flag_outlined, 'Asal', _asalLabel(breeder.asal)),
                    if (breeder.tanggalLahir != null) ...[
                      _divider(),
                      _infoRow(Icons.cake_outlined, 'Tanggal Lahir', formatDate(breeder.tanggalLahir!.toIso8601String())),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Performa'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _metric('Total Telur', '${breeder.totalTelur}', Icons.egg_outlined)),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(child: _metric('% Fertil', '${breeder.persentaseFertil.toStringAsFixed(0)}%', Icons.percent)),
                      Container(width: 1, height: 40, color: AppColors.divider),
                      Expanded(child: _metric('Anakan', '${breeder.jumlahAnakan}', Icons.cruelty_free)),
                    ],
                  ),
                ),
              ),
              if (breeder.parentJantanId != null || breeder.parentBetinaId != null) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'Silsilah'),
                Card(
                  child: Column(
                    children: [
                      if (breeder.parentJantanId != null)
                        _parentRow(context, Icons.male, 'Ayah', breeder.parentJantanId!),
                      if (breeder.parentJantanId != null && breeder.parentBetinaId != null) _divider(),
                      if (breeder.parentBetinaId != null)
                        _parentRow(context, Icons.female, 'Ibu', breeder.parentBetinaId!),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push('/breeders/${breeder.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit nomor'),
              ),
              if (canDelete) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: deleting
                      ? null
                      : () => _onDelete(
                            context,
                            ref,
                            breeder.id,
                            breeder.nama ?? breeder.id,
                            childEggs,
                            childBreeders,
                            childChicks,
                          ),
                  icon: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline,
                          color: AppColors.critical),
                  label: Text(
                    deleting ? 'Menghapus…' : 'Hapus indukan',
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

  /// Hapus dengan guard relasi: beranak -> blokir informatif,
  /// tak beranak -> konfirmasi -> eksekusi -> refresh -> kembali.
  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    String breederId,
    String nama,
    int childEggs,
    int childBreeders,
    int childChicks,
  ) async {
    if (childEggs + childBreeders + childChicks > 0) {
      final parts = <String>[];
      if (childEggs > 0) parts.add('$childEggs telur');
      if (childBreeders > 0) parts.add('$childBreeders indukan anak');
      if (childChicks > 0) parts.add('$childChicks anakan');
      await showBlockedDeleteDialog(
        context,
        title: 'Tidak bisa dihapus',
        message:
            '$nama masih memiliki ${parts.join(', ')}. Hapus atau pindahkan data tersebut dulu.',
      );
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus indukan?',
      message: '$nama akan dihapus permanen dan tidak bisa dibatalkan.',
      confirmText: 'Hapus',
    );
    if (!ok || !context.mounted) return;
    await ref.read(breederDeleteProvider.notifier).deleteBreeder(breederId);
    if (!context.mounted) return;
    final state = ref.read(breederDeleteProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: ${friendlyApiError(state.error!)}'),
          backgroundColor: AppColors.critical,
        ),
      );
      ref.read(breederDeleteProvider.notifier).reset();
      return;
    }
    ref.invalidate(breedersListProvider);
    ref.invalidate(dashboardProvider);
    ref.read(breederDeleteProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Indukan berhasil dihapus')),
    );
    context.pop();
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, thickness: 0.5);
  }

  /// Baris induk yang bisa di-tap ke detailnya (jelajah silsilah tanpa putar balik).
  Widget _parentRow(BuildContext context, IconData icon, String label, String id) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/breeders/$id'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            Flexible(
              child: Text(
                id,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'breeding':
        return AppColors.statusActive;
      case 'resting':
        return AppColors.statusPending;
      case 'ready_for_sale':
        return AppColors.statusReady;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'breeding':
        return 'Aktif';
      case 'resting':
        return 'Istirahat';
      case 'ready_for_sale':
        return 'Siap Jual';
      default:
        return status;
    }
  }

  String _asalLabel(String asal) {
    switch (asal) {
      case 'beli':
        return 'Beli';
      case 'ternak_sendiri':
        return 'Ternak Sendiri';
      default:
        return asal;
    }
  }
}
