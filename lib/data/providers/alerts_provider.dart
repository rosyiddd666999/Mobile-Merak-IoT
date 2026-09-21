import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/alert.dart';
import 'api_client_provider.dart';

part 'alerts_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<Alert>> alertsList(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/alerts');
    return (response.data as List).map((e) => Alert.fromJson(e)).toList();
  } on DioException {
    rethrow;
  }
}

/// Hasil bulk delete: berhasil + gagal (gagal dilewati, dilaporkan).
class BulkDeleteResult {
  final int deleted;
  final int failed;

  const BulkDeleteResult(this.deleted, this.failed);
}

@Riverpod(keepAlive: true)
class AlertDelete extends _$AlertDelete {
  @override
  Future<void> build() async {}

  /// Hapus 1 notifikasi. 404 = sudah hilang, dianggap sukses.
  Future<bool> deleteOne(int id) async {
    final dio = ref.read(apiClientProvider);
    try {
      await dio.delete('/api/alerts/$id');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return true;
      return false;
    }
  }

  /// Hapus deretan id sekuensial. Progress 0..1 via [alertBulkProgressProvider].
  /// Return jumlah berhasil/gagal. Batal aman: berhenti di titik terakhir
  /// bila [isCancelled] true (dicek tiap iterasi).
  Future<BulkDeleteResult> deleteMany(
    List<int> ids, {
    bool Function()? isCancelled,
  }) async {
    state = const AsyncLoading();
    var ok = 0;
    var fail = 0;
    for (var i = 0; i < ids.length; i++) {
      if (isCancelled?.call() == true) break;
      if (await deleteOne(ids[i])) {
        ok++;
      } else {
        fail++;
      }
      ref.read(alertBulkProgressProvider.notifier).state =
          (i + 1) / ids.length;
    }
    ref.invalidate(alertsListProvider);
    state = const AsyncData(null);
    return BulkDeleteResult(ok, fail);
  }

  void reset() {
    state = const AsyncData(null);
  }
}

/// Progress bulk 0..1, null = idle.
final alertBulkProgressProvider = StateProvider<double?>((ref) => null);
