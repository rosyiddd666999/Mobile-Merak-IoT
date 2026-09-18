class MqttConfig {
  final String mqttUrl;
  final String? mqttUsername;
  final String? mqttPassword;
  final String status;

  MqttConfig({
    required this.mqttUrl,
    this.mqttUsername,
    this.mqttPassword,
    required this.status,
  });

  factory MqttConfig.fromJson(Map<String, dynamic> json) => MqttConfig(
        mqttUrl: (json['mqtt_url'] ?? '') as String,
        mqttUsername: json['mqtt_username'] as String?,
        mqttPassword: json['mqtt_password'] as String?,
        status: (json['status'] ?? 'offline') as String,
      );

  bool get isConfigured => mqttUrl.isNotEmpty;

  /// URL tanpa password untuk log/UI.
  String get safeUrl {
    try {
      final uri = Uri.parse(mqttUrl);
      if (uri.hasAuthority && (uri.userInfo.isNotEmpty || mqttUsername != null)) {
        return uri.replace(userInfo: '').toString();
      }
      return mqttUrl;
    } catch (_) {
      return mqttUrl;
    }
  }
}
