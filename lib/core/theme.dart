import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Legacy (dipakai screen yang belum migrasi — jangan pakai untuk kode baru).
  static const primary      = Color(0xFF2E7D32);
  static const primaryDark  = Color(0xFF1B5E20);
  static const primaryLight = Color(0xFF81C784);
  static const secondary    = Color(0xFFF9A825);
  static const tertiary     = Color(0xFF00897B);
  static const success      = Color(0xFF4CAF50);
  static const warning      = Color(0xFFFFC107);
  static const critical     = Color(0xFFF44336);
  static const surface      = Color(0xFFF5F5F5);
  static const surfaceCard  = Color(0xFFFFFFFF);
  static const textPrimary  = Color(0xFF1B1B1B);
  static const textSecondary= Color(0xFF757575);
  static const divider      = Color(0xFFE0E0E0);
  static const info         = Color(0xFF00897B);

  // Sistem baru — Avian Intelligence / MerakNK (DESIGN.md §1).
  static const bg            = Color(0xFFF5F7F6);
  static const darkCard      = Color(0xFF0E1B17);
  static const primaryTeal   = Color(0xFF16C79A);
  static const textDark      = Color(0xFF1A2421);
  static const textMuted     = Color(0xFF6B7772);

  static const statusActive  = Color(0xFF16C79A); // aktif/produksi/lunas/sehat
  static const statusPending = Color(0xFFF5A524); // observasi/proses/pending
  static const statusReady   = Color(0xFF3B82F6); // siap jual/selesai/verifikasi
  static const statusAlert   = Color(0xFFEF4444); // alert/gagal
  static const emptyValue    = Color(0xFF9AA5A0); // tanda "-" (netral, bukan status)
}

/// Status generik lintas screen (DESIGN.md §1 — hanya 4 warna + netral).
enum AppStatus { active, pending, ready, alert, neutral }

extension AppStatusColor on AppStatus {
  Color get color {
    switch (this) {
      case AppStatus.active:
        return AppColors.statusActive;
      case AppStatus.pending:
        return AppColors.statusPending;
      case AppStatus.ready:
        return AppColors.statusReady;
      case AppStatus.alert:
        return AppColors.statusAlert;
      case AppStatus.neutral:
        return AppColors.textMuted;
    }
  }
}

class AppRadius {
  static const double card = 20;
  static const double cardSmall = 16;
  static const double chip = 100;
}

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.critical,
    surface: AppColors.surface,
  ),
  scaffoldBackgroundColor: AppColors.bg,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bg,
    foregroundColor: AppColors.textDark,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: AppColors.surfaceCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: const BorderSide(color: Color(0xFFE6ECEA), width: 1),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkCard,
      foregroundColor: Colors.white,
      minimumSize: const Size(120, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.textDark,
      side: const BorderSide(color: Color(0xFFD5DDDA), width: 1.5),
      minimumSize: const Size(120, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.critical, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    labelStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    elevation: 2,
  ),
  fontFamily: GoogleFonts.inter().fontFamily,
  textTheme: GoogleFonts.interTextTheme(),
);
