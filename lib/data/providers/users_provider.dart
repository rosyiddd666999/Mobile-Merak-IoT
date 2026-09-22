import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user.dart';
import 'api_client_provider.dart';

part 'users_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<User>> usersList(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/users');
    return (response.data as List).map((e) => User.fromJson(e)).toList();
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
class UserCreate extends _$UserCreate {
  @override
  Future<User?> build() async => null;

  Future<User?> create({
    required String id,
    required String nama,
    required String email,
    required String password,
    required String role,
    String? fotoUrl,
  }) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.post('/auth/register', data: {
        'id': id,
        'nama': nama,
        'email': email,
        'password': password,
        'role': role,
        if (fotoUrl?.isNotEmpty ?? false) ...{
          'avatar_url': fotoUrl,
          'image_url': fotoUrl,
        },
      });
      final created = User.fromJson(response.data);
      state = AsyncData(created);
      return created;
    } on DioException catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

@Riverpod(keepAlive: true)
class UserUpdate extends _$UserUpdate {
  @override
  Future<User?> build() async => null;

  /// Ubah profil (nama/foto). `PUT /api/users/{id}` pemilik-only —
  /// staff ditolak 403 (pesan spesifik via AppFailure di UI).
  Future<User?> updateUser({
    required String id,
    String? nama,
    String? fotoUrl,
  }) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    final data = <String, dynamic>{
      if (nama != null) 'nama': nama,
    };
    // String kosong = bersihkan foto; null = tak diubah.
    final photo = fotoUrl;
    // ignore: use_null_aware_elements
    if (photo != null) {
      data['avatar_url'] = photo;
      data['image_url'] = photo;
    }
    try {
      final response = await dio.put('/api/users/$id', data: data);
      final updated = User.fromJson(response.data as Map<String, dynamic>);
      state = AsyncData(updated);
      return updated;
    } on DioException catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

@Riverpod(keepAlive: true)
class UserDelete extends _$UserDelete {
  @override
  Future<void> build() async {}

  /// Hapus pengguna. 404 = sudah hilang di server, tetap dianggap sukses.
  Future<void> deleteUser(String id) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      await dio.delete('/api/users/$id');
      state = const AsyncData(null);
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 404) {
        state = const AsyncData(null);
        return;
      }
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}
