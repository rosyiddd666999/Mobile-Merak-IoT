import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Wrapper mqtt_client: koneksi persisten + reconnect terkoordinasi.
///
/// Prinsip anti-putus:
/// - Tepat 1 klien aktif: klien lama selalu di-teardown total sebelum baru.
/// - Satu penjadwal reconnect dengan backoff + jitter (2s -> 60s).
/// - Putus tak terduga (socket drop, ganti WiFi, Doze) langsung dijadwalkan
///   ulang di [_handleDisconnected], tidak hanya mengandalkan `autoReconnect`.
/// - Gagal auth (notAuthorized) TIDAK di-retry membabi buta.
class MqttService {
  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _sub;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _connecting = false;
  bool _manualDisconnect = false;
  int _connectSeq = 0;
  int _backoffSeconds = 2;

  /// Diagnosa tanpa kredensial.
  int reconnectCount = 0;
  DateTime? lastDisconnectAt;
  String? lastErrorDetail;
  DateTime? nextRetryAt;

  /// Latch blokir auth: begitu broker menolak kredensial ini, semua jalur
  /// OTOMATIS (schedule/retrySoon/onDisconnected) berhenti. Retry manual
  /// dengan `force:true` (tombol UI) tetap diizinkan satu kali untuk
  /// verifikasi setelah password diperbaiki. Dibuka otomatis bila
  /// url/username/password BERBEDA dari yang diblokir.
  bool authBlocked = false;
  String? _authBlockKey;

  // Param terakhir untuk reconnectNow().
  String? _lastUrl;
  String? _lastUsername;
  String? _lastPassword;
  List<String> _lastTopics = const [];

  void Function(String topic, String payload)? onMessage;
  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function()? onAutoReconnect;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  bool get isConnecting => _connecting;

  /// Return code terakhir (notAuthorized vs network) — tanpa kredensial.
  String? get lastReturnCode =>
      _client?.connectionStatus?.returnCode.toString();

  /// True bila putus terakhir karena auth (jangan retry agresif).
  /// Mengecek returnCode DAN pesan exception mqtt_client yang membawa
  /// return code di dalam string ("... return code is ...notAuthorized")
  /// karena pada jalur exception `connectionStatus` kadang sudah null.
  bool get lastWasAuthFailure {
    final rc = _client?.connectionStatus?.returnCode;
    if (rc == MqttConnectReturnCode.notAuthorized ||
        rc == MqttConnectReturnCode.badUsernameOrPassword) {
      return true;
    }
    final detail = lastErrorDetail ?? '';
    return detail.contains('notAuthorized') ||
        detail.contains('badUsernameOrPassword') ||
        detail.contains('Not authorized');
  }

  static String _credKey(String url, String? u, String? p) =>
      '$url|$u|${p?.length ?? 0}:${p.hashCode}';

  static bool _looksLikeAuthFailure(Object e) {
    final s = e.toString();
    return s.contains('notAuthorized') ||
        s.contains('badUsernameOrPassword') ||
        s.contains('Not authorized') ||
        s.contains('Not Authorized');
  }

  void _latchAuthBlock(String url, String? u, String? p) {
    authBlocked = true;
    _authBlockKey = _credKey(url, u, p);
  }

