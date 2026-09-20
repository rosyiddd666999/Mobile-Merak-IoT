import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config.dart';
import '../../core/constants.dart';
import 'auth_provider.dart';

// Preload dari flutter_secure_storage saat splash/login (MOBILE.md §7.1).
// Interceptor baca state sinkron — jangan baca storage async di onRequest.
final apiKeyProvider = StateProvider<String?>((ref) => null);
final jwtTokenProvider = StateProvider<String?>((ref) => null);

String _effectiveApiKey(Ref ref) {
  final fromState = ref.read(apiKeyProvider);
  if (fromState != null && fromState.isNotEmpty) return fromState;
  if (AppConfig.apiKeyAndroid.isNotEmpty) return AppConfig.apiKeyAndroid;
  // Fallback .env (dev): jangan hardcode key produksi di source.
  if (AppConstants.apiKeyAndroid.isNotEmpty) return AppConstants.apiKeyAndroid;
  return '';
}

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    // Runtime (.env) dulu, fallback dart-define — agar `flutter run` biasa benar.
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // 1. X-API-Key wajib di SEMUA request (MOBILE.md §2/§7.1).
      final apiKey = _effectiveApiKey(ref);
      if (apiKey.isNotEmpty) {
        options.headers['X-API-Key'] = apiKey;
      }
      // 2. JWT jika ada.
      final token = ref.read(jwtTokenProvider);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (err, handler) {
      if (!kReleaseMode) {
        _logDioError(err);
      }
      if (err.response?.statusCode == 401) {
        // Token expired / API Key invalid -> force logout.
        try {
          ref.read(authProvider.notifier).forceLogout();
        } catch (_) {}
      }
      handler.next(err);
    },
  ));

  return dio;
});

void _logDioError(DioException err) {
  final method = err.requestOptions.method;
  final url = err.requestOptions.uri.toString();
  final status = err.response?.statusCode;

  // Endpoint sakit yang diketahui (500 OperationalError server): cukup satu baris.
  if (url.contains('/api/incubator/status') && status != null && status >= 500) {
    debugPrint('[DIO] $method $url -> $status (server error, ditangani sebagai data kosong)');
    return;
  }

  // Endpoint history belum deploy (404): fallback berlapis menangani,
  // cukup satu baris agar console tidak penuh.
  if (url.contains('/api/incubator/status/history') && status == 404) {
    debugPrint('[DIO] $method $url -> 404 (endpoint belum ada, fallback aktif)');
    return;
  }

  final type = err.type.name;
  final message = err.message ?? '-';

  final safeHeaders = <String, dynamic>{};
  err.requestOptions.headers.forEach((k, v) {
    if (k.toLowerCase() == 'x-api-key' || k.toLowerCase() == 'authorization') {
      safeHeaders[k] = '<redacted>';
    } else {
      safeHeaders[k] = v;
    }
  });

  debugPrint('╔══ DIO ERROR ═══════════════════════════════════════');
  debugPrint('║ METHOD   : $method');
  debugPrint('║ URL      : $url');
  debugPrint('║ STATUS   : ${status ?? "-"}');
  debugPrint('║ TYPE     : $type');
  debugPrint('║ MESSAGE  : $message');
  debugPrint('║ HEADERS  : $safeHeaders');
  // Sengaja tidak log response body: bisa memuat PII/token.
  debugPrint('╚═════════════════════════════════════════════════════');
}
