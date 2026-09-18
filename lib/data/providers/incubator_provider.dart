import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incubator_status.dart';
import '../models/incubator_settings.dart';
import '../models/mqtt_config.dart';
import '../models/telemetry_log.dart';
import '../models/rotation_log.dart';
import 'api_client_provider.dart';

IncubatorSettings _defaultSettings() => IncubatorSettings(
      id: 1,
      suhuMin: 37.0,
      suhuMax: 38.0,
      kelembapanMin: 55.0,
      kelembapanMax: 65.0,
      intervalRotasiMenit: 240,
    );

/// Live: GET /api/incubator/settings saat ini me-return MqttConfig
/// {mqtt_url, mqtt_username, mqtt_password, status} (MOBILE.md §4.5/§7.4).
final mqttConfigProvider = FutureProvider<MqttConfig?>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/incubator/settings');
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('mqtt_url')) {
      return MqttConfig.fromJson(data);
    }
    return null;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});

final incubatorStatusProvider = FutureProvider<IncubatorStatus?>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/incubator/status');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      try {
        return IncubatorStatus.fromJson(data);
      } catch (_) {
        return null;
      }
    }
    return null;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) rethrow;
    // Router belum mount (404) atau parse gagal -> null, UI tampil empty-state.
    return null;
  } catch (_) {
    return null;
  }
});

final incubatorSettingsProvider = FutureProvider<IncubatorSettings>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/incubator/settings');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Live = MqttConfig, bukan threshold -> pakai default threshold.
      if (data.containsKey('mqtt_url') && !data.containsKey('suhu_min')) {
        return _defaultSettings();
      }
      try {
        return IncubatorSettings.fromJson(data);
      } catch (_) {
        return _defaultSettings();
      }
    }
    return _defaultSettings();
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) rethrow;
    if (e.response?.statusCode == 404) return _defaultSettings();
    rethrow;
  }
});

/// Riwayat grafik: tabel `incubator_status` via
/// `GET /api/incubator/status/history?limit=100` (list ASC).
/// Fallback berlapis agar tidak blank saat backend belum deploy:
/// `/api/incubator/telemetry-logs` -> `/api/telemetry` -> [].
final incubatorStatusHistoryProvider = FutureProvider<List<TelemetryLog>>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get(
      '/api/incubator/status/history',
      queryParameters: {'limit': 200},
    );
    final parsed = _parseTelemetry(response.data);
    if (parsed.isNotEmpty) return parsed;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) rethrow;
    // 404/jaringan -> lanjut ke fallback lama di bawah.
  } catch (_) {
    // Parse gagal -> lanjut ke fallback lama di bawah.
  }
  for (final path in ['/api/incubator/telemetry-logs', '/api/telemetry']) {
    try {
      final response = await dio.get(path);
      return _parseTelemetry(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) rethrow;
      if (e.response?.statusCode == 404) continue; // coba path berikutnya
      return [];
    } catch (_) {
      return [];
    }
  }
  return [];
});

List<TelemetryLog> _parseTelemetry(dynamic data) {
  List list;
  if (data is List) {
    list = data;
  } else if (data is Map<String, dynamic> && data['data'] is List) {
    list = data['data'] as List;
  } else {
    return [];
  }
  // Range difilter client-side oleh grafik; ambil 100 terakhir.
  final logs = list
      .whereType<Map<String, dynamic>>()
      .map((e) {
        try {
          return TelemetryLog.fromJson(e);
        } catch (_) {
          return null;
        }
      })
      .whereType<TelemetryLog>()
      .toList();
  if (logs.length > 100) return logs.sublist(logs.length - 100);
  return logs;
}

final rotationLogsProvider = FutureProvider<List<RotationLog>>((ref) async {
  final dio = ref.read(apiClientProvider);
  try {
    final response = await dio.get('/api/incubator/rotation-logs');
    final data = response.data;
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map((e) {
          try {
            return RotationLog.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<RotationLog>()
        .toList();
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) rethrow;
    return [];
  }
});

class IncubatorSettingsNotifier extends StateNotifier<AsyncValue<IncubatorSettings>> {
  final Ref _ref;

  IncubatorSettingsNotifier(this._ref) : super(const AsyncLoading());

  Future<void> update(IncubatorSettings settings) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.put('/api/incubator/settings', data: settings.toJson());
      return IncubatorSettings.fromJson(response.data as Map<String, dynamic>);
    });
  }
}

final incubatorSettingsUpdateProvider = StateNotifierProvider<IncubatorSettingsNotifier, AsyncValue<IncubatorSettings>>(
  (ref) => IncubatorSettingsNotifier(ref),
);
