import 'package:flutter/material.dart';
import '../../shared/detail_app_bar.dart';
import '../../shared/partner_logos.dart';

/// Halaman statis Informasi Aplikasi — identitas + kerjasama.
/// Dibuka dari menu Profil (tanpa state/API).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const DetailAppBar(title: 'Informasi Aplikasi'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE6ECEA)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Media Edukasi Kampung Merak Gentan Hijau Berseri',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Text(
                        'Kerjasama',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PT Pertamina Patra Niaga FT Madiun',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const PartnerLogos(size: 52, wide: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _FeatureTile(
                  icon: Icons.thermostat,
                  title: 'Telemetri Inkubator IoT',
                  subtitle: 'Suhu, kelembapan, lampu, rotasi, dan mist',
                ),
                Divider(height: 1, indent: 56),
                _FeatureTile(
                  icon: Icons.account_tree_outlined,
                  title: 'Silsilah Indukan',
                  subtitle: 'Manajemen breeder F0 / F1 / F2',
                ),
                Divider(height: 1, indent: 56),
                _FeatureTile(
                  icon: Icons.egg_outlined,
                  title: 'Siklus Telur & Anakan',
                  subtitle: 'Pencatatan telur hingga chick lifecycle',
                ),
                Divider(height: 1, indent: 56),
                _FeatureTile(
                  icon: Icons.videocam_outlined,
                  title: 'CCTV & Penjualan',
                  subtitle: 'Pantau kandang dan kelola transaksi',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.group_outlined),
                      const SizedBox(width: 12),
                      Text(
                        'Tim Pengembang',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                const _FeatureTile(
                  icon: Icons.person_outline,
                  title: 'Abdul Rosyid',
                  subtitle: 'Pengembang Aplikasi & Perangkat IoT',
                ),
                const Divider(height: 1, indent: 56),
                const _FeatureTile(
                  icon: Icons.person_outline,
                  title: 'Prasetya Riski W',
                  subtitle: 'Pengembang Aplikasi & Perangkat IoT',
                ),
                const Divider(height: 1, indent: 56),
                const _FeatureTile(
                  icon: Icons.person_outline,
                  title: 'Bayu Adji N',
                  subtitle: 'Pengembang Aplikasi & Perangkat IoT',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2026 Kampung Merak',
              style: textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      dense: true,
    );
  }
}
