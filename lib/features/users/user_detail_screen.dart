import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/user.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/users_provider.dart';
import '../../shared/confirm_dialog.dart';
import '../../shared/design_kit.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';

/// Detail dari list (backend tidak punya GET /api/users/:id -> 405).
final userDetailProvider = FutureProvider.family<User, String>((ref, id) async {
  final users = await ref.watch(usersListProvider.future);
  for (final u in users) {
    if (u.id == id) return u;
  }
  throw StateError('Pengguna tidak ditemukan (mungkin sudah dihapus)');
});

class UserDetailScreen extends ConsumerWidget {
  final String id;

  const UserDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailProvider(id));
    final me = ref.watch(currentUserProvider);
    final canDelete = me?.role == 'pemilik';

    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Pengguna'),
      body: userAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => AppErrorWidget(
          message: friendlyApiError(err),
          onRetry: () => ref.invalidate(usersListProvider),
        ),
        data: (user) {
          final isPemilik = user.role == 'pemilik';
          final initial = user.nama.isNotEmpty ? user.nama.substring(0, 1).toUpperCase() : '?';
          final deleting = ref.watch(userDeleteProvider).isLoading;
          final allUsers = ref.watch(usersListProvider).valueOrNull ?? const <User>[];
          final pemilikCount = allUsers.where((u) => u.role == 'pemilik').length;
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
                        backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.12),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.nama,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            StatusChip(
                              label: isPemilik ? 'Pemilik' : 'Staff',
                              status: isPemilik ? AppStatus.active : AppStatus.neutral,
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
                    _infoRow(Icons.badge_outlined, 'ID', user.id),
                    _divider(),
                    _infoRow(Icons.email_outlined, 'Email', user.email),
                    _divider(),
                    _infoRow(Icons.person_outline, 'Role', isPemilik ? 'Pemilik' : 'Staff'),
                    if (user.createdAt != null) ...[
                      _divider(),
                      _infoRow(Icons.calendar_today, 'Terdaftar', formatDate(user.createdAt!.toIso8601String())),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit (Segera)'),
              ),
              if (canDelete) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: deleting
                      ? null
                      : () => _onDelete(
                            context,
                            ref,
                            user,
                            me?.id,
                            pemilikCount,
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
                    deleting ? 'Menghapus…' : 'Hapus pengguna',
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

  /// Hapus dengan guard: diri sendiri + pemilik terakhir diblokir.
  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    User user,
    String? myId,
    int pemilikCount,
  ) async {
    if (myId != null && myId == user.id) {
      await showBlockedDeleteDialog(
        context,
        title: 'Tidak bisa dihapus',
        message: 'Kamu tidak bisa menghapus akunmu sendiri.',
      );
      return;
    }
    if (user.role == 'pemilik' && pemilikCount <= 1) {
      await showBlockedDeleteDialog(
        context,
        title: 'Tidak bisa dihapus',
        message:
            '${user.nama} adalah pemilik terakhir. Tambahkan pemilik lain dulu.',
      );
      return;
    }
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus pengguna?',
      message:
          '${user.nama} (${user.email}) akan dihapus permanen dan tidak bisa dibatalkan.',
      confirmText: 'Hapus',
    );
    if (!ok || !context.mounted) return;
    await ref.read(userDeleteProvider.notifier).deleteUser(user.id);
    if (!context.mounted) return;
    final state = ref.read(userDeleteProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: ${friendlyApiError(state.error!)}'),
          backgroundColor: AppColors.critical,
        ),
      );
      ref.read(userDeleteProvider.notifier).reset();
      return;
    }
    ref.invalidate(usersListProvider);
    ref.read(userDeleteProvider.notifier).reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengguna berhasil dihapus')),
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
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 0.5);
}
