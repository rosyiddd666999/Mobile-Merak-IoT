import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import 'api_client_provider.dart';

final salesListProvider = FutureProvider<List<Sale>>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/sales');
    return (response.data as List).map((e) => Sale.fromJson(e)).toList();
  } on DioException {
    rethrow;
  }
});

final saleDetailProvider = FutureProvider.family<Sale, String>((ref, id) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/sales/$id');
    return Sale.fromJson(response.data);
  } on DioException {
    rethrow;
  }
});

class SaleCreateNotifier extends AsyncNotifier<Sale?> {
  @override
  Future<Sale?> build() async => null;

  Future<Sale?> create(Sale sale) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.post('/api/sales', data: sale.toJson());
      final created = Sale.fromJson(response.data);
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

final saleCreateProvider = AsyncNotifierProvider<SaleCreateNotifier, Sale?>(
  SaleCreateNotifier.new,
);
