import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_routes.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/async_state_view.dart';
import '../../shared/detail_app_bar.dart';
import 'widgets/chick_card.dart';

class ChicksListScreen extends ConsumerWidget {
  const ChicksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chicksAsync = ref.watch(chicksListProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = user != null;

    return Scaffold(
      appBar: const DetailAppBar(title: 'Data Anakan'),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => context.push(AppRoutes.chickNew),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(chicksListProvider.future),
        child: AsyncStateView(
          async: chicksAsync,
          loadingMessage: 'Memuat data anakan...',
          emptyIcon: Icons.cruelty_free,
          emptyMessage: 'Belum ada data anakan',
          onRetry: () => ref.refresh(chicksListProvider),
          isEmpty: (chicks) => chicks.isEmpty,
          dataBuilder: (chicks) => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: chicks.length,
            itemBuilder: (_, i) {
              final chick = chicks[i];
              return ChickCard(
                chick: chick,
                onTap: () => context.push(AppRoutes.chickDetail(chick.id)),
              );
            },
          ),
        ),
      ),
    );
  }
}
