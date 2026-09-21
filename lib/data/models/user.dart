class User {
  final String id;
  final String email;
  final String nama;
  final String role;
  final String? fotoUrl;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.nama,
    required this.role,
    this.fotoUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawRole = ((json['role'] ?? '') as String).toLowerCase();
    // Mapping web ROLES admin/operator/viewer -> backend pemilik/staff.
    final role = rawRole == 'admin'
        ? 'pemilik'
        : rawRole == 'operator'
            ? 'staff'
            : rawRole;
    return User(
      id: (json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      nama: ((json['nama'] ?? json['name'] ?? '') as String),
      role: role,
      fotoUrl: (json['avatar_url'] ?? json['image_url'] ?? json['foto_url']) as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nama': nama,
    'role': role,
    // Kanonis backend: avatar_url (BACKEND.md §12); plus alias image_url.
    'avatar_url': fotoUrl,
    'image_url': fotoUrl,
    'created_at': createdAt?.toIso8601String(),
  };

  User copyWith({
    String? id,
    String? email,
    String? nama,
    String? role,
    String? fotoUrl,
    DateTime? createdAt,
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    nama: nama ?? this.nama,
    role: role ?? this.role,
    fotoUrl: fotoUrl ?? this.fotoUrl,
    createdAt: createdAt ?? this.createdAt,
  );
}
