/// Konfigurasi build-time via `--dart-define`.
/// Sengaja TANPA defaultValue berisi secret agar kredensial tidak tertanam
/// di source/binary dan tidak bocor via git/APK strings.
/// Isi via: flutter run --dart-define=BASE_URL=... --dart-define=API_KEY_ANDROID=...
class AppConfig {
  static const baseUrl = String.fromEnvironment('BASE_URL', defaultValue: '');
  static const apiKeyAndroid = String.fromEnvironment('API_KEY_ANDROID', defaultValue: '');
  // Fallback WebSocket (web); Flutter native memakai host/port di bawah.
  static const mqttUrl = String.fromEnvironment('MQTT_URL', defaultValue: '');
  static const mqttHost = String.fromEnvironment('MQTT_HOST', defaultValue: '');
  static const mqttPort = int.fromEnvironment('MQTT_PORT', defaultValue: 8883);
  static const mqttUsername = String.fromEnvironment('MQTT_USERNAME', defaultValue: '');
  static const mqttPassword = String.fromEnvironment('MQTT_PASSWORD', defaultValue: '');
  static const cctvIncubatorPath =
      String.fromEnvironment('CCTV_INCUBATOR_PATH', defaultValue: '/video_feed');
  static const cctvKandangPath =
      String.fromEnvironment('CCTV_KANDANG_PATH', defaultValue: '/kandang_feed');
  static const cctvHealthPath =
      String.fromEnvironment('CCTV_HEALTH_PATH', defaultValue: '/cctv_health');
}
