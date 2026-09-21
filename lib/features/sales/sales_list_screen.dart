import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_routes.dart';
import '../../core/theme.dart';
import '../../data/models/sale.dart';
import '../../data/providers/sales_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/async_state_view.dart';
import '../../shared/design_kit.dart';
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
              onPressed: () => context.push(AppRoutes.saleNew),
              backgroundColor: AppColors.darkCard,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(salesListProvider.future),
        child: AsyncStateView(
          async: salesAsync,
          loadingMessage: 'Memuat data penjualan...',
          emptyIcon: Icons.sell_outlined,
          emptyMessage: 'Belum ada data penjualan',
          onRetry: () => ref.refresh(salesListProvider),
          isEmpty: (sales) => sales.isEmpty,
          dataBuilder: (sales) {
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
                    children: [
                      for (final f in ['Semua', 'Lunas', 'Proses'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppFilterChip(
                            label: f,
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                        ),
                    ],
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
                        onTap: () => context.push(AppRoutes.saleDetail(s.id)),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}
