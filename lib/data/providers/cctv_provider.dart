import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/cctv_snapshot.dart';
import '../services/cctv_service.dart';
import 'api_client_provider.dart';
import 'secure_storage_provider.dart';

part 'cctv_provider.g.dart';

/// Riwayat snapshot CCTV (`GET /api/cctv-snapshots`, terbaru dulu bila API
/// mendukung `?limit`). Live stream tetap via MJPEG; ini galeri statis.
@Riverpod(keepAlive: true)
Future<List<CctvSnapshot>> cctvSnapshots(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  final res = await dio.get(
    '/api/cctv-snapshots',
    queryParameters: {'limit': 50},
  );
  final data = res.data;
  final raw = data is List
      ? data
      : (data is Map<String, dynamic> && data['data'] is List
          ? data['data'] as List
          : const []);
  return raw
      .whereType<Map<String, dynamic>>()
      .map(CctvSnapshot.fromJson)
      .where((s) => s.url.isNotEmpty)
      .toList();
}

enum CctvFeed { inkubator, kandang }

const _kCctvCustomKey = 'cctv_custom_url';
const _kCctvBaseKey = 'cctv_custom_base';

class CctvState {
  final CctvFeed selected;
  final bool? reachable; // null = belum tahu
  final bool checking;
  final int cacheBuster;
  final String? error;
  final int? lastStatusCode;
  final String? customBase; // override host CCTV, null = CCTV_BASE_URL

  const CctvState({
    this.selected = CctvFeed.inkubator,
    this.reachable,
    this.checking = false,
    this.cacheBuster = 0,
    this.error,
    this.lastStatusCode,
    this.customBase,
  });

  /// Host CCTV efektif: setting user > CCTV_BASE_URL (.env).
  /// null = pakai AppConstants.cctvBaseUrl di service.
  String? get effectiveBase {
    if (customBase != null && customBase!.trim().isNotEmpty) return customBase!.trim();
    return null;
  }

  CctvState copyWith({
    CctvFeed? selected,
    bool? reachable,
    bool? clearReachable,
    bool? checking,
    int? cacheBuster,
    String? error,
    bool? clearError,
    int? lastStatusCode,
    String? customBase,
  }) =>
      CctvState(
        selected: selected ?? this.selected,
        reachable: clearReachable == true ? null : (reachable ?? this.reachable),
        checking: checking ?? this.checking,
        cacheBuster: cacheBuster ?? this.cacheBuster,
        error: clearError == true ? null : (error ?? this.error),
        lastStatusCode: lastStatusCode ?? this.lastStatusCode,
        customBase: customBase ?? this.customBase,
      );
}

@Riverpod(keepAlive: true)
class Cctv extends _$Cctv {
  @override
  CctvState build() => const CctvState();

  CctvService get _service => CctvService(ref.read(apiClientProvider));

  Future<void> loadCustom() async {
    try {
      final storage = ref.read(secureStorageProvider);
      // Bersihkan sisa override lama (?url= sudah tidak dipakai).
      await storage.delete(key: _kCctvCustomKey);
      final savedBase = await storage.read(key: _kCctvBaseKey);
      if (savedBase != null && savedBase.trim().isNotEmpty) {
        // Tolak nilai lama yang tidak lolos aturan https-only.
        if (CctvService.sanitizeCustomBase(savedBase) == null) {
          await storage.delete(key: _kCctvBaseKey);
          return;
        }
        state = state.copyWith(customBase: savedBase.trim());
      }
    } catch (_) {}
  }

  /// Simpan override host CCTV. Hanya terima HTTPS valid (lihat
  /// [CctvService.sanitizeCustomBase]); nilai http/IP lokal ditolak agar
  /// token tidak exfil ke host arbitrari. Return false bila ditolak.
  Future<bool> saveBase(String base) async {
    final v = base.trim().replaceAll(RegExp(r'/+$'), '');
    if (v.isNotEmpty && CctvService.sanitizeCustomBase(v) == null) {
      return false;
    }
    try {
      if (v.isEmpty) {
        await ref.read(secureStorageProvider).delete(key: _kCctvBaseKey);
      } else {
        await ref.read(secureStorageProvider).write(key: _kCctvBaseKey, value: v);
      }
    } catch (_) {}
    state = state.copyWith(
      customBase: v.isEmpty ? null : v,
      clearReachable: true,
      clearError: true,
      cacheBuster: DateTime.now().millisecondsSinceEpoch,
    );
    pollHealth();
    return true;
  }

  void select(CctvFeed feed) {
    if (state.selected == feed) return;
    state = state.copyWith(selected: feed, clearError: true);
  }

  /// Polling health tiap 8 dtk dari screen (MOBILE.md §7.5).
  Future<void> pollHealth() async {
    if (state.checking) return;
    state = state.copyWith(checking: true, clearError: true);
    try {
      final reachable = await _service.fetchReachable(baseOverride: state.effectiveBase);
      state = state.copyWith(checking: false, reachable: reachable ?? state.reachable);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      state = state.copyWith(
        checking: false,
        reachable: false,
        lastStatusCode: code,
        error: code == 401
            ? 'Tidak berwenang (401). Periksa API Key / login.'
            : code == 404
                ? 'Health tidak ditemukan (404) di host ini. Cek CCTV_BASE_URL.'
                : 'Gateway tidak terjangkau',
      );
    } catch (_) {
      state = state.copyWith(checking: false, reachable: false, error: 'Gateway tidak terjangkau');
    }
  }

  /// Tombol Hubungkan Ulang: reset ?t= + state health (MOBILE.md §6.19.4).
  void reconnect() {
    state = state.copyWith(
      cacheBuster: DateTime.now().millisecondsSinceEpoch,
      clearReachable: true,
      clearError: true,
    );
    pollHealth();
  }

  void reportStreamError() {
    state = state.copyWith(reachable: false, error: 'Stream terputus');
  }
}
