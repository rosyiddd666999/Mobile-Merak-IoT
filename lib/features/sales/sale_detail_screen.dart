import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/status_mapper.dart';
import '../../core/theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/providers/sales_provider.dart';
import '../../shared/async_state_view.dart';
import '../../shared/design_kit.dart';
import '../../shared/detail_app_bar.dart';
import '../../shared/detail_section.dart';

class SaleDetailScreen extends ConsumerWidget {
  final String id;

  const SaleDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(id));

    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Penjualan'),
      body: AsyncStateView(
        async: saleAsync,
        onRetry: () => ref.refresh(saleDetailProvider(id)),
        dataBuilder: (sale) {
          final total = sale.qty * sale.hargaSatuan;
          final status = StatusMapper.sale(sale.status);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                            child: const Icon(Icons.sell, color: AppColors.secondary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale.item,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  sale.id,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(label: status.$1, status: status.$2),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              formatRupiah(total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
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
              DetailSection(
                title: 'Informasi',
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        DetailRow(icon: Icons.calendar_today, label: 'Tanggal', value: formatDate(sale.tanggal)),
                        const DetailDivider(),
                        DetailRow(icon: Icons.person_outline, label: 'Pembeli', value: sale.pembeli),
                        const DetailDivider(),
                        DetailRow(icon: Icons.numbers, label: 'Qty', value: '${sale.qty}'),
                        const DetailDivider(),
                        DetailRow(icon: Icons.payments_outlined, label: 'Harga Satuan', value: formatRupiah(sale.hargaSatuan)),
                        if (sale.referensiId.isNotEmpty) ...[
                          const DetailDivider(),
                          DetailRow(icon: Icons.link, label: 'Referensi ID', value: sale.referensiId),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (sale.catatan != null && sale.catatan!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                DetailNote(sale.catatan),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit (Segera)'),
              ),
            ],
          );
        },
      ),
    );
  }
}
