class Egg {
  final String id;
  final int slot;
  final String indukJantanId;
  final String indukBetinaId;
  final String tanggalMasuk;
  final String fertilitas;
  final String akhir;
  final String? catatan;

  Egg({
    required this.id,
    required this.slot,
    required this.indukJantanId,
    required this.indukBetinaId,
    required this.tanggalMasuk,
    required this.fertilitas,
    required this.akhir,
    this.catatan,
  });

  factory Egg.fromJson(Map<String, dynamic> json) => Egg(
    id: (json['id'] ?? '') as String,
    slot: (json['slot'] as num?)?.toInt() ?? 0,
    // Live GET /api/eggs belum kirim induk IDs (MOBILE.md §4.3) — toleran.
    indukJantanId: (json['induk_jantan_id'] as String?) ?? '',
    indukBetinaId: (json['induk_betina_id'] as String?) ?? '',
    tanggalMasuk: ((json['tanggalMasuk'] ?? json['tanggal_masuk'] ?? '') as String),
    fertilitas: (json['fertilitas'] as String?) ?? '',
    akhir: (json['akhir'] as String?) ?? '',
    catatan: json['catatan'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slot': slot,
    'induk_jantan_id': indukJantanId,
    'induk_betina_id': indukBetinaId,
    'tanggal_masuk': tanggalMasuk,
    'fertilitas': fertilitas,
    'akhir': akhir,
    if (catatan != null) 'catatan': catatan,
  };

  Egg copyWith({
    String? id,
    int? slot,
    String? indukJantanId,
    String? indukBetinaId,
    String? tanggalMasuk,
    String? fertilitas,
    String? akhir,
    String? catatan,
  }) => Egg(
    id: id ?? this.id,
    slot: slot ?? this.slot,
    indukJantanId: indukJantanId ?? this.indukJantanId,
    indukBetinaId: indukBetinaId ?? this.indukBetinaId,
    tanggalMasuk: tanggalMasuk ?? this.tanggalMasuk,
    fertilitas: fertilitas ?? this.fertilitas,
    akhir: akhir ?? this.akhir,
    catatan: catatan ?? this.catatan,
  );
}
