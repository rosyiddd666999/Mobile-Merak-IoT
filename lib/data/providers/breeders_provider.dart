import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/breeder.dart';
import '../models/breeder_lineage.dart';
import '../models/breeder_compare_item.dart';
import 'api_client_provider.dart';

part 'breeders_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<Breeder>> breedersList(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/breeders');
    return (response.data as List).map((e) => Breeder.fromJson(e)).toList();
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
Future<Breeder> breederDetail(Ref ref, String id) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/breeders/$id');
    return Breeder.fromJson(response.data);
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
Future<BreederLineage> breederLineage(Ref ref, String id) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/breeders/$id/lineage');
    return BreederLineage.fromJson(response.data);
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
Future<List<BreederCompareItem>> breederCompare(
    Ref ref, List<String> ids) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/breeders/compare',
        queryParameters: {'ids': ids.join(',')});
    return (response.data as List)
        .map((e) => BreederCompareItem.fromJson(e))
        .toList();
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
class BreederCreate extends _$BreederCreate {
  @override
  FutureOr<Breeder?> build() => null;

  Future<Breeder?> create(Breeder breeder) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.post('/api/breeders', data: breeder.toJson());
      final created = Breeder.fromJson(response.data);
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
class BreederUpdate extends _$BreederUpdate {
  @override
  FutureOr<Breeder?> build() => null;

  Future<Breeder?> updateBreeder(String id, Breeder breeder) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      final response =
          await dio.put('/api/breeders/$id', data: breeder.toJson());
      final updated = Breeder.fromJson(response.data);
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
class BreederDelete extends _$BreederDelete {
  @override
  FutureOr<void> build() {}

  /// Hapus indukan. 404 = sudah hilang di server, tetap dianggap sukses.
  Future<void> deleteBreeder(String id) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      await dio.delete('/api/breeders/$id');
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
