import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/finance_entry.dart';
import 'api_client_provider.dart';

part 'finance_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<FinanceEntry>> financeList(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/finance');
    return (response.data as List)
        .map((e) => FinanceEntry.fromJson(e))
        .toList();
  } on DioException {
    rethrow;
  }
}

@Riverpod(keepAlive: true)
class FinanceCreate extends _$FinanceCreate {
  @override
  FutureOr<FinanceEntry?> build() => null;

  Future<FinanceEntry?> create(FinanceEntry entry) async {
    state = const AsyncLoading();
    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.post('/api/finance', data: entry.toJson());
      final created = FinanceEntry.fromJson(response.data);
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
