import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/providers/sales_provider.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';

class SaleDetailScreen extends ConsumerWidget {
  final String id;

  const SaleDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(id));

    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Penjualan'),
      body: saleAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => AppErrorWidget(
          message: friendlyApiError(err),
          onRetry: () => ref.refresh(saleDetailProvider(id)),
        ),
        data: (sale) {
          final total = sale.qty * sale.hargaSatuan;
          final statusColor = _statusColor(sale.status);
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sale.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
              _sectionTitle(context, 'Informasi'),
              Card(
                child: Column(
                  children: [
                    _infoRow(Icons.calendar_today, 'Tanggal', formatDate(sale.tanggal)),
                    _divider(),
                    _infoRow(Icons.person_outline, 'Pembeli', sale.pembeli),
                    _divider(),
                    _infoRow(Icons.numbers, 'Qty', '${sale.qty}'),
                    _divider(),
                    _infoRow(Icons.payments_outlined, 'Harga Satuan', formatRupiah(sale.hargaSatuan)),
                    if (sale.referensiId.isNotEmpty) ...[
                      _divider(),
                      _infoRow(Icons.link, 'Referensi ID', sale.referensiId),
                    ],
                  ],
                ),
              ),
              if (sale.catatan != null && sale.catatan!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'Catatan'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(sale.catatan!, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ),
                ),
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

  Widget _divider() => const Divider(height: 1, thickness: 0.5);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lunas':
        return AppColors.success;
      case 'dp':
        return AppColors.warning;
      case 'booking':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
}
