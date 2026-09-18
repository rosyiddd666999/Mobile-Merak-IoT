class Sale {
  final String id;
  final String tanggal;
  final String item;
  final String referensiId;
  final String pembeli;
  final int qty;
  final double hargaSatuan;
  final String status;
  final String? catatan;

  Sale({
    required this.id,
    required this.tanggal,
    required this.item,
    required this.referensiId,
    required this.pembeli,
    required this.qty,
    required this.hargaSatuan,
    required this.status,
    this.catatan,
  });

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'] as String,
    tanggal: json['tanggal'] as String,
    item: json['item'] as String,
    referensiId: (json['referensiId'] ?? json['referensi_id']) as String,
    pembeli: json['pembeli'] as String,
    qty: (json['qty'] as num).toInt(),
    hargaSatuan: ((json['hargaSatuan'] ?? json['harga_satuan']) as num).toDouble(),
    status: json['status'] as String,
    catatan: json['catatan'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tanggal': tanggal,
    'item': item,
    'referensiId': referensiId,
    'pembeli': pembeli,
    'qty': qty,
    'hargaSatuan': hargaSatuan,
    'status': status,
    if (catatan != null) 'catatan': catatan,
  };

  Sale copyWith({
    String? id,
    String? tanggal,
    String? item,
    String? referensiId,
    String? pembeli,
    int? qty,
    double? hargaSatuan,
    String? status,
    String? catatan,
  }) => Sale(
    id: id ?? this.id,
    tanggal: tanggal ?? this.tanggal,
    item: item ?? this.item,
    referensiId: referensiId ?? this.referensiId,
    pembeli: pembeli ?? this.pembeli,
    qty: qty ?? this.qty,
    hargaSatuan: hargaSatuan ?? this.hargaSatuan,
    status: status ?? this.status,
    catatan: catatan ?? this.catatan,
  );
}
