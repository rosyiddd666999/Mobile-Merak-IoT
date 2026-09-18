import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cctv_service.dart';
import 'api_client_provider.dart';
import 'secure_storage_provider.dart';

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

class CctvNotifier extends StateNotifier<CctvState> {
  final Ref _ref;
  CctvNotifier(this._ref) : super(const CctvState());

  CctvService get _service => CctvService(_ref.read(apiClientProvider));

  Future<void> loadCustom() async {
    try {
      final storage = _ref.read(secureStorageProvider);
      // Bersihkan sisa override lama (?url= sudah tidak dipakai).
      await storage.delete(key: _kCctvCustomKey);
      final savedBase = await storage.read(key: _kCctvBaseKey);
      if (savedBase != null && savedBase.trim().isNotEmpty) {
        state = state.copyWith(customBase: savedBase.trim());
      }
    } catch (_) {}
  }

  Future<void> saveBase(String base) async {
    final v = base.trim().replaceAll(RegExp(r'/+$'), '');
    try {
      if (v.isEmpty) {
        await _ref.read(secureStorageProvider).delete(key: _kCctvBaseKey);
      } else {
        await _ref.read(secureStorageProvider).write(key: _kCctvBaseKey, value: v);
      }
    } catch (_) {}
    state = state.copyWith(
      customBase: v.isEmpty ? null : v,
      clearReachable: true,
      clearError: true,
      cacheBuster: DateTime.now().millisecondsSinceEpoch,
    );
    pollHealth();
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

final cctvProvider = StateNotifierProvider<CctvNotifier, CctvState>((ref) => CctvNotifier(ref));
