import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../data/providers/users_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';
import 'widgets/user_tile.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final user = ref.watch(currentUserProvider);
    final isPemilik = user?.role == 'pemilik';
    final canCreate = isPemilik;

    return Scaffold(
      appBar: const DetailAppBar(title: 'Pengguna'),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/users/new'),
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(usersListProvider.future),
        child: usersAsync.when(
          loading: () => const LoadingWidget(message: 'Memuat data pengguna...'),
          error: (err, _) => AppErrorWidget(
            message: friendlyApiError(err),
            onRetry: () => ref.refresh(usersListProvider),
          ),
          data: (users) {
            if (users.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Belum ada data pengguna',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i];
                return UserTile(
                  user: u,
                  onTap: () => context.push('/users/${u.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
