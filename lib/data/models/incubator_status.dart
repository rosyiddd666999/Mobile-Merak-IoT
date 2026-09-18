class IncubatorStatus {
  final int id;
  final double suhuSekarang;
  final double kelembapanSekarang;
  final String lampuStatus;
  final DateTime? terakhirRotasi;
  final DateTime? updatedAt;

  IncubatorStatus({
    required this.id,
    required this.suhuSekarang,
    required this.kelembapanSekarang,
    required this.lampuStatus,
    this.terakhirRotasi,
    this.updatedAt,
  });

  factory IncubatorStatus.fromJson(Map<String, dynamic> json) {
    final rawRotasi = json['terakhir_rotasi'] ?? json['terakhirRotasi'];
    return IncubatorStatus(
      id: (json['id'] as num?)?.toInt() ?? 0,
      suhuSekarang: ((json['suhu_sekarang'] ?? json['temperature'] ?? json['suhu'] ?? 0) as num).toDouble(),
      kelembapanSekarang:
          ((json['kelembapan_sekarang'] ?? json['humidity'] ?? json['kelembapan'] ?? 0) as num).toDouble(),
      lampuStatus: ((json['lampu_status'] ?? json['status_lamp'] ?? 'OFF') as String),
      terakhirRotasi: rawRotasi != null ? DateTime.tryParse(rawRotasi.toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suhu_sekarang': suhuSekarang,
      'kelembapan_sekarang': kelembapanSekarang,
      'lampu_status': lampuStatus,
      if (terakhirRotasi != null) 'terakhir_rotasi': terakhirRotasi!.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  IncubatorStatus copyWith({
    int? id,
    double? suhuSekarang,
    double? kelembapanSekarang,
    String? lampuStatus,
    DateTime? terakhirRotasi,
    DateTime? updatedAt,
  }) =>
      IncubatorStatus(
        id: id ?? this.id,
        suhuSekarang: suhuSekarang ?? this.suhuSekarang,
        kelembapanSekarang: kelembapanSekarang ?? this.kelembapanSekarang,
        lampuStatus: lampuStatus ?? this.lampuStatus,
        terakhirRotasi: terakhirRotasi ?? this.terakhirRotasi,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
