class Chick {
  final String id;
  final String eggId;
  final String? indukJantanId;
  final String? indukBetinaId;
  final String tanggalMenetas;
  final double beratAwal;
  final String skorKesehatan;
  final String status;
  final String? fotoUrl;
  final String? catatan;

  Chick({
    required this.id,
    required this.eggId,
    this.indukJantanId,
    this.indukBetinaId,
    required this.tanggalMenetas,
    required this.beratAwal,
    required this.skorKesehatan,
    required this.status,
    this.fotoUrl,
    this.catatan,
  });

  factory Chick.fromJson(Map<String, dynamic> json) => Chick(
    id: json['id'] as String,
    eggId: json['egg_id'] as String,
    indukJantanId: json['induk_jantan_id'] as String?,
    indukBetinaId: json['induk_betina_id'] as String?,
    tanggalMenetas: json['tanggal_menetas'] as String,
    beratAwal: (json['berat_awal'] as num).toDouble(),
    skorKesehatan: json['skor_kesehatan'] as String,
    status: json['status'] as String,
    fotoUrl: (json['image_url'] ?? json['foto_url']) as String?,
    catatan: json['catatan'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'egg_id': eggId,
    'induk_jantan_id': indukJantanId,
    'induk_betina_id': indukBetinaId,
    'tanggal_menetas': tanggalMenetas,
    'berat_awal': beratAwal,
    'skor_kesehatan': skorKesehatan,
    'status': status,
    'foto_url': fotoUrl,
    'image_url': fotoUrl,
    if (catatan != null) 'catatan': catatan,
  };

  Chick copyWith({
    String? id,
    String? eggId,
    String? indukJantanId,
    String? indukBetinaId,
    String? tanggalMenetas,
    double? beratAwal,
    String? skorKesehatan,
    String? status,
    String? fotoUrl,
    String? catatan,
  }) => Chick(
    id: id ?? this.id,
    eggId: eggId ?? this.eggId,
    indukJantanId: indukJantanId ?? this.indukJantanId,
    indukBetinaId: indukBetinaId ?? this.indukBetinaId,
    tanggalMenetas: tanggalMenetas ?? this.tanggalMenetas,
    beratAwal: beratAwal ?? this.beratAwal,
    skorKesehatan: skorKesehatan ?? this.skorKesehatan,
    status: status ?? this.status,
    fotoUrl: fotoUrl ?? this.fotoUrl,
    catatan: catatan ?? this.catatan,
  );
}
