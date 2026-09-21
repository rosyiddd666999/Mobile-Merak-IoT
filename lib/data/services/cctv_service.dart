import 'package:dio/dio.dart';
import '../../core/constants.dart';

/// Helper URL feed + fetch /cctv_health (MOBILE.md §6.19/§7.5, cctv.md).
/// Base URL dibaca runtime (.env -> dart-define) agar `flutter run` biasa benar.
class CctvService {
  CctvService(this._dio);
  final Dio _dio;

  /// Host custom hanya boleh origin HTTPS murni (tanpa path/query aneh).
  /// Mengembalikan null bila tidak valid — caller wajib menolak dan
  /// TIDAK mengirim header auth ke host tersebut.
  static String? sanitizeCustomBase(String? input) {
    final v = input?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
    if (v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    if (uri.userInfo.isNotEmpty) return null;
    // Tolak path (mis. tempelan RTSP `/rtsp://...` atau `/video_feed` nyasar
    // ke kolom host) dan query/fragment — host murni saja.
    if (uri.path.isNotEmpty && uri.path != '/') return null;
    if (uri.hasQuery || uri.hasFragment) return null;
    if (v.toLowerCase().contains('rtsp:')) return null;
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

  /// Normalisasi base toleran: user boleh menempel origin polos
  /// (`https://host`), full link website (`https://host/video_feed?url=...`),
  /// bahkan RTSP nyasar sebagai path. Hasil selalu `origin` (+ `?url=` bila
  /// ada) agar tak terbentuk URL sampah `host/rtsp://.../cctv_health`.
  /// Gagal parse / non-https -> fallback CCTV_BASE_URL resmi.
  static String normalizeBase(String? rawBase) {
    final fallback = AppConstants.cctvBaseUrl;
    final v = rawBase?.trim() ?? '';
    if (v.isEmpty) return fallback;
    if (v.toLowerCase().startsWith('rtsp:')) return fallback;
    final uri = Uri.tryParse(v);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return fallback;
    if (uri.scheme.toLowerCase() != 'https') return fallback;
    final clean = Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      queryParameters: uri.queryParameters.containsKey('url')
          ? {'url': uri.queryParameters['url']!}
          : null,
    );
    final s = clean.toString().replaceAll(RegExp(r'/+$'), '');
    return s.isEmpty ? fallback : s;
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
    final base = normalizeBase(
        (baseOverride?.trim().isNotEmpty == true) ? baseOverride!.trim() : AppConstants.cctvBaseUrl);
    // normalizeBase bisa kembalikan `origin?url=...` — rakit ulang agar path
    // selalu di belakang host, bukan di belakang query.
    final baseUri = Uri.parse(base);
    var uri = Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: path,
      queryParameters: baseUri.queryParameters.containsKey('url')
          ? {'url': baseUri.queryParameters['url']!}
          : null,
    );
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
    final base = normalizeBase(
        (baseOverride?.trim().isNotEmpty == true) ? baseOverride!.trim() : AppConstants.cctvBaseUrl);
    return Uri.parse('$base${AppConstants.cctvHealthPath}');
  }

  String get healthPath => AppConstants.cctvHealthPath;

  /// Health polling (pola CctvPage.jsx): baca `incubator_reachable: bool`.
  /// Return null bila field tidak ada; throw bila HTTP/gateway error.
  Future<bool?> fetchReachable({String? baseOverride}) async {
    final base = normalizeBase(
        (baseOverride?.trim().isNotEmpty == true) ? baseOverride!.trim() : AppConstants.cctvBaseUrl);
    // Full URL ke host CCTV (bisa beda dari API base) — bukan path relatif Dio.
    final res = await _dio.get('$base${AppConstants.cctvHealthPath}');
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
