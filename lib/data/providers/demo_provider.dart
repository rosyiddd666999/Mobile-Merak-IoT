import 'dart:async';
import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/alert_margins.dart';
import '../models/alert.dart';
import '../models/incubator_status.dart';
import '../models/incubator_settings.dart';
import '../models/rotation_log.dart';
import '../models/telemetry_log.dart';

part 'demo_provider.g.dart';

class DemoState {
  final bool active;
  final IncubatorStatus? status;
  final List<TelemetryLog> telemetry;
  final List<RotationLog> rotations;
  final List<Alert> alerts;
  final IncubatorSettings? settings;

  const DemoState({
    this.active = false,
    this.status,
    this.telemetry = const [],
    this.rotations = const [],
    this.alerts = const [],
    this.settings,
  });

  DemoState copyWith({
    bool? active,
    IncubatorStatus? status,
    List<TelemetryLog>? telemetry,
    List<RotationLog>? rotations,
    List<Alert>? alerts,
    IncubatorSettings? settings,
  }) =>
      DemoState(
        active: active ?? this.active,
        status: status ?? this.status,
        telemetry: telemetry ?? this.telemetry,
        rotations: rotations ?? this.rotations,
        alerts: alerts ?? this.alerts,
        settings: settings ?? this.settings,
      );
}

@Riverpod(keepAlive: true)
class Demo extends _$Demo {
  @override
  DemoState build() {
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const DemoState();
  }

  Timer? _ticker;
  final _random = Random();
  int _alertIdCounter = 1000;
  int _rotationIdCounter = 100;
  int _telemetryIdCounter = 1000;
  DateTime? _lastRotation;

  void activate(IncubatorSettings settings) {
    if (state.active) return;

    _lastRotation = DateTime.now().subtract(const Duration(hours: 1));

    final initialStatus = IncubatorStatus(
      id: 1,
      suhuSekarang: 37.5,
      kelembapanSekarang: 60.0,
      lampuStatus: 'ON',
      updatedAt: DateTime.now(),
    );

    state = DemoState(
      active: true,
      status: initialStatus,
      settings: settings,
      telemetry: _generateInitialTelemetry(),
      rotations: _generateInitialRotations(),
      alerts: const [],
    );

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
  }

  void deactivate() {
    _ticker?.cancel();
    _ticker = null;
    _lastRotation = null;
    state = const DemoState();
  }

  void markAlertRead(int id) {
    final updated = state.alerts
        .map((a) => a.id == id ? a.copyWith(isRead: true) : a)
        .toList();
    state = state.copyWith(alerts: updated);
  }

  void clearAlerts() {
    state = state.copyWith(alerts: const []);
  }

