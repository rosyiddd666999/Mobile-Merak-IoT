class AppConfig {
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api-merak.abdulrosyid.my.id',
  );
  static const apiKeyAndroid = String.fromEnvironment('API_KEY_ANDROID', defaultValue: '');
  // Fallback WebSocket (web); Flutter native memakai host/port di bawah.
  static const mqttUrl = String.fromEnvironment(
    'MQTT_URL',
    defaultValue: 'wss://9170ac9caae04bc598c6d6111adfa4a1.s1.eu.hivemq.cloud:8884/mqtt',
  );
  static const mqttHost = String.fromEnvironment('MQTT_HOST', defaultValue: '');
  static const mqttPort = int.fromEnvironment('MQTT_PORT', defaultValue: 8883);
  // Samakan firmware ESP32 (esp32/incubator_controller.ino): endoqmerak (q).
  static const mqttUsername = String.fromEnvironment('MQTT_USERNAME', defaultValue: 'endoqmerak');
  static const mqttPassword = String.fromEnvironment('MQTT_PASSWORD', defaultValue: 'Admin123');
  static const cctvIncubatorPath =
      String.fromEnvironment('CCTV_INCUBATOR_PATH', defaultValue: '/video_feed');
  static const cctvKandangPath =
      String.fromEnvironment('CCTV_KANDANG_PATH', defaultValue: '/kandang_feed');
  static const cctvHealthPath =
      String.fromEnvironment('CCTV_HEALTH_PATH', defaultValue: '/cctv_health');
}
