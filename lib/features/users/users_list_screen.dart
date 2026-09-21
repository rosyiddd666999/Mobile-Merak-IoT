import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_routes.dart';
import '../../core/status_mapper.dart';
import '../../data/providers/users_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/async_state_view.dart';
import '../../shared/detail_app_bar.dart';
import 'widgets/user_tile.dart';

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final user = ref.watch(currentUserProvider);
    final isPemilik = UserRoleX.fromString(user?.role ?? '') == UserRole.pemilik;
    final canCreate = isPemilik;

    return Scaffold(
      appBar: const DetailAppBar(title: 'Pengguna'),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.userNew),
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(usersListProvider.future),
        child: AsyncStateView(
          async: usersAsync,
          loadingMessage: 'Memuat data pengguna...',
          emptyIcon: Icons.people_outlined,
          emptyMessage: 'Belum ada data pengguna',
          onRetry: () => ref.refresh(usersListProvider),
          isEmpty: (users) => users.isEmpty,
          dataBuilder: (users) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              return UserTile(
                user: u,
                onTap: () => context.push(AppRoutes.userDetail(u.id)),
              );
            },
          ),
        ),
      ),
    );
  }
}
