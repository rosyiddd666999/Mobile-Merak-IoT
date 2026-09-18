import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Bottom nav 5 tab: Dashboard · Inkubator · Indukan · Telur · Keuangan.
/// Tab Keuangan (index terakhir) disembunyikan untuk non-pemilik.
/// Branch shell selalu 5 berurutan sehingga index 0-3 tetap selaras.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isPemilik;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isPemilik = false,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.thermostat),
          label: 'Inkubator',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Indukan'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.egg_rounded),
          label: 'Telur',
        ),
        if (isPemilik)
          const BottomNavigationBarItem(
            icon: Icon(Icons.payments),
            label: 'Keuangan',
          ),
      ],
    );
  }
}
