import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../models/mqtt_config.dart';
import '../models/telemetry_log.dart';
import '../services/mqtt_service.dart';
import 'api_client_provider.dart';
import 'incubator_provider.dart';

/// Topik subscribe (firmware ESP32, 6 topik incl. status_sensor).
const mqttSubscribeTopics = [
  'iot/telemetry/temperature',
  'iot/telemetry/humidity',
  'iot/telemetry/status_lamp',
  'iot/telemetry/status_motor',
  'iot/telemetry/status_mist',
  'iot/telemetry/status_sensor',
];

class MqttState {
  final String status; // idle/connecting/connected/reconnecting/offline/error
  final double? temperature;
  final double? humidity;
  final String? statusLamp;
  final String? statusMotor;
  final String? statusMist;
  final String? statusSensor; // OK | ERROR (kesehatan sensor SHT31)
  final List<TelemetryLog> trend; // buffer 24 titik terakhir
  final DateTime? lastTelemetryAt;
  final String? lastError; // tanpa kredensial — untuk diagnosa UI
  final String? transport; // 'native' | 'websocket'
  final int reconnectCount;
  final bool authFailed;
  final DateTime? lastManualRotation; // picu manual terakhir dari app ini

  const MqttState({
    this.status = 'idle',
    this.temperature,
    this.humidity,
    this.statusLamp,
    this.statusMotor,
    this.statusMist,
    this.statusSensor,
    this.trend = const [],
    this.lastTelemetryAt,
    this.lastError,
    this.transport,
    this.reconnectCount = 0,
    this.authFailed = false,
    this.lastManualRotation,
  });

  bool get hasTelemetry => temperature != null && humidity != null;

  /// Hidup jujur: connected ATAU data segar (<35 dtk; ESP publish tiap 5 dtk).
  /// Status mentah bisa macet offline walau data mengalir (drop sesaat tanpa
  /// onConnected ulang), jadi kontrol memakai ini, bukan status mentah.
  bool get isLive {
    if (status == 'connected') return true;
    if (!hasTelemetry || lastTelemetryAt == null) return false;
    return DateTime.now().difference(lastTelemetryAt!).inSeconds < 35;
  }

  MqttState copyWith({
    String? status,
    double? temperature,
    double? humidity,
    String? statusLamp,
    String? statusMotor,
    String? statusMist,
    String? statusSensor,
    List<TelemetryLog>? trend,
    DateTime? lastTelemetryAt,
    String? lastError,
    bool? clearError,
    String? transport,
    int? reconnectCount,
    bool? authFailed,
    DateTime? lastManualRotation,
  }) =>
      MqttState(
        status: status ?? this.status,
        temperature: temperature ?? this.temperature,
        humidity: humidity ?? this.humidity,
        statusLamp: statusLamp ?? this.statusLamp,
        statusMotor: statusMotor ?? this.statusMotor,
        statusMist: statusMist ?? this.statusMist,
        statusSensor: statusSensor ?? this.statusSensor,
        trend: trend ?? this.trend,
        lastTelemetryAt: lastTelemetryAt ?? this.lastTelemetryAt,
        lastError: clearError == true ? null : (lastError ?? this.lastError),
        transport: transport ?? this.transport,
        reconnectCount: reconnectCount ?? this.reconnectCount,
        authFailed: authFailed ?? this.authFailed,
        lastManualRotation: lastManualRotation ?? this.lastManualRotation,
      );
}

/// Topik perintah ESP32 (firmware esp32/incubator_controller.ino).
class MqttCmd {
  static const lampMode = 'iot/cmd/lamp_mode'; // AUTO | ON | OFF
  static const motorTrigger = 'iot/cmd/motor_trigger'; // TRIGGER
  static const mistTrigger = 'iot/cmd/mist_trigger'; // TRIGGER (mist ~10 dtk)
}

/// Mode lampu: label Indonesia <-> payload firmware.
enum LampMode { auto, on, off }

extension LampModePayload on LampMode {
  String get payload {
    switch (this) {
      case LampMode.auto:
        return 'AUTO';
      case LampMode.on:
        return 'ON';
      case LampMode.off:
        return 'OFF';
    }
  }

  String get label {
    switch (this) {
      case LampMode.auto:
        return 'Otomatis';
      case LampMode.on:
        return 'Nyala';
      case LampMode.off:
        return 'Mati';
    }
  }
}

