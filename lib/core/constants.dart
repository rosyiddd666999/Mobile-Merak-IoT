import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config.dart';

class AppConstants {
  static String get baseUrl {
    final env = dotenv.get('BASE_URL', fallback: '');
    if (env.isNotEmpty) return env;
    return AppConfig.baseUrl;
  }
  static String get apiKeyAndroid => dotenv.get('API_KEY_ANDROID', fallback: 'dev-api-key-android');

  // Base origin untuk CCTV (Nginx HTTPS). Isi CCTV_BASE_URL bila beda host.
  static String get cctvBaseUrl {
    final custom = dotenv.get('CCTV_BASE_URL', fallback: '');
    if (custom.isNotEmpty) return custom.replaceAll(RegExp(r'/+$'), '');
    final origin = Uri.tryParse(baseUrl)?.origin;
    return (origin == null || origin.isEmpty) ? baseUrl : origin;
  }

  // Path feed MJPEG dari .env web (RTSP_MJPEG_URL), fallback dart-define.
  static String get cctvInkubatorPath {
    final env = dotenv.get('RTSP_MJPEG_URL', fallback: '');
    if (env.isNotEmpty) return env.startsWith('/') ? env : '/$env';
    return AppConfig.cctvIncubatorPath;
  }

  static String get cctvKandangPath => AppConfig.cctvKandangPath;
  static String get cctvHealthPath => AppConfig.cctvHealthPath;

  static String get cctvInkubatorUrl => '$cctvBaseUrl$cctvInkubatorPath';
  static String get cctvKandangUrl => '$cctvBaseUrl$cctvKandangPath';
  static String get cctvHealthUrl => '$cctvBaseUrl$cctvHealthPath';

  // MQTT native (mqtts host:8883, MOBILE.md §12) — .env dulu, fallback dart-define.
  static String get mqttHost {
    final env = dotenv.get('MQTT_HOST', fallback: '');
    return env.isNotEmpty ? env : AppConfig.mqttHost;
  }

  static int get mqttPort {
    final env = dotenv.get('MQTT_PORT', fallback: '');
    final n = int.tryParse(env);
    if (n != null) return n;
    return AppConfig.mqttPort;
  }

  /// URL koneksi native: mqtts://host:8883 (bukan wss 8884 khusus web).
  static String get mqttNativeUrl => 'mqtts://$mqttHost:$mqttPort';
  static String get mqttUrl {
    final env = dotenv.get('MQTT_URL', fallback: '');
    return env.isNotEmpty ? env : AppConfig.mqttUrl;
  }

  static String? get mqttUsername {
    final env = dotenv.get('MQTT_USERNAME', fallback: '');
    if (env.isNotEmpty) return env;
    return AppConfig.mqttUsername.isEmpty ? null : AppConfig.mqttUsername;
  }

  static String? get mqttPassword {
    final env = dotenv.get('MQTT_PASSWORD', fallback: '');
    if (env.isNotEmpty) return env;
    return AppConfig.mqttPassword.isEmpty ? null : AppConfig.mqttPassword;
  }

}