  void _tick() {
    if (!state.active || state.status == null || state.settings == null) return;
    final s = state.status!;
    final settings = state.settings!;

    final newSuhu = (s.suhuSekarang + (_random.nextDouble() - 0.5) * 0.6)
        .clamp(35.0, 40.0);
    final newHum = (s.kelembapanSekarang + (_random.nextDouble() - 0.5) * 4.0)
        .clamp(45.0, 75.0);

    final spikedSuhu = _random.nextDouble() < 0.08
        ? (_random.nextBool() ? settings.suhuMax + 0.4 : settings.suhuMin - 0.4)
        : newSuhu;
    final spikedHum = _random.nextDouble() < 0.08
        ? (_random.nextBool() ? settings.kelembapanMax + 5 : settings.kelembapanMin - 5)
        : newHum;

    final now = DateTime.now();
    RotationLog? newRot;

    final shouldRotate = _lastRotation == null ||
        now.difference(_lastRotation!).inMinutes >= settings.intervalRotasiMenit;
    if (shouldRotate) {
      final success = _random.nextDouble() > 0.1;
      newRot = RotationLog(
        id: _rotationIdCounter++,
        timestamp: now.toIso8601String(),
        status: success ? 'sukses' : 'gagal',
        catatan: success ? null : 'Motor tidak merespons',
      );
      _lastRotation = now;
    }

    final newStatus = IncubatorStatus(
      id: s.id,
      suhuSekarang: spikedSuhu,
      kelembapanSekarang: spikedHum,
      lampuStatus: _random.nextDouble() < 0.02 ? 'OFF' : 'ON',
      updatedAt: now,
    );

    final newTelemetry = List<TelemetryLog>.from(state.telemetry)
      ..add(TelemetryLog(
        id: _telemetryIdCounter++,
        timestamp: now.toIso8601String(),
        temperature: spikedSuhu,
        humidity: spikedHum,
      ));
    if (newTelemetry.length > 100) {
      newTelemetry.removeAt(0);
    }

    final newAlerts = List<Alert>.from(state.alerts);
    // Zona toleransi: alert hanya bila MELAMPAUI margin (konsisten dgn backend).
    if (spikedSuhu > settings.suhuMax + AlertMargins.suhu) {
      newAlerts.insert(
        0,
        Alert(
          id: _alertIdCounter++,
          tipe: 'suhu',
          pesan:
              'Suhu ${spikedSuhu.toStringAsFixed(1)}°C melebihi batas (${settings.suhuMax}°C)',
          level: spikedSuhu > settings.suhuMax + 0.5 ? 'critical' : 'warning',
          isRead: false,
          createdAt: now,
        ),
      );
    } else if (spikedSuhu < settings.suhuMin - AlertMargins.suhu) {
      newAlerts.insert(
        0,
        Alert(
          id: _alertIdCounter++,
          tipe: 'suhu',
          pesan:
              'Suhu ${spikedSuhu.toStringAsFixed(1)}°C di bawah batas (${settings.suhuMin}°C)',
          level: spikedSuhu < settings.suhuMin - 0.5 ? 'critical' : 'warning',
          isRead: false,
          createdAt: now,
        ),
      );
    }
    if (spikedHum > settings.kelembapanMax + AlertMargins.kelembapan) {
      newAlerts.insert(
        0,
        Alert(
          id: _alertIdCounter++,
          tipe: 'kelembapan',
          pesan:
              'Kelembapan ${spikedHum.toStringAsFixed(0)}% melebihi batas (${settings.kelembapanMax}%)',
          level: 'warning',
          isRead: false,
          createdAt: now,
        ),
      );
    } else if (spikedHum < settings.kelembapanMin - AlertMargins.kelembapan) {
      newAlerts.insert(
        0,
        Alert(
          id: _alertIdCounter++,
          tipe: 'kelembapan',
          pesan:
              'Kelembapan ${spikedHum.toStringAsFixed(0)}% di bawah batas (${settings.kelembapanMin}%)',
          level: 'warning',
          isRead: false,
          createdAt: now,
        ),
      );
    }
    if (newAlerts.length > 50) {
      newAlerts.removeRange(50, newAlerts.length);
    }

    final newRotations = newRot != null
        ? ([newRot, ...state.rotations])
        : state.rotations;

    state = state.copyWith(
      status: newStatus,
      telemetry: newTelemetry,
      rotations: newRotations,
      alerts: newAlerts,
    );
  }

  List<TelemetryLog> _generateInitialTelemetry() {
    final List<TelemetryLog> logs = [];
    final now = DateTime.now();
    for (int i = 72; i >= 1; i--) {
      final ts = now.subtract(Duration(minutes: i * 5));
      final suhu = 37.5 + (_random.nextDouble() - 0.5) * 1.0;
      final hum = 60.0 + (_random.nextDouble() - 0.5) * 6.0;
      logs.add(TelemetryLog(
        id: _telemetryIdCounter++,
        timestamp: ts.toIso8601String(),
        temperature: suhu,
        humidity: hum,
      ));
    }
    return logs;
  }

  List<RotationLog> _generateInitialRotations() {
    final List<RotationLog> logs = [];
    final now = DateTime.now();
    for (int i = 6; i >= 1; i--) {
      final ts = now.subtract(Duration(hours: i * 4));
      logs.add(RotationLog(
        id: _rotationIdCounter++,
        timestamp: ts.toIso8601String(),
        status: _random.nextDouble() < 0.1 ? 'gagal' : 'sukses',
        catatan: null,
      ));
    }
    return logs;
  }

}
