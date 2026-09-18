import 'package:dio/dio.dart';
import '../../core/constants.dart';

/// Helper URL feed + fetch /cctv_health (MOBILE.md §6.19/§7.5, cctv.md).
/// Base URL dibaca runtime (.env -> dart-define) agar `flutter run` biasa benar.
class CctvService {
  CctvService(this._dio);
  final Dio _dio;

  Uri incubatorFeed({int? cacheBuster, String? baseOverride}) =>
      _feed(AppConstants.cctvInkubatorPath, cacheBuster, baseOverride);
  Uri kandangFeed({int? cacheBuster, String? baseOverride}) =>
      _feed(AppConstants.cctvKandangPath, cacheBuster, baseOverride);

  Uri _feed(String path, int? cacheBuster, String? baseOverride) {
    final rawBase = (baseOverride?.trim().isNotEmpty == true) ? baseOverride!.trim() : AppConstants.cctvBaseUrl;
    final base = rawBase.replaceAll(RegExp(r'/+$'), '');
    var uri = Uri.parse('$base$path');
    // Gateway mengabaikan query ?url= (FRONTEND_WEBSITE.md §3C.3) — jangan kirim
    // RTSP dari app (bocor ke log). Target RTSP murni env gateway server.
    if (cacheBuster != null) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, 't': '$cacheBuster'});
    }
    return uri;
  }

  Uri healthUri({String? baseOverride}) {
    final rawBase = (baseOverride?.trim().isNotEmpty == true) ? baseOverride!.trim() : AppConstants.cctvBaseUrl;
    return Uri.parse('${rawBase.replaceAll(RegExp(r'/+$'), '')}${AppConstants.cctvHealthPath}');
  }

  String get healthPath => AppConstants.cctvHealthPath;

  /// Health polling (pola CctvPage.jsx): baca `incubator_reachable: bool`.
  /// Return null bila field tidak ada; throw bila HTTP/gateway error.
  Future<bool?> fetchReachable({String? baseOverride}) async {
    final rawBase = (baseOverride?.trim().isNotEmpty == true) ? baseOverride!.trim() : AppConstants.cctvBaseUrl;
    // Full URL ke host CCTV (bisa beda dari API base) — bukan path relatif Dio.
    final res = await _dio.get('${rawBase.replaceAll(RegExp(r'/+$'), '')}${AppConstants.cctvHealthPath}');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      final v = data['incubator_reachable'];
      if (v is bool) return v;
      final status = (data['status'] ?? '') as String;
      if (status.toLowerCase() == 'ok') return true;
      return null;
    }
    return null;
  }

  /// URL aman untuk ditampilkan/di-log: query `url` (RTSP + password) dimasking.
  static String safeFeedLabel(Uri feed) {
    if (!feed.queryParameters.containsKey('url')) return feed.toString();
    final masked = feed.replace(queryParameters: {
      ...feed.queryParameters,
      'url': '***',
    });
    return masked.toString();
  }

  /// Ambil IP termasking dari health payload (jangan tampilkan password RTSP).
  static String? extractMaskedTarget(Map<String, dynamic> data) {
    for (final k in ['incubator_target', 'incubator_endpoint', 'kandang_endpoint']) {
      final v = data[k];
      if (v is String && v.isNotEmpty) {
        if (v.contains('****') || v.contains('***')) return v;
        return maskRtsp(v);
      }
    }
    return null;
  }

  /// Masking kredensial RTSP: rtsp://user:pass@host... -> rtsp://***@host...
  static String maskRtsp(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.userInfo.isNotEmpty) {
        return uri.replace(userInfo: '***').toString();
      }
      return url;
    } catch (_) {
      return url;
    }
  }

  /// Host/IP saja untuk footer (pola extractIp CctvPage.jsx).
  static String extractIp(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }
}
