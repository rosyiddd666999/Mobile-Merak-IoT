import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/sale.dart';
import 'api_client_provider.dart';

part 'sales_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<Sale>> salesList(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/sales');
    return (response.data as List).map((e) => Sale.fromJson(e)).toList();
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
Future<Sale> saleDetail(Ref ref, String id) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/sales/$id');
    return Sale.fromJson(response.data);
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
class SaleCreate extends _$SaleCreate {
  @override
  FutureOr<Sale?> build() => null;

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

// Alias nama lama agar call-site tidak berubah.
