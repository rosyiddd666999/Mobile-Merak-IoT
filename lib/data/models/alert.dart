class Alert {
  final int id;
  final String tipe;
  final String pesan;
  final String level;
  final bool isRead;
  final DateTime? createdAt;

  Alert({
    required this.id,
    required this.tipe,
    required this.pesan,
    required this.level,
    required this.isRead,
    this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id: (json['id'] as num).toInt(),
    tipe: json['tipe'] as String,
    pesan: json['pesan'] as String,
    level: json['level'] as String,
    isRead: json['is_read'] as bool? ?? false,
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipe': tipe,
    'pesan': pesan,
    'level': level,
    'is_read': isRead,
  };

  Alert copyWith({
    int? id,
    String? tipe,
    String? pesan,
    String? level,
    bool? isRead,
    DateTime? createdAt,
  }) => Alert(
    id: id ?? this.id,
    tipe: tipe ?? this.tipe,
    pesan: pesan ?? this.pesan,
    level: level ?? this.level,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt ?? this.createdAt,
  );
}
