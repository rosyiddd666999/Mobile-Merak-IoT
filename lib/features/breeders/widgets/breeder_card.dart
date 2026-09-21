import 'package:flutter/material.dart';
import '../../../core/status_mapper.dart';
import '../../../core/theme.dart';
import '../../../data/models/breeder.dart';
import '../../../shared/app_card.dart';
import '../../../shared/app_photo.dart';
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
    final status = sold ? ('Terjual', AppStatus.ready) : StatusMapper.breeder(breeder.status);
    final nama = (breeder.nama?.isNotEmpty == true) ? breeder.nama! : breeder.id;
    final sub = '${breeder.generasi} · ${isJantan ? 'Jantan' : 'Betina'}';

    return AppRowCard(
      onTap: onTap,
      leading: AppPhotoBox(
        url: breeder.fotoUrl,
        fallback: _fallbackIcon(isJantan),
      ),
      title: nama,
      subtitle: sub,
      trailing: StatusChip(label: status.$1, status: status.$2),
      meta: Text(
        _metrics(),
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
}
