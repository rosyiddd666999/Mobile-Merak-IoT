import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/finance_entry.dart';
import '../../../shared/app_card.dart';

class FinanceEntryCard extends StatelessWidget {
  final FinanceEntry entry;
  final VoidCallback? onTap;

  const FinanceEntryCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.tipe.toLowerCase() == 'pemasukan';
    final color = isIncome ? AppColors.statusActive : AppColors.statusAlert;
    final icon = isIncome ? Icons.trending_up : Icons.trending_down;

    return AppRowCard(
      onTap: onTap,
      leading: AppLeadingBox(
        size: 44,
        color: color,
        child: Icon(icon, color: color, size: 22),
      ),
      title: entry.kategori.isEmpty ? '-' : entry.kategori,
      subtitle: formatDate(entry.tanggal),
      showChevron: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isIncome ? '+' : '-'}${formatCompact(entry.jumlah)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }
}
