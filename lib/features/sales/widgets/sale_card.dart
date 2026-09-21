import 'package:flutter/material.dart';
import '../../../core/status_mapper.dart';
import '../../../core/theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/sale.dart';
import '../../../shared/app_card.dart';
import '../../../shared/design_kit.dart';

/// Item transaksi 3 baris (DESIGN.md §4.4): kode+chip, pembeli, nominal.
class SaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback? onTap;

  const SaleCard({super.key, required this.sale, this.onTap});

  @override
  Widget build(BuildContext context) {
    final total = sale.qty * sale.hargaSatuan;
    final status = StatusMapper.sale(sale.status);
    return AppTappableCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sale.id.isEmpty ? '-' : sale.id,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: status.$1, status: status.$2),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sale.pembeli.isEmpty ? '-' : sale.pembeli,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${sale.qty} × ${formatRupiah(sale.hargaSatuan)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatRupiah(total),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatDate(sale.tanggal),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
