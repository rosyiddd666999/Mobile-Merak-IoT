import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/egg.dart';
import 'api_client_provider.dart';

final eggsListProvider = FutureProvider<List<Egg>>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/eggs');
    return (response.data as List).map((e) => Egg.fromJson(e)).toList();
  } on DioException {
    rethrow;
  }
});

final eggDetailProvider = FutureProvider.family<Egg, String>((ref, id) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/eggs/$id');
    return Egg.fromJson(response.data);
  } on DioException {
    rethrow;
  }
});

class EggCreateNotifier extends AsyncNotifier<Egg?> {
  @override
  Future<Egg?> build() async => null;

  Future<Egg?> create(Egg egg) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.post('/api/eggs', data: egg.toJson());
      final created = Egg.fromJson(response.data);
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

final eggCreateProvider = AsyncNotifierProvider<EggCreateNotifier, Egg?>(
  EggCreateNotifier.new,
);

class EggUpdateNotifier extends AsyncNotifier<Egg?> {
  @override
  Future<Egg?> build() async => null;

  Future<Egg?> updateEgg(String id, Egg egg) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.put('/api/eggs/$id', data: egg.toJson());
      final updated = Egg.fromJson(response.data);
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

final eggUpdateProvider = AsyncNotifierProvider<EggUpdateNotifier, Egg?>(
  EggUpdateNotifier.new,
);

class EggDeleteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Hapus telur. 404 = sudah hilang di server, tetap dianggap sukses.
  Future<void> deleteEgg(String id) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      await dio.delete('/api/eggs/$id');
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

final eggDeleteProvider = AsyncNotifierProvider<EggDeleteNotifier, void>(
  EggDeleteNotifier.new,
);
