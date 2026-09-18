class IncubatorSettings {
  final int id;
  final double suhuMin;
  final double suhuMax;
  final double kelembapanMin;
  final double kelembapanMax;
  final int intervalRotasiMenit;
  final String? updatedBy;
  final DateTime? updatedAt;

  IncubatorSettings({
    required this.id,
    required this.suhuMin,
    required this.suhuMax,
    required this.kelembapanMin,
    required this.kelembapanMax,
    required this.intervalRotasiMenit,
    this.updatedBy,
    this.updatedAt,
  });

  factory IncubatorSettings.fromJson(Map<String, dynamic> json) => IncubatorSettings(
    id: (json['id'] as num).toInt(),
    suhuMin: (json['suhu_min'] as num).toDouble(),
    suhuMax: (json['suhu_max'] as num).toDouble(),
    kelembapanMin: (json['kelembapan_min'] as num).toDouble(),
    kelembapanMax: (json['kelembapan_max'] as num).toDouble(),
    intervalRotasiMenit: (json['interval_rotasi_menit'] as num).toInt(),
    updatedBy: json['updated_by'] as String?,
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'suhu_min': suhuMin,
    'suhu_max': suhuMax,
    'kelembapan_min': kelembapanMin,
    'kelembapan_max': kelembapanMax,
    'interval_rotasi_menit': intervalRotasiMenit,
  };

  IncubatorSettings copyWith({
    int? id,
    double? suhuMin,
    double? suhuMax,
    double? kelembapanMin,
    double? kelembapanMax,
    int? intervalRotasiMenit,
    String? updatedBy,
    DateTime? updatedAt,
  }) => IncubatorSettings(
    id: id ?? this.id,
    suhuMin: suhuMin ?? this.suhuMin,
    suhuMax: suhuMax ?? this.suhuMax,
    kelembapanMin: kelembapanMin ?? this.kelembapanMin,
    kelembapanMax: kelembapanMax ?? this.kelembapanMax,
    intervalRotasiMenit: intervalRotasiMenit ?? this.intervalRotasiMenit,
    updatedBy: updatedBy ?? this.updatedBy,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
