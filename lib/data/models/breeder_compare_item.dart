class BreederCompareItem {
  final String id;
  final String? nama;
  final String jenisKelamin;
  final String generasi;
  final String varianWarna;
  final String status;
  final int totalTelur;
  final double persentaseFertil;
  final int jumlahAnakan;

  BreederCompareItem({
    required this.id,
    this.nama,
    required this.jenisKelamin,
    required this.generasi,
    required this.varianWarna,
    required this.status,
    required this.totalTelur,
    required this.persentaseFertil,
    required this.jumlahAnakan,
  });

  factory BreederCompareItem.fromJson(Map<String, dynamic> json) => BreederCompareItem(
    id: json['id'] as String,
    nama: json['nama'] as String?,
    jenisKelamin: json['jenis_kelamin'] as String,
    generasi: json['generasi'] as String,
    varianWarna: json['varian_warna'] as String,
    status: json['status'] as String,
    totalTelur: (json['total_telur'] as num?)?.toInt() ?? 0,
    persentaseFertil: (json['persentase_fertil'] as num?)?.toDouble() ?? 0,
    jumlahAnakan: (json['jumlah_anakan'] as num?)?.toInt() ?? 0,
  );
}
