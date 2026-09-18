import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/egg.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/dashboard_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/design_kit.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';

class EggDetailScreen extends ConsumerWidget {
  final String id;

  const EggDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eggAsync = ref.watch(eggDetailProvider(id));
    final breedersAsync = ref.watch(breedersListProvider);
    final chicksAsync = ref.watch(chicksListProvider);
    final user = ref.watch(currentUserProvider);
    final canDelete =
        user?.role == 'pemilik' || user?.role == 'staff';

    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Telur'),
      body: eggAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => AppErrorWidget(
          message: friendlyApiError(err),
          onRetry: () => ref.refresh(eggDetailProvider(id)),
        ),
        data: (egg) {
          final breeders = breedersAsync.valueOrNull ?? const [];
          final names = {
            for (final b in breeders)
              b.id: (b.nama?.isNotEmpty == true ? b.nama! : b.id),
          };
          final anak = (chicksAsync.valueOrNull ?? const [])
              .where((c) => c.eggId == egg.id)
              .toList();
          final deleting = ref.watch(eggDeleteProvider).isLoading;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Slot',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                height: 1,
                              ),
                            ),
                            Text(
                              '${egg.slot}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                                height: 1.1,
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
                            Text(
                              egg.id,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatDate(egg.tanggalMasuk),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                StatusChip(
                                  label: _fertilLabel(egg.fertilitas),
                                  status: _fertilStatus(egg.fertilitas),
                                ),
                                StatusChip(
                                  label: _akhirLabel(egg.akhir),
                                  status: _akhirStatus(egg.akhir),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Indukan'),
              Card(
                child: Column(
                  children: [
                    _parentRow(
                      context,
                      Icons.male,
                      'Indukan Jantan',
                      egg.indukJantanId,
                      names[egg.indukJantanId],
                    ),
                    _divider(),
                    _parentRow(
                      context,
                      Icons.female,
                      'Indukan Betina',
                      egg.indukBetinaId,
                      names[egg.indukBetinaId],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Perkembangan'),
              _growthCard(egg),
              if (anak.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'Anakan'),
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < anak.length; i++) ...[
                        ListTile(
                          dense: true,
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.cruelty_free,
                                size: 19, color: AppColors.primaryTeal),
                          ),
                          title: Text(
                            anak[i].id,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${formatDate(anak[i].tanggalMenetas)} · ${anak[i].beratAwal.toStringAsFixed(0)}g',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.textMuted),
                          onTap: () => context.push('/chicks/${anak[i].id}'),
                        ),
                        if (i < anak.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
                ),
              ],
              if (egg.catatan != null && egg.catatan!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'Catatan'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      egg.catatan!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push('/eggs/${egg.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit nomor'),
              ),
              if (canDelete) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: deleting
                      ? null
                      : () => _onDelete(context, ref, egg.id, anak.length),
                  icon: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline,
                          color: AppColors.critical),
                  label: Text(
                    deleting ? 'Menghapus…' : 'Hapus telur',
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

  Widget _divider() {
    return const Divider(height: 1, thickness: 0.5);
  }

  /// Hapus dengan guard relasi: beranak -> blokir informatif.
  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    String eggId,
    int childChicks,
  ) async {
    if (childChicks > 0) {
      await showBlockedDeleteDialog(
        context,
        title: 'Tidak bisa dihapus',
        message:
            'Telur $eggId sudah menetas menjadi $childChicks anakan. Hapus data anakan tersebut dulu.',
      );
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus telur?',
      message: 'Telur $eggId akan dihapus permanen dan tidak bisa dibatalkan.',
      confirmText: 'Hapus',
    );
    if (!ok || !context.mounted) return;
    await ref.read(eggDeleteProvider.notifier).deleteEgg(eggId);
    if (!context.mounted) return;
    final state = ref.read(eggDeleteProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: ${friendlyApiError(state.error!)}'),
          backgroundColor: AppColors.critical,
        ),
      );
      ref.read(eggDeleteProvider.notifier).reset();
      return;
    }
    ref.invalidate(eggsListProvider);
    ref.invalidate(dashboardProvider);
    ref.read(eggDeleteProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Telur berhasil dihapus')),
    );
    context.pop();
  }

  /// Baris induk tappable ke detailnya (nama bila dikenal, fallback ID).
  Widget _parentRow(
    BuildContext context,
    IconData icon,
    String label,
    String id,
    String? nama,
  ) {
    final display = (nama?.isNotEmpty == true) ? nama! : (id.isEmpty ? '-' : id);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Flexible(
            child: Text(
              display,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
          if (id.isNotEmpty) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
          ],
        ],
      ),
    );
    if (id.isEmpty) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/breeders/$id'),
      child: content,
    );
  }

  /// Kartu perkembangan: hari inkubasi + progress 28 hari, atau status final.
  Widget _growthCard(Egg egg) {
    final start = DateTime.tryParse(egg.tanggalMasuk);
    final akhir = egg.akhir.toLowerCase();
    final finished = akhir == 'menetas' || akhir == 'gagal';
    if (start == null || finished) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                finished && akhir == 'menetas'
                    ? Icons.check_circle
                    : finished
                        ? Icons.cancel_outlined
                        : Icons.help_outline,
                color: finished && akhir == 'menetas'
                    ? AppColors.statusActive
                    : finished
                        ? AppColors.statusAlert
                        : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  finished
                      ? 'Siklus selesai: ${_akhirLabel(egg.akhir)}'
                      : 'Tanggal masuk belum valid',
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final days = DateTime.now().difference(start).inDays.clamp(0, 28);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hari ke-${days + 1} dari 28',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                ),
                StatusChip(label: 'Proses', status: AppStatus.pending),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: (days + 1) / 28,
                minHeight: 8,
                backgroundColor:
                    AppColors.primaryTeal.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(
                    AppColors.primaryTeal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fertilLabel(String fertilitas) {
    switch (fertilitas.toLowerCase()) {
      case 'fertil':
        return 'Fertil';
      case 'infertil':
        return 'Infertil';
      default:
        return fertilitas;
    }
  }

  AppStatus _fertilStatus(String fertilitas) {
    switch (fertilitas.toLowerCase()) {
      case 'fertil':
        return AppStatus.active;
      case 'infertil':
        return AppStatus.alert;
      default:
        return AppStatus.neutral;
    }
  }

  AppStatus _akhirStatus(String akhir) {
    switch (akhir.toLowerCase()) {
      case 'menetas':
        return AppStatus.active;
      case 'gagal':
        return AppStatus.alert;
      case 'proses':
        return AppStatus.pending;
      default:
        return AppStatus.neutral;
    }
  }

  String _akhirLabel(String akhir) {
    switch (akhir.toLowerCase()) {
      case 'menetas':
        return 'Menetas';
      case 'gagal':
        return 'Gagal';
      case 'proses':
        return 'Proses';
      default:
        return akhir;
    }
  }
}
