import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/chick.dart';
import '../models/dashboard_summary.dart';
import '../models/egg.dart';
import 'api_client_provider.dart';

part 'dashboard_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DashboardSummary> dashboard(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  DashboardSummary? server;
  try {
    final response = await dio.get('/api/dashboard/summary');
    try {
      server = DashboardSummary.fromJson(response.data);
    } catch (_) {
      server = null;
    }
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) rethrow;
    if (e.response?.statusCode != 404) {
      // Error jaringan/timeout: tampilkan error agar bisa retry (bukan diam nol).
      rethrow;
    }
    // 404 = router belum mount -> murni lokal.
  } catch (_) {
    server = null;
  }

  final local = await _localCounts(ref);
  if (server == null) {
    return DashboardSummary(
      totalTelurAktif: local.$1,
      totalAnakanBulanIni: local.$2,
      isLocal: true,
    );
  }
  // Gabung: pakai nilai terbesar agar angka tetap muncul walau summary backend nol.
  return DashboardSummary(
    totalTelurAktif: max(server.totalTelurAktif, local.$1),
    totalAnakanBulanIni: max(server.totalAnakanBulanIni, local.$2),
    inkubatorStatus: server.inkubatorStatus,
    financeSummary: server.financeSummary,
    isLocal: false,
  );
}

/// Hitung lokal dari endpoint LIVE.
/// Telur aktif = `akhir == Proses`; anakan bulan ini dari `tanggal_menetas`.
Future<(int, int)> _localCounts(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  var telur = 0;
  var anakan = 0;

  try {
    final res = await dio.get('/api/eggs');
    final data = res.data;
    if (data is List) {
      for (final e in data) {
        if (e is! Map<String, dynamic>) continue;
        try {
          final egg = Egg.fromJson(e);
          if (egg.akhir.toLowerCase() == 'proses') telur++;
        } catch (_) {}
      }
    }
  } catch (_) {}

  try {
    final res = await dio.get('/api/chicks');
    final data = res.data;
    if (data is List) {
      final now = DateTime.now();
      for (final e in data) {
        if (e is! Map<String, dynamic>) continue;
        try {
          final chick = Chick.fromJson(e);
          final t = DateTime.tryParse(chick.tanggalMenetas);
          if (t != null && t.year == now.year && t.month == now.month) anakan++;
        } catch (_) {}
      }
    }
  } catch (_) {
    // Endpoint chicks belum mount (404) -> anakan 0.
  }

  return (telur, anakan);
}
