class FinanceEntry {
  final String id;
  final String tanggal;
  final String tipe;
  final String kategori;
  final double jumlah;
  final String? catatan;
  final String createdBy;

  FinanceEntry({
    required this.id,
    required this.tanggal,
    required this.tipe,
    required this.kategori,
    required this.jumlah,
    this.catatan,
    required this.createdBy,
  });

  factory FinanceEntry.fromJson(Map<String, dynamic> json) => FinanceEntry(
    id: json['id'] as String,
    tanggal: json['tanggal'] as String,
    tipe: json['tipe'] as String,
    kategori: json['kategori'] as String,
    jumlah: (json['jumlah'] as num).toDouble(),
    catatan: json['catatan'] as String?,
    createdBy: json['created_by'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tanggal': tanggal,
    'tipe': tipe,
    'kategori': kategori,
    'jumlah': jumlah,
    if (catatan != null) 'catatan': catatan,
    'created_by': createdBy,
  };

  FinanceEntry copyWith({
    String? id,
    String? tanggal,
    String? tipe,
    String? kategori,
    double? jumlah,
    String? catatan,
    String? createdBy,
  }) => FinanceEntry(
    id: id ?? this.id,
    tanggal: tanggal ?? this.tanggal,
    tipe: tipe ?? this.tipe,
    kategori: kategori ?? this.kategori,
    jumlah: jumlah ?? this.jumlah,
    catatan: catatan ?? this.catatan,
    createdBy: createdBy ?? this.createdBy,
  );
}