  Future<bool> connect({
    required String url,
    String? username,
    String? password,
    required List<String> subscribeTopics,
    Duration timeout = const Duration(seconds: 7),
    bool force = false,
  }) async {
    if (_disposed) return false;
    if (_connecting) return false;
    if (isConnected) return true;
    // Kredensial yang sama dengan yang diblokir: tolak retry otomatis.
    // Manual (force) atau kredensial baru tetap boleh coba.
    if (authBlocked && !force) {
      if (_authBlockKey == _credKey(url, username, password)) {
        return false;
      }
      // Kredensial berbeda -> buka blokir, coba lagi.
      authBlocked = false;
      _authBlockKey = null;
    }
    _lastUrl = url;
    _lastUsername = username;
    _lastPassword = password;
    _lastTopics = subscribeTopics;
    _connecting = true;
    _manualDisconnect = false;
    final seq = ++_connectSeq;
    // Jangan tumpuk klien: teardown total dulu (tanpa menandai manual).
    _teardownClient(suppressReconnect: true);
    try {
      final uri = Uri.parse(url);
      final host = uri.host.isNotEmpty ? uri.host : url;
      final port = uri.hasPort ? uri.port : 8883;
      // Fail-fast: jangan lakukan DNS lookup atas string sampah (mis. URL utuh
      // nyasar jadi hostname) — itu dulu sebabkan infinite `Failed host lookup`.
      if (host.isEmpty || host.contains('://') || host.contains('/')) {
        _connecting = false;
        lastErrorDetail = 'host MQTT tidak valid (cek MQTT_HOST, harus bare hostname)';
        if (!kReleaseMode) debugPrint('[MQTT] $lastErrorDetail');
        return false;
      }
      final useWs =
          uri.scheme == 'wss' || uri.scheme == 'ws' || url.contains('/mqtt');
      // Native mqtts (8883, MOBILE.md §12) butuh TLS; wss juga TLS.
      final secure = useWs
          ? uri.scheme == 'wss'
          : (uri.scheme == 'mqtts' || port == 8883);
      // Pola web (useMqttBridge.js): kampung-merak-<klien>-<rand>.
      final clientId = 'kampung-merak-flutter-${Random().nextInt(1 << 30)}';

      // WebSocket WAJIB menyertakan path (/mqtt) — tanpanya handshake HiveMQ gagal.
      final wsPath = uri.path.isEmpty ? '/mqtt' : uri.path;
      final client = useWs
          ? MqttServerClient.withPort('wss://$host$wsPath', clientId, port)
          : MqttServerClient.withPort(host, clientId, port);
      client.logging(on: false);
      client.keepAlivePeriod = 25;
      client.connectTimeoutPeriod = 7000;
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true;
      client.onConnected = _handleConnected;
      client.onDisconnected = _handleDisconnected;
      client.pongCallback = _handlePong;
      if (useWs) {
        client.useWebSocket = true;
        client.websocketProtocols = const ['mqtt'];
        // PENTING: jangan set client.secure untuk wss — mqtt_client mematikan
        // useWebSocket bila secure=true (jatuh ke raw TLS TCP dengan string
        // URL utuh sebagai host -> `Failed host lookup: 'wss://...'`). TLS
        // sudah inheren dari skema wss di koneksi websocket.
      }
      // Sertifikat HiveMQ Cloud valid publik — tanpa bypass verifikasi.
      // Hanya untuk native mqtts (TCP). Jalur websocket tidak pakai flag ini.
      if (secure && !useWs) {
        client.secure = true;
      }

      final msg = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withProtocolVersion(MqttClientConstants.mqttV311ProtocolVersion)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      client.connectionMessage = msg;
      _client = client;

      final status = await client
          .connect(username, password)
          .timeout(timeout, onTimeout: () => client.connectionStatus!);
      // Connect basi (sudah di-teardown oleh reconnectNow/dispose): abaikan.
      if (seq != _connectSeq || _disposed || _client != client) {
        _connecting = false;
        return false;
      }
      _connecting = false;
      if (!kReleaseMode) {
        // Tanpa kredensial: hanya state + return code untuk diagnosa.
        debugPrint(
            '[MQTT] hasil: state=${status?.state} returnCode=${status?.returnCode}');
      }
      if (status?.state != MqttConnectionState.connected) {
        lastErrorDetail =
            'connect ${status?.state} (${status?.returnCode}) via ${useWs ? 'websocket' : 'native'}';
        if (lastWasAuthFailure) {
          // Kredensial salah: latch blokir, jangan retry otomatis.
          _latchAuthBlock(url, username, password);
          if (!kReleaseMode) {
            debugPrint('[MQTT] auth gagal, hentikan auto-retry.');
          }
          return false;
        }
        _scheduleReconnect();
        return false;
      }

      _backoffSeconds = 2;
      lastErrorDetail = null;
      nextRetryAt = null;
      for (final t in subscribeTopics) {
        client.subscribe(t, MqttQos.atMostOnce);
      }
      await _sub?.cancel();
      _sub = client.updates?.listen((events) {
        for (final e in events) {
          final msg = e.payload as MqttPublishMessage;
          final payload =
              MqttPublishPayload.bytesToStringAsString(msg.payload.message);
          try {
            onMessage?.call(e.topic, payload);
          } catch (err) {
            if (!kReleaseMode) debugPrint('[MQTT] onMessage error: $err');
          }
        }
      });
      return true;
    } on SocketException catch (e) {
      if (!kReleaseMode) debugPrint('[MQTT] socket error: $e');
      _connecting = false;
      if (seq != _connectSeq || _disposed) return false;
      lastErrorDetail = 'socket: $e';
      _scheduleReconnect();
      return false;
    } catch (e) {
      if (!kReleaseMode) debugPrint('[MQTT] connect failed: $e');
      _connecting = false;
      if (seq != _connectSeq || _disposed) return false;
      lastErrorDetail = 'connect failed: $e';
      if (_looksLikeAuthFailure(e) || lastWasAuthFailure) {
        // mqtt_client melempar NoConnectionException dengan return code
        // di dalam pesan — sebelumnya lolos dari cek auth dan menyebabkan
        // retry membabi buta. Sekarang di-latch.
        _latchAuthBlock(url, username, password);
        if (!kReleaseMode) {
          debugPrint('[MQTT] auth gagal (exception), hentikan auto-retry.');
        }
        return false;
      }
      _scheduleReconnect();
      return false;
    }
  }

