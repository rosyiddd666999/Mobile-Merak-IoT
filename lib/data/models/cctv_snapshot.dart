/// Snapshot CCTV dari `GET /api/cctv-snapshots` (FastAPI).
/// URL gambar absolut di key `url` (fallback `image_url` bila backend
/// menambah alias). `object_key` hanya untuk hapus/migrasi.
class CctvSnapshot {
  final int id;
  final DateTime? capturedAt;
  final String? objectKey;
  final String url;
  final String? source;

  const CctvSnapshot({
    required this.id,
    this.capturedAt,
    this.objectKey,
    required this.url,
    this.source,
  });

  factory CctvSnapshot.fromJson(Map<String, dynamic> json) => CctvSnapshot(
        id: (json['id'] as num?)?.toInt() ?? 0,
        capturedAt: json['captured_at'] != null
            ? DateTime.tryParse(json['captured_at'] as String)
            : null,
        objectKey: json['object_key'] as String?,
        url: ((json['url'] ?? json['image_url'] ?? '') as String),
        source: json['source'] as String?,
      );

  CctvSnapshot copyWith({
    int? id,
    DateTime? capturedAt,
    String? objectKey,
    String? url,
    String? source,
  }) =>
      CctvSnapshot(
        id: id ?? this.id,
        capturedAt: capturedAt ?? this.capturedAt,
        objectKey: objectKey ?? this.objectKey,
        url: url ?? this.url,
        source: source ?? this.source,
      );
}
