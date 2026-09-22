import 'package:flutter/material.dart';
import 'alert_margins.dart';
import 'theme.dart';
import '../data/models/incubator_settings.dart';

/// Status 3-state cermin backend/web:
/// Ideal (dalam range) / Waspada (zona margin, kuning, tanpa notifikasi) /
/// Perhatian (lewat margin, merah — backend membuat record Alert).
enum ThresholdState { ideal, waspada, perhatian }

extension ThresholdStateX on ThresholdState {
  String get label {
    switch (this) {
      case ThresholdState.ideal:
        return 'Ideal';
      case ThresholdState.waspada:
        return 'Waspada';
      case ThresholdState.perhatian:
        return 'Perhatian';
    }
  }

  Color get color {
    switch (this) {
      case ThresholdState.ideal:
        return AppColors.statusActive;
      case ThresholdState.waspada:
        return AppColors.statusPending;
      case ThresholdState.perhatian:
        return AppColors.statusAlert;
    }
  }

  AppStatus get appStatus {
    switch (this) {
      case ThresholdState.ideal:
        return AppStatus.active;
      case ThresholdState.waspada:
        return AppStatus.pending;
      case ThresholdState.perhatian:
        return AppStatus.alert;
    }
  }
}

/// Klasifikasi suhu terhadap [min]–[max] + margin.
/// Contoh 37,5–38,5: 37,4 → ideal; 37,2 → waspada; 37,1 → perhatian.
ThresholdState classifyTemp(double v, double min, double max) {
  if (v < min - AlertMargins.suhu || v > max + AlertMargins.suhu) {
    return ThresholdState.perhatian;
  }
  if (v < min || v > max) return ThresholdState.waspada;
  return ThresholdState.ideal;
}

/// Klasifikasi kelembapan (margin ±[AlertMargins.kelembapan]).
ThresholdState classifyHum(double v, double min, double max) {
  if (v < min - AlertMargins.kelembapan ||
      v > max + AlertMargins.kelembapan) {
    return ThresholdState.perhatian;
  }
  if (v < min || v > max) return ThresholdState.waspada;
  return ThresholdState.ideal;
}

/// Gabungan: terburuk dari suhu & kelembapan.
ThresholdState classifyOverall({
  required double suhu,
  required double lembap,
  required IncubatorSettings settings,
}) {
  const order = [
    ThresholdState.ideal,
    ThresholdState.waspada,
    ThresholdState.perhatian,
  ];
  final a = classifyTemp(suhu, settings.suhuMin, settings.suhuMax);
  final b = classifyHum(
      lembap, settings.kelembapanMin, settings.kelembapanMax);
  return order[a.index > b.index ? a.index : b.index];
}

/// Fallback web: dipakai saat settings DB belum termuat.
IncubatorSettings webFallbackSettings() => IncubatorSettings(
      id: 0,
      suhuMin: 37.5,
      suhuMax: 38.5,
      kelembapanMin: 55.0,
      kelembapanMax: 65.0,
      intervalRotasiMenit: 240,
    );