  void _handleConnected() {
    _backoffSeconds = 2;
    nextRetryAt = null;
    lastErrorDetail = null;
    onConnected?.call();
  }

  void _handlePong() {
    // Pong = jalur hidup; jangan biarkan backoff membesar tanpa alasan.
    if (isConnected && _backoffSeconds > 2) _backoffSeconds = 2;
  }

  void _handleDisconnected() {
    lastDisconnectAt = DateTime.now();
    if (!kReleaseMode) {
      debugPrint(
          '[MQTT] disconnected rc=${_client?.connectionStatus?.returnCode} manual=$_manualDisconnect disposed=$_disposed');
    }
    try {
      onDisconnected?.call();
    } catch (_) {}
    if (_disposed || _manualDisconnect) return;
    if (lastWasAuthFailure) {
      lastErrorDetail = 'auth gagal (${_client?.connectionStatus?.returnCode})';
      return;
    }
    onAutoReconnect?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _manualDisconnect) return;
    if (authBlocked || lastWasAuthFailure) return;
    _reconnectTimer?.cancel();
    final base = _backoffSeconds;
    // Jitter ±30% agar banyak HP tidak menyerbu broker serentak.
    final jitter = Random().nextInt((base * 0.6).ceil() + 1);
    final delay = (base + jitter - (base * 0.3).floor()).clamp(2, 60);
    _backoffSeconds = (_backoffSeconds * 2).clamp(2, 60);
    reconnectCount++;
    nextRetryAt = DateTime.now().add(Duration(seconds: delay));
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (_disposed || _manualDisconnect || isConnected || _connecting) return;
      if (_lastUrl == null) return;
      if (!kReleaseMode) {
        debugPrint('[MQTT] reconnect #$reconnectCount (${delay}s)...');
      }
      connect(
        url: _lastUrl!,
        username: _lastUsername,
        password: _lastPassword,
        subscribeTopics: _lastTopics,
      );
    });
  }

  /// Reconnect manual (tombol retry / kirim gagal / jaringan kembali):
  /// batalkan jadwal lama, teardown, sambung ulang segera.
  /// `force:true` = aksi eksplisit user, diizinkan meski authBlocked.
  Future<bool> reconnectNow({bool force = false}) async {
    if (_disposed) return false;
    if (authBlocked && !force) return false;
    if (force) {
      authBlocked = false;
      _authBlockKey = null;
    }
    _connectSeq++; // batalkan connect yang masih jalan
    _connecting = false;
    _manualDisconnect = false;
    _teardownClient(suppressReconnect: true);
    if (_lastUrl == null) return false;
    _backoffSeconds = 2;
    return connect(
      url: _lastUrl!,
      username: _lastUsername,
      password: _lastPassword,
      subscribeTopics: _lastTopics,
      force: force,
    );
  }

  /// Dipanggil saat jaringan kembali / app resume: paksa coba segera.
  /// TIDAK dipanggil bila auth diblokir (kredensial salah — retry sia-sia).
  void retrySoon() {
    if (_disposed || _manualDisconnect) return;
    if (authBlocked) return;
    if (isConnected || _connecting || _lastUrl == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 1), () {
      if (_disposed || _manualDisconnect || isConnected || _connecting) return;
      reconnectNow();
    });
  }

  void publish(String topic, String payload) {
    final client = _client;
    if (client == null || !isConnected) return;
    final builder = MqttClientPayloadBuilder()..addString(payload);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  /// Teardown total klien lama agar tak ada 2 koneksi berebut broker.
  void _teardownClient({bool suppressReconnect = false}) {
    if (suppressReconnect) _reconnectTimer?.cancel();
    final client = _client;
    _client = null;
    // Batalkan listener dulu agar onDisconnected lama tak memicu retry ganda.
    final sub = _sub;
    _sub = null;
    if (sub != null) {
      try {
        sub.cancel();
      } catch (_) {}
    }
    if (client != null) {
      try {
        client.autoReconnect = false;
      } catch (_) {}
      try {
        client.onDisconnected = null;
      } catch (_) {}
      try {
        client.disconnect();
      } catch (_) {}
    }
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _connectSeq++;
    _connecting = false;
    _reconnectTimer?.cancel();
    nextRetryAt = null;
    await _sub?.cancel();
    _sub = null;
    _teardownClient();
  }

  Future<void> dispose() async {
    _disposed = true;
    _connectSeq++;
    await disconnect();
  }
}
