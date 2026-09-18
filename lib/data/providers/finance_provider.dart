import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/finance_entry.dart';
import 'api_client_provider.dart';

final financeListProvider = FutureProvider<List<FinanceEntry>>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/finance');
    return (response.data as List).map((e) => FinanceEntry.fromJson(e)).toList();
  } on DioException {
    rethrow;
  }
});

class FinanceCreateNotifier extends AsyncNotifier<FinanceEntry?> {
  @override
  Future<FinanceEntry?> build() async => null;

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

final financeCreateProvider = AsyncNotifierProvider<FinanceCreateNotifier, FinanceEntry?>(
  FinanceCreateNotifier.new,
);
