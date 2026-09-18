import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/breeder.dart';
import '../../../shared/design_kit.dart';

/// Statistik performa per indukan, dihitung lokal dari list telur/anakan
/// (endpoint list tidak mengirim metrik — hanya detail yang punya).
class BreederStats {
  final int totalTelur;
  final double persentaseFertil;
  final int jumlahAnakan;

  const BreederStats({
    this.totalTelur = 0,
    this.persentaseFertil = 0,
    this.jumlahAnakan = 0,
  });
}

/// Card individu kompak (DESIGN.md §2.5): foto 56, nama ellipsis,
/// max 2 metrik inline, badge kanan atas, tappable + chevron, tanpa tombol.
class BreederCard extends StatelessWidget {
  final Breeder breeder;
  final VoidCallback? onTap;
  final BreederStats? stats;
  final bool sold;

  const BreederCard({super.key, required this.breeder, this.onTap, this.stats, this.sold = false});

  @override
  Widget build(BuildContext context) {
    final isJantan = breeder.jenisKelamin == 'jantan';
    final status = sold ? ('Terjual', AppStatus.ready) : _status(breeder.status);
    final nama = (breeder.nama?.isNotEmpty == true) ? breeder.nama! : breeder.id;
    final sub = '${breeder.generasi} · ${isJantan ? 'Jantan' : 'Betina'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: breeder.fotoUrl != null && breeder.fotoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(breeder.fotoUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _fallbackIcon(isJantan)),
                      )
                    : _fallbackIcon(isJantan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nama,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(label: status.$1, status: status.$2),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _metrics(),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon(bool isJantan) {
    return Icon(
      isJantan ? Icons.male : Icons.female,
      color: AppColors.primaryTeal,
      size: 28,
    );
  }

  /// Maksimal 2 metrik utama inline; kosong -> "-".
  /// Pakai [stats] lokal bila ada (list), fallback ke field detail.
  String _metrics() {
    final totalTelur = stats?.totalTelur ?? breeder.totalTelur;
    final fertil = stats?.persentaseFertil ?? breeder.persentaseFertil;
    final anakan = stats?.jumlahAnakan ?? breeder.jumlahAnakan;
    final parts = <String>[];
    if (totalTelur > 0) parts.add('$totalTelur telur');
    if (fertil > 0) {
      parts.add('${fertil.toStringAsFixed(0)}% fertil');
    }
    if (parts.length < 2 && anakan > 0) {
      parts.add('$anakan anakan');
    }
    if (parts.isEmpty) return '-';
    return parts.take(2).join(' · ');
  }

  (String, AppStatus) _status(String s) {
    switch (s) {
      case 'breeding':
        return ('Aktif', AppStatus.active);
      case 'resting':
        return ('Istirahat', AppStatus.pending);
      case 'ready_for_sale':
        return ('Siap Jual', AppStatus.ready);
      default:
        return (s.isEmpty ? '-' : s, AppStatus.neutral);
    }
  }
}
