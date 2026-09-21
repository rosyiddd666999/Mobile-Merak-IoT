import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/chick.dart';
import 'api_client_provider.dart';

part 'chicks_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<Chick>> chicksList(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/chicks');
    return (response.data as List).map((e) => Chick.fromJson(e)).toList();
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
Future<Chick> chickDetail(Ref ref, String id) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/chicks/$id');
    return Chick.fromJson(response.data);
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
class ChickCreate extends _$ChickCreate {
  @override
  FutureOr<Chick?> build() => null;

  Future<Chick?> create(Chick chick) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.post('/api/chicks', data: chick.toJson());
      final created = Chick.fromJson(response.data);
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

// Alias nama lama agar call-site tidak berubah.

@Riverpod(keepAlive: true)
class ChickUpdate extends _$ChickUpdate {
  @override
  FutureOr<Chick?> build() => null;

  Future<Chick?> updateChick(String id, Chick chick) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.put('/api/chicks/$id', data: chick.toJson());
      final updated = Chick.fromJson(response.data);
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

// Alias nama lama agar call-site tidak berubah.

@Riverpod(keepAlive: true)
class ChickDelete extends _$ChickDelete {
  @override
  FutureOr<void> build() {}

  /// Hapus anakan. 404 = sudah hilang di server, tetap dianggap sukses.
  Future<void> deleteChick(String id) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      await dio.delete('/api/chicks/$id');
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

// Alias nama lama agar call-site tidak berubah.
