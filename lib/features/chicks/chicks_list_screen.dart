import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
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
              onPressed: () => context.push('/chicks/new'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(chicksListProvider.future),
        child: chicksAsync.when(
          loading: () => const LoadingWidget(message: 'Memuat data anakan...'),
          error: (err, _) => AppErrorWidget(
            message: friendlyApiError(err),
            onRetry: () => ref.refresh(chicksListProvider),
          ),
          data: (chicks) {
            if (chicks.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Belum ada data anakan',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: chicks.length,
              itemBuilder: (_, i) {
                final chick = chicks[i];
                return ChickCard(
                  chick: chick,
                  onTap: () => context.push('/chicks/${chick.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