class MqttNotifier extends StateNotifier<MqttState>
    with WidgetsBindingObserver {
  final Ref _ref;
  final MqttService _service = MqttService();
  bool _started = false;
  bool _connecting = false;
  bool _disposed = false;
  DateTime? _lastDbSync;
  Timer? _watchdog;
  DateTime? _lastAttempt;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  String _preferredTransport = 'native';

  MqttNotifier(this._ref) : super(const MqttState()) {
    WidgetsBinding.instance.addObserver(this);
    _service.onAutoReconnect = () {
      if (_disposed) return;
      state = state.copyWith(
        status: 'reconnecting',
        reconnectCount: _service.reconnectCount,
      );
    };
    _listenConnectivity();
  }

  /// Panggil dari dashboard/incubator sekali. Urutan config (MOBILE.md §7.4.1):
  /// API (`GET /api/incubator/settings`) -> .env runtime -> dart-define.
  /// Transport: native mqtts 8883 dulu, fallback WSS 8884 (jalur web, FRONTEND_WEBSITE.md §3A).
  Future<void> connectIfNeeded() async {
    if (_started || _disposed) return;
    _started = true;
    _startWatchdog();
    await _connectOnce();
  }

  void _listenConnectivity() {
    try {
      _connSub = Connectivity()
          .onConnectivityChanged
          .listen((results) async {
        if (_disposed || !_started) return;
        final hasNet = results.any((r) => r != ConnectivityResult.none);
        if (!hasNet) {
          state = state.copyWith(status: 'offline', lastError: 'tanpa jaringan');
          return;
        }
        // Auth diblokir (kredensial salah): jangan retry otomatis.
        // Tunggu user perbaiki password lalu tekan tombol retry.
        if (state.authFailed || _service.authBlocked) return;
        // Jaringan kembali: coba segera bila tidak live.
        if (state.isLive || _service.isConnected || _service.isConnecting) {
          return;
        }
        debugPrint('[MQTT] jaringan kembali, retry segera...');
        _service.retrySoon();
        // Jaring pengaman bila retrySoon diabaikan (mis. manual flag).
        Future.delayed(const Duration(seconds: 2), () {
          if (!_disposed &&
              _started &&
              !state.isLive &&
              !_service.isConnected &&
              !_service.isConnecting &&
              !_connecting) {
            _connectOnce(isRetry: true);
          }
        });
      });
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || !_started) return;
    if (state == AppLifecycleState.resumed) {
      if (this.state.authFailed || _service.authBlocked) return;
      if (this.state.isLive ||
          _service.isConnected ||
          _service.isConnecting ||
          _connecting) {
        return;
      }
      debugPrint('[MQTT] app resume, retry segera...');
      _service.retrySoon();
      Future.delayed(const Duration(seconds: 2), () {
        if (!_disposed &&
            _started &&
            !this.state.isLive &&
            !_service.isConnected &&
            !_service.isConnecting &&
            !_connecting) {
          _connectOnce(isRetry: true);
        }
      });
    }
  }

  /// Watchdog 15 detik sebagai CADANGAN (jaring utama = autoReconnect
  /// library + scheduler backoff service + connectivity/listener resume).
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_disposed || !_started) return;
      if (state.authFailed) return;
      if (state.isLive) return;
      if (_service.isConnected || _service.isConnecting || _connecting) return;
      if (_lastAttempt != null &&
          DateTime.now().difference(_lastAttempt!).inSeconds < 10) {
        return;
      }
      debugPrint('[MQTT] watchdog: tidak live, mencoba ulang...');
      await _connectOnce(isRetry: true);
    });
  }

  Future<void> _connectOnce({bool isRetry = false}) async {
    if (_disposed) return;
    if (_connecting) return;
    if (state.authFailed && isRetry) return;
    _connecting = true;
    _lastAttempt = DateTime.now();
    if (!isRetry || state.status == 'idle') {
      state = state.copyWith(status: 'connecting', clearError: true);
    } else {
      state = state.copyWith(status: 'reconnecting');
    }

    // Native mqtts host:8883 dulu (MOBILE.md §12), fallback wss web.
    final nativeUrl =
        AppConstants.mqttHost.isNotEmpty ? AppConstants.mqttNativeUrl : null;
    final wsUrl = AppConstants.mqttUrl;
    String? username = AppConstants.mqttUsername;
    String? password = AppConstants.mqttPassword;
    String? apiUrl;
    String credSource = 'ENV';
    try {
      final cfg = await _ref.read(mqttConfigProvider.future);
      if (cfg is MqttConfig && cfg.isConfigured) {
        credSource = 'API';
        apiUrl = cfg.mqttUrl;
        username = cfg.mqttUsername ?? username;
        // Password: API -> .env -> dart-define SAJA. Jangan baca secure storage:
        // cache basi bisa membayangi nilai benar tanpa terlihat di log.
        if (cfg.mqttPassword != null && cfg.mqttPassword!.isNotEmpty) {
          password = cfg.mqttPassword;
        }
      } else {
        credSource = 'ENV (API tanpa kunci mqtt)';
      }
    } catch (_) {
      credSource = 'ENV (API gagal)';
    }
    if (!kReleaseMode) {
      String host;
      try {
        host = Uri.parse(nativeUrl ?? wsUrl).host;
      } catch (_) {
        host = nativeUrl ?? wsUrl;
      }
      debugPrint(
          '[MQTT] kredensial dari $credSource sebagai ${username ?? '-'}@$host (pwdLen=${password?.length ?? 0})');
    }

    _service.onMessage = _handleMessage;
    _service.onConnected = () {
      if (_disposed) return;
      _preferredTransport = state.transport ?? _preferredTransport;
      state = state.copyWith(
        status: 'connected',
        reconnectCount: _service.reconnectCount,
      );
    };
    _service.onDisconnected = () {
      if (_disposed) return;
      state = state.copyWith(
        status: state.status == 'connected' ? 'reconnecting' : 'offline',
        reconnectCount: _service.reconnectCount,
      );
    };

    // Kandidat transport: preferensi terakhir sukses dulu, native tetap
    // prioritas default. API (biasanya wss) di tengah.
    final candidates = <MapEntry<String, String>>[];
    void addCand(String url, String kind) {
      if (!candidates.any((c) => c.key == url)) {
        candidates.add(MapEntry(url, kind));
      }
    }

    final apiKind = (apiUrl != null && apiUrl.contains('/mqtt'))
        ? 'websocket'
        : 'native';
    // Susun ulang berdasarkan preferensi agar transport tercepat dicoba dulu.
    if (_preferredTransport == 'websocket') {
      if (apiUrl != null && apiUrl.isNotEmpty && apiKind == 'websocket') {
        addCand(apiUrl, apiKind);
      }
      addCand(wsUrl, 'websocket');
      if (apiUrl != null && apiUrl.isNotEmpty && apiKind == 'native') {
        addCand(apiUrl, apiKind);
      }
      if (nativeUrl != null) addCand(nativeUrl, 'native');
    } else {
      if (nativeUrl != null) addCand(nativeUrl, 'native');
      if (apiUrl != null && apiUrl.isNotEmpty) addCand(apiUrl, apiKind);
      addCand(wsUrl, 'websocket');
    }

    try {
      for (final cand in candidates) {
        if (_disposed) return;
        // Bukti kredensial efektif (tanpa password): bedakan build basi vs broker.
        String host;
        try {
          host = Uri.parse(cand.key).host;
        } catch (_) {
          host = cand.key;
        }
        debugPrint(
            '[MQTT] mencoba ${cand.value} sebagai ${username ?? '-'}@$host ...');
        final ok = await _service.connect(
          url: cand.key,
          username: username,
          password: password,
          subscribeTopics: mqttSubscribeTopics,
        );
        if (_disposed) return;
        if (ok) {
          _preferredTransport = cand.value;
          state = state.copyWith(
            transport: cand.value,
            clearError: true,
            authFailed: false,
            reconnectCount: _service.reconnectCount,
          );
          return;
        }
        if (_service.lastWasAuthFailure || _service.authBlocked) {
          state = state.copyWith(
            status: 'error',
            lastError:
                'auth gagal (${_service.lastReturnCode}) — cek username/password HiveMQ di .env (MQTT_PASSWORD)',
            authFailed: true,
            reconnectCount: _service.reconnectCount,
          );
          return;
        }
        final rc = _service.lastReturnCode;
        final detail = _service.lastErrorDetail;
        state = state.copyWith(
          lastError:
              'gagal via ${cand.value}${rc != null ? ' ($rc)' : ''}${detail != null ? ': $detail' : ''}',
          reconnectCount: _service.reconnectCount,
        );
      }
      if (!_disposed && state.status != 'error') {
        state = state.copyWith(
          status: 'offline',
          reconnectCount: _service.reconnectCount,
        );
      }
    } finally {
      _connecting = false;
    }
  }

  void _handleMessage(String topic, String payload) {
    final now = DateTime.now();
    switch (topic) {
      case 'iot/telemetry/temperature':
        final t = double.tryParse(payload.trim());
        if (t == null) return;
        _pushTrend(temp: t, now: now);
        state = state.copyWith(temperature: t, lastTelemetryAt: now);
        _maybeSyncDb();
        break;
      case 'iot/telemetry/humidity':
        final h = double.tryParse(payload.trim());
        if (h == null) return;
        _pushTrend(hum: h, now: now);
        state = state.copyWith(humidity: h, lastTelemetryAt: now);
        _maybeSyncDb();
        break;
      case 'iot/telemetry/status_lamp':
        state = state.copyWith(statusLamp: payload.trim().toUpperCase());
        break;
      case 'iot/telemetry/status_motor':
        state = state.copyWith(statusMotor: payload.trim().toUpperCase());
        break;
      case 'iot/telemetry/status_mist':
        state = state.copyWith(statusMist: payload.trim().toUpperCase());
        break;
      case 'iot/telemetry/status_sensor':
        state = state.copyWith(statusSensor: payload.trim().toUpperCase());
        break;
      default:
        break;
    }
  }

  void _pushTrend({double? temp, double? hum, required DateTime now}) {
    final t = temp ?? state.temperature ?? 0;
    final h = hum ?? state.humidity ?? 0;
    if (t == 0 && h == 0) return;
    final next = List<TelemetryLog>.of(state.trend)
      ..add(TelemetryLog(id: now.millisecondsSinceEpoch, timestamp: now.toIso8601String(), temperature: t, humidity: h));
    if (next.length > 24) next.removeRange(0, next.length - 24);
    state = state.copyWith(trend: next);
  }

  /// Sync DB ala web (FRONTEND_WEBSITE.md §3A.5): POST /api/incubator/status
  /// max 1x/60 detik dari telemetri terakhir agar riwayat + fallback REST terisi.
  /// Field memakai nama yang benar (temperature/humidity), bukan `temp` ala bug web.
  void _maybeSyncDb() {
    if (!state.hasTelemetry) return;
    final now = DateTime.now();
    if (_lastDbSync != null && now.difference(_lastDbSync!).inSeconds < 60) return;
    _lastDbSync = now;
    Future(() async {
      try {
        final dio = _ref.read(apiClientProvider);
        await dio.post('/api/incubator/status', data: {
          'suhu_sekarang': state.temperature,
          'kelembapan_sekarang': state.humidity,
          'lampu_status': state.statusLamp ?? 'OFF',
        });
      } catch (_) {}
    });
  }

  /// Publish command (pemilik/staff only, kunci di viewer) — MOBILE.md §7.4.4.
  /// Return false bila MQTT belum terhubung (jangan kirim perintah buta).
  bool publishCommand(String topic, String payload) {
    if (!_service.isConnected) return false;
    _service.publish(topic, payload);
    return true;
  }

  /// Atur mode lampu. Return false bila belum terhubung.
  bool sendLampMode(LampMode mode) =>
      publishCommand(MqttCmd.lampMode, mode.payload);

  /// Picu putar rak sekali (motor jalan ±30 dtk di firmware).
  /// Return false bila belum terhubung.
  bool triggerMotor() => publishCommand(MqttCmd.motorTrigger, 'TRIGGER');

  /// Picu mist maker sekali (mist jalan ±10 dtk di firmware).
  /// Return false bila belum terhubung.
  bool triggerMist() => publishCommand(MqttCmd.mistTrigger, 'TRIGGER');

  /// Catat rotasi manual: label langsung akurat (optimistis) + tulis
  /// permanen ke `POST /api/incubator/rotation-logs` agar riwayat
  /// server ikut benar. Gagal POST tidak menggagalkan UI (log diredam).
  Future<void> recordManualRotation() async {
    final now = DateTime.now();
    if (_disposed) return;
    state = state.copyWith(lastManualRotation: now);
    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post('/api/incubator/rotation-logs', data: {
        'status': 'sukses',
        'catatan': 'Manual via aplikasi mobile',
        'timestamp': now.toIso8601String(),
      });
      _ref.invalidate(rotationLogsProvider);
    } catch (_) {}
  }

  /// Tombol retry: debounce 3 dtk agar tidak spam broker.
  Future<void> reconnect() async {
    if (_disposed || _connecting || _service.isConnecting) return;
    if (_lastAttempt != null &&
        DateTime.now().difference(_lastAttempt!).inSeconds < 3) {
      return;
    }
    _lastAttempt = DateTime.now();
    state = state.copyWith(
      status: 'reconnecting',
      clearError: !state.authFailed,
      authFailed: false,
    );
    // Coba jalur cepat dulu (pakai param terakhir). force:true karena ini
    // aksi eksplisit user — diizinkan satu kali meski authBlocked.
    try {
      if (await _service.reconnectNow(force: true)) {
        if (_disposed) return;
        _started = true;
        _startWatchdog();
        state = state.copyWith(
          status: 'connected',
          clearError: true,
          authFailed: false,
          reconnectCount: _service.reconnectCount,
        );
        return;
      }
    } catch (_) {}
    // reconnectNow gagal (mis. belum pernah connect): jalur normal penuh.
    _started = true;
    _startWatchdog();
    await _connectOnce(isRetry: true);
  }

  /// Dipanggil saat pull-to-refresh agar telemetri + koneksi disegarkan.
  Future<void> refreshConnection() async {
    if (_disposed) return;
    if (state.isLive && _service.isConnected) return;
    await reconnect();
  }

  @override
  void dispose() {
    _disposed = true;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _watchdog?.cancel();
    _connSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}

final mqttProvider = StateNotifierProvider<MqttNotifier, MqttState>((ref) {
  final n = MqttNotifier(ref);
  ref.onDispose(n.dispose);
  return n;
});
