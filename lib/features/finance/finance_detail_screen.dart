import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/status_mapper.dart';
import '../../core/theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/number_formatter.dart';
import '../../data/models/finance_entry.dart';
import '../../data/providers/api_client_provider.dart';
import '../../shared/async_state_view.dart';
import '../../shared/design_kit.dart';
import '../../shared/detail_app_bar.dart';
import '../../shared/detail_section.dart';

final financeDetailProvider = FutureProvider.family<FinanceEntry, String>((ref, id) async {
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
      body: AsyncStateView(
        async: entryAsync,
          actionLabel: 'memuat detail keuangan',
        onRetry: () => ref.refresh(financeDetailProvider(id)),
        dataBuilder: (entry) {
          final isIncome = entry.tipe.toLowerCase() == 'pemasukan';
          final color = isIncome ? AppColors.success : AppColors.critical;
          final typeStatus = StatusMapper.financeType(entry.tipe);
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
                      StatusChip(label: typeStatus.$1, status: typeStatus.$2),
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
              DetailSection(
                title: 'Informasi',
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        DetailRow(icon: Icons.calendar_today, label: 'Tanggal', value: formatDate(entry.tanggal)),
                        const DetailDivider(),
                        DetailRow(icon: Icons.confirmation_number_outlined, label: 'ID', value: entry.id),
                        const DetailDivider(),
                        DetailRow(icon: Icons.person_outline, label: 'Dibuat oleh', value: entry.createdBy),
                      ],
                    ),
                  ),
                ],
              ),
              if (entry.catatan != null && entry.catatan!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                DetailNote(entry.catatan),
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
