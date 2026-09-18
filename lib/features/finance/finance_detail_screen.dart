import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/models/finance_entry.dart';
import '../../data/providers/api_client_provider.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/detail_app_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

final financeDetailProvider = riverpod.FutureProvider.family<FinanceEntry, String>((ref, id) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/finance/$id');
    return FinanceEntry.fromJson(response.data);
  } on DioException {
    rethrow;
  }
});

class FinanceDetailScreen extends ConsumerWidget {
  final String id;

  const FinanceDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(financeDetailProvider(id));

    return Scaffold(
      appBar: const DetailAppBar(title: 'Detail Keuangan'),
      body: entryAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => AppErrorWidget(
          message: friendlyApiError(err),
          onRetry: () => ref.refresh(financeDetailProvider(id)),
        ),
        data: (entry) {
          final isIncome = entry.tipe.toLowerCase() == 'pemasukan';
          final color = isIncome ? AppColors.success : AppColors.critical;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(
                          isIncome ? Icons.trending_up : Icons.trending_down,
                          color: color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        entry.kategori,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.tipe,
                        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${isIncome ? '+' : '-'} ${formatRupiah(entry.jumlah)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: color,
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
                    _infoRow(Icons.calendar_today, 'Tanggal', formatDate(entry.tanggal)),
                    _divider(),
                    _infoRow(Icons.confirmation_number_outlined, 'ID', entry.id),
                    _divider(),
                    _infoRow(Icons.person_outline, 'Dibuat oleh', entry.createdBy),
                  ],
                ),
              ),
              if (entry.catatan != null && entry.catatan!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionTitle(context, 'Catatan'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(entry.catatan!, style: const TextStyle(fontSize: 14, height: 1.5)),
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
}
