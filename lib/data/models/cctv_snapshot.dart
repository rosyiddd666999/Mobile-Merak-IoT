/// Snapshot CCTV dari `GET /api/cctv-snapshots` (FastAPI).
/// URL gambar absolut di key `url` (fallback `image_url` bila backend
/// menambah alias). `object_key` hanya untuk hapus/migrasi.
class CctvSnapshot {
  final int id;
  final DateTime? capturedAt;
  final String? objectKey;
  final String url;

  const CctvSnapshot({
    required this.id,
    this.capturedAt,
    this.objectKey,
    required this.url,
  });

  factory CctvSnapshot.fromJson(Map<String, dynamic> json) => CctvSnapshot(
        id: (json['id'] as num?)?.toInt() ?? 0,
        capturedAt: json['captured_at'] != null
            ? DateTime.tryParse(json['captured_at'] as String)
            : null,
        objectKey: json['object_key'] as String?,
        url: ((json['url'] ?? json['image_url'] ?? '') as String),
      );

  CctvSnapshot copyWith({
    int? id,
    DateTime? capturedAt,
    String? objectKey,
    String? url,
  }) =>
      CctvSnapshot(
        id: id ?? this.id,
        capturedAt: capturedAt ?? this.capturedAt,
        objectKey: objectKey ?? this.objectKey,
        url: url ?? this.url,
      );
}
