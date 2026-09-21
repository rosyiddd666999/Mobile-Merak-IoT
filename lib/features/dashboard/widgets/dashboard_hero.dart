import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/dashboard_summary.dart';

/// 1 dark hero di paling atas (DESIGN.md §5): sapaan + 3 baris penuh.
/// Baris = tombol pindah tab; suhu tidak di sini (sudah ada kartunya sendiri).
class DarkHero extends StatelessWidget {
  final String nama;
  final DashboardSummary summary;
  final int? indukanTotal;
  final VoidCallback onTelur;
  final VoidCallback onAnakan;
  final VoidCallback onIndukan;

  const DarkHero({
    super.key,
    required this.nama,
    required this.summary,
    required this.indukanTotal,
    required this.onTelur,
    required this.onAnakan,
    required this.onIndukan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $nama',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Ringkasan peternakan hari ini',
            style: TextStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          HeroRow(
            icon: Icons.egg_outlined,
            value: '${summary.totalTelurAktif}',
            label: 'Telur Aktif',
            onTap: onTelur,
          ),
          const SizedBox(height: 8),
          HeroRow(
            icon: Icons.flutter_dash,
            value: '${summary.totalAnakanBulanIni}',
            label: 'Anakan Bulan Ini',
            onTap: onAnakan,
          ),
          const SizedBox(height: 8),
          HeroRow(
            icon: Icons.pets,
            value: indukanTotal != null ? '$indukanTotal' : '-',
            label: 'Indukan',
            onTap: onIndukan,
          ),
        ],
      ),
    );
  }
}

class HeroRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  const HeroRow({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
