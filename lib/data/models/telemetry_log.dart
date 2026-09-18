class TelemetryLog {
  final int id;
  final String timestamp;
  final double temperature;
  final double humidity;

  TelemetryLog({
    required this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
  });

  factory TelemetryLog.fromJson(Map<String, dynamic> json) => TelemetryLog(
    id: (json['id'] as num?)?.toInt() ?? 0,
    timestamp: ((json['timestamp'] ??
                json['created_at'] ??
                json['updated_at'] ??
                json['waktu'] ??
                '') as String),
    temperature: ((json['temperature'] ??
                    json['suhu'] ??
                    json['suhu_sekarang'] ??
                    0) as num)
        .toDouble(),
    humidity: ((json['humidity'] ?? json['kelembapan'] ?? json['kelembapan_sekarang'] ?? 0) as num)
        .toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'temperature': temperature,
    'humidity': humidity,
  };
}
