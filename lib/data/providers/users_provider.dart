import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'api_client_provider.dart';

final usersListProvider = FutureProvider<List<User>>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/users');
    return (response.data as List).map((e) => User.fromJson(e)).toList();
  } on DioException {
    rethrow;
  }
});

class UserCreateNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<User?> create({
    required String id,
    required String nama,
    required String email,
    required String password,
    required String role,
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

final userCreateProvider = AsyncNotifierProvider<UserCreateNotifier, User?>(
  UserCreateNotifier.new,
);

class UserDeleteNotifier extends AsyncNotifier<void> {
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

final userDeleteProvider = AsyncNotifierProvider<UserDeleteNotifier, void>(
  UserDeleteNotifier.new,
);
