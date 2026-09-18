import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../data/models/sale.dart';
import '../../data/providers/sales_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/design_kit.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';
import 'widgets/sale_card.dart';

class SalesListScreen extends ConsumerStatefulWidget {
  const SalesListScreen({super.key});

  @override
  ConsumerState<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends ConsumerState<SalesListScreen> {
  String _filter = 'Semua'; // Semua | Lunas | Proses

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesListProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = user != null;

    return Scaffold(
      appBar: const DetailAppBar(title: 'Penjualan'),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push('/sales/new'),
              backgroundColor: AppColors.darkCard,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(salesListProvider.future),
        child: salesAsync.when(
          loading: () => const LoadingWidget(message: 'Memuat data penjualan...'),
          error: (err, _) => AppErrorWidget(
            message: friendlyApiError(err),
            onRetry: () => ref.refresh(salesListProvider),
          ),
          data: (sales) {
            final filtered = _filter == 'Semua'
                ? sales
                : sales.where((s) {
                    final st = s.status.toLowerCase();
                    return _filter == 'Lunas' ? st == 'lunas' : st != 'lunas';
                  }).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Semua', 'Lunas', 'Proses'].map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: selected,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.darkCard,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.sell_outlined,
                    message: 'Belum ada data di kategori ini',
                  )
                else
                  ...filtered.map((Sale s) => SaleCard(
                        sale: s,
                        onTap: () => context.push('/sales/${s.id}'),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}
