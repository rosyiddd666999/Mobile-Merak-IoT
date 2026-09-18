import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/dashboard_summary.dart';

class FinanceSummaryCard extends StatelessWidget {
  final FinanceSummary summary;

  const FinanceSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ringkasan Keuangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _row(Icons.arrow_downward, 'Pemasukan', formatRupiah(summary.totalPemasukan), AppColors.success),
            const SizedBox(height: 8),
            _row(Icons.arrow_upward, 'Pengeluaran', formatRupiah(summary.totalPengeluaran), AppColors.critical),
            const Divider(height: 24),
            _row(Icons.account_balance_wallet, 'Saldo', formatRupiah(summary.saldo), AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
      ],
    );
  }
}
