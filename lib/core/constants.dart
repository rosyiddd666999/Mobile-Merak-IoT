import 'utils/env_utils.dart';

import 'config.dart';

class AppConstants {
  static String get baseUrl {
    final env = envOr('BASE_URL', fallback: '');
    if (env.isNotEmpty) return env;
    return AppConfig.baseUrl;
  }

  /// Kosong bila tidak dikonfigurasi — caller wajib menolak request auth
  /// daripada memakai fallback lemah bawaan.
  static String get apiKeyAndroid {
    final env = envOr('API_KEY_ANDROID', fallback: '');
    if (env.isNotEmpty) return env;
    return AppConfig.apiKeyAndroid;
  }

  /// True bila konfigurasi penting belum diisi (tampilkan layar perbaiki key).
  static bool get isConfigured =>
      baseUrl.isNotEmpty && apiKeyAndroid.isNotEmpty;

  // Base origin untuk CCTV (Nginx HTTPS). Isi CCTV_BASE_URL bila beda host.
  static String get cctvBaseUrl {
    final custom = envOr('CCTV_BASE_URL', fallback: '');
    if (custom.isNotEmpty) return custom.replaceAll(RegExp(r'/+$'), '');
    final origin = Uri.tryParse(baseUrl)?.origin;
    return (origin == null || origin.isEmpty) ? baseUrl : origin;
  }

  // Path feed MJPEG dari .env web (RTSP_MJPEG_URL), fallback dart-define.
  static String get cctvInkubatorPath {
    final env = envOr('RTSP_MJPEG_URL', fallback: '');
    if (env.isNotEmpty) return env.startsWith('/') ? env : '/$env';
    return AppConfig.cctvIncubatorPath;
  }

  static String get cctvKandangPath => AppConfig.cctvKandangPath;
  static String get cctvHealthPath => AppConfig.cctvHealthPath;

  static String get cctvInkubatorUrl => '$cctvBaseUrl$cctvInkubatorPath';
  static String get cctvKandangUrl => '$cctvBaseUrl$cctvKandangPath';
  static String get cctvHealthUrl => '$cctvBaseUrl$cctvHealthPath';

  // MQTT: MQTT_URL sumber tunggal (wajib). MQTT_HOST/PORT opsional legacy —
  // bila kosong, host diturunkan dari MQTT_URL (HiveMQ: host sama untuk
  // native 8883 maupun websocket 8884). Disanitasi anti full-URL nyasar.
  static String get mqttHost {
    final raw = envOr('MQTT_HOST', fallback: '');
    final sanitized = _bareHost(raw);
    if (sanitized.isNotEmpty) return sanitized;
    final fromUrl = _bareHost(mqttUrl);
    if (fromUrl.isNotEmpty) return fromUrl;
    return _bareHost(AppConfig.mqttHost);
  }

  /// Target RTSP inkubator untuk query `?url=` (gateway mewajibkan).
  /// Kosong = feed tanpa `?url=` (kandang / belum dikonfigurasi).
  static String get cctvRtspUrl {
    final env = envOr('CCTV_RTSP_URL', fallback: '');
    if (env.isNotEmpty) return env;
    return AppConfig.cctvRtspUrl;
  }

  /// Ambil bare hostname dari input yang bisa berupa host polos
  /// atau URL utuh (`wss://host:8884/mqtt`).
  static String _bareHost(String input) {
    final v = input.trim();
    if (v.isEmpty) return '';
    if (!v.contains('://')) return v.split('/').first.split(':').first.trim();
    final host = Uri.tryParse(v)?.host.trim() ?? '';
    if (host.isNotEmpty) return host;
    return v.split('/').first.split(':').first.trim();
  }

  static int get mqttPort {
    final env = envOr('MQTT_PORT', fallback: '');
    final n = int.tryParse(env);
    if (n != null) return n;
    return AppConfig.mqttPort;
  }

  /// URL koneksi native: mqtts://host:8883 (bukan wss 8884 khusus web).
  static String get mqttNativeUrl => 'mqtts://$mqttHost:$mqttPort';
  static String get mqttUrl {
    final env = envOr('MQTT_URL', fallback: '');
    return env.isNotEmpty ? env : AppConfig.mqttUrl;
  }

  static String? get mqttUsername {
    final env = envOr('MQTT_USERNAME', fallback: '');
    if (env.isNotEmpty) return env;
    return AppConfig.mqttUsername.isEmpty ? null : AppConfig.mqttUsername;
  }

  static String? get mqttPassword {
    final env = envOr('MQTT_PASSWORD', fallback: '');
    if (env.isNotEmpty) return env;
    return AppConfig.mqttPassword.isEmpty ? null : AppConfig.mqttPassword;
  }

}
