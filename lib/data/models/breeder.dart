class Breeder {
  final String id;
  final String? nama;
  final String jenisKelamin;
  final DateTime? tanggalLahir;
  final String generasi;
  final String varianWarna;
  final String asal;
  final String status;
  final String? fotoUrl;
  final String? parentJantanId;
  final String? parentBetinaId;
  final DateTime? createdAt;
  final int totalTelur;
  final double persentaseFertil;
  final int jumlahAnakan;

  Breeder({
    required this.id,
    this.nama,
    required this.jenisKelamin,
    this.tanggalLahir,
    required this.generasi,
    required this.varianWarna,
    required this.asal,
    required this.status,
    this.fotoUrl,
    this.parentJantanId,
    this.parentBetinaId,
    this.createdAt,
    this.totalTelur = 0,
    this.persentaseFertil = 0,
    this.jumlahAnakan = 0,
  });

  factory Breeder.fromJson(Map<String, dynamic> json) => Breeder(
    id: json['id'] as String,
    nama: json['nama'] as String?,
    jenisKelamin: json['jenis_kelamin'] as String,
    tanggalLahir: json['tanggal_lahir'] != null ? DateTime.tryParse(json['tanggal_lahir'] as String) : null,
    generasi: json['generasi'] as String,
    varianWarna: json['varian_warna'] as String,
    asal: json['asal'] as String,
    status: json['status'] as String,
    fotoUrl: (json['image_url'] ?? json['foto_url']) as String?,
    parentJantanId: json['parent_jantan_id'] as String?,
    parentBetinaId: json['parent_betina_id'] as String?,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    totalTelur: (json['total_telur'] as num?)?.toInt() ?? 0,
    persentaseFertil: (json['persentase_fertil'] as num?)?.toDouble() ?? 0,
    jumlahAnakan: (json['jumlah_anakan'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (nama != null) 'nama': nama,
    'jenis_kelamin': jenisKelamin,
    'tanggal_lahir': tanggalLahir?.toIso8601String(),
    'generasi': generasi,
    'varian_warna': varianWarna,
    'asal': asal,
    'status': status,
    'image_url': fotoUrl,
    'parent_jantan_id': parentJantanId,
    'parent_betina_id': parentBetinaId,
  };

  Breeder copyWith({
    String? id,
    String? nama,
    String? jenisKelamin,
    DateTime? tanggalLahir,
    String? generasi,
    String? varianWarna,
    String? asal,
    String? status,
    String? fotoUrl,
    String? parentJantanId,
    String? parentBetinaId,
    DateTime? createdAt,
    int? totalTelur,
    double? persentaseFertil,
    int? jumlahAnakan,
  }) => Breeder(
    id: id ?? this.id,
    nama: nama ?? this.nama,
    jenisKelamin: jenisKelamin ?? this.jenisKelamin,
    tanggalLahir: tanggalLahir ?? this.tanggalLahir,
    generasi: generasi ?? this.generasi,
    varianWarna: varianWarna ?? this.varianWarna,
    asal: asal ?? this.asal,
    status: status ?? this.status,
    fotoUrl: fotoUrl ?? this.fotoUrl,
    parentJantanId: parentJantanId ?? this.parentJantanId,
    parentBetinaId: parentBetinaId ?? this.parentBetinaId,
    createdAt: createdAt ?? this.createdAt,
    totalTelur: totalTelur ?? this.totalTelur,
    persentaseFertil: persentaseFertil ?? this.persentaseFertil,
    jumlahAnakan: jumlahAnakan ?? this.jumlahAnakan,
  );
}
