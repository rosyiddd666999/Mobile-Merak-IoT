class RotationLog {
  final int id;
  final String timestamp;
  final String status;
  final String? catatan;

  RotationLog({
    required this.id,
    required this.timestamp,
    required this.status,
    this.catatan,
  });

  factory RotationLog.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    int id;
    if (rawId is num) {
      id = rawId.toInt();
    } else {
      id = int.tryParse(rawId?.toString() ?? '') ?? 0;
    }
    return RotationLog(
      id: id,
      // Kontrak backend: timestamp string bebas — jangan cast keras.
      timestamp: json['timestamp']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      catatan: json['catatan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'status': status,
    if (catatan != null) 'catatan': catatan,
  };
}
