import 'package:dio/dio.dart';
import '../../core/constants.dart';

/// Helper URL feed + fetch /cctv_health (MOBILE.md §6.19/§7.5, cctv.md).
/// Base URL dibaca runtime (.env -> dart-define) agar `flutter run` biasa benar.
class CctvService {
  CctvService(this._dio);
  final Dio _dio;

  /// Host custom hanya boleh HTTPS dan tanpa userinfo/path aneh.
  /// Mengembalikan null bila tidak valid — caller wajib menolak dan
  /// TIDAK mengirim header auth ke host tersebut.
  static String? sanitizeCustomBase(String? input) {
    final v = input?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
    if (v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    if (uri.userInfo.isNotEmpty) return null;
    if (uri.hasQuery || uri.hasFragment) return null;
    // Tolak IP privat/loopback yang diketik manual agar tidak jadi SSRF lokal.
    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host.startsWith('127.') ||
        host.startsWith('10.') ||
        host.startsWith('192.168.') ||
        host.startsWith('172.') ||
        host == '::1' ||
        host == '[::1]') {
      return null;
    }
    return v;
  }

  /// True bila feed mengarah ke host di luar base resmi — UI wajib tampilkan
  /// peringatan sebelum mengirim X-API-Key/Bearer ke sana.
  static bool isExternalHost(Uri feed, String trustedBase) {
    final trusted = Uri.tryParse(trustedBase)?.host.toLowerCase() ?? '';
    if (trusted.isEmpty) return true;
    return feed.host.toLowerCase() != trusted;
  }

  Uri incubatorFeed({int? cacheBuster, String? baseOverride}) =>
      _feed(AppConstants.cctvInkubatorPath, cacheBuster, baseOverride,
          rtspTarget: AppConstants.cctvRtspUrl);
  // Kandang belum ada kamera — feed tanpa `?url=` sampai target tersedia.
  Uri kandangFeed({int? cacheBuster, String? baseOverride}) =>
      _feed(AppConstants.cctvKandangPath, cacheBuster, baseOverride);

  Uri _feed(String path, int? cacheBuster, String? baseOverride, {String? rtspTarget}) {
    final rawBase = (baseOverride?.trim().isNotEmpty == true) ? baseOverride!.trim() : AppConstants.cctvBaseUrl;
    final base = rawBase.replaceAll(RegExp(r'/+$'), '');
    var uri = Uri.parse('$base$path');
    // Satu-key fleksibel (cukup salah satu terisi):
    // 1. Base SUDAH bawa ?url= (full link ala website ditempel ke
    //    CCTV_BASE_URL) -> pakai apa adanya.
    // 2. CCTV_RTSP_URL terisi -> tempel sebagai ?url=, HANYA ke host resmi
    //    (== CCTV_BASE_URL), bukan custom override (password kamera tidak
    //    boleh exfil ke host arbitrari).
    // 3. Keduanya kosong -> polos tanpa ?url= (andalkan default gateway).
    final trustedHost = Uri.tryParse(AppConstants.cctvBaseUrl)?.host.toLowerCase() ?? '';
    final target = rtspTarget?.trim() ?? '';
    final qp = <String, String>{...uri.queryParameters};
    if (!qp.containsKey('url') &&
        target.isNotEmpty &&
        trustedHost.isNotEmpty &&
        uri.host.toLowerCase() == trustedHost) {
      qp['url'] = target;
    }
    if (cacheBuster != null) {
      qp['t'] = '$cacheBuster';
    }
    if (qp.isNotEmpty) uri = uri.replace(queryParameters: qp);
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
