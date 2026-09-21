// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incubator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mqttConfigHash() => r'4b4a4139b00f1028b72553225b7ccff524fefd9e';

/// Live: GET /api/incubator/settings saat ini me-return MqttConfig
/// {mqtt_url, mqtt_username, mqtt_password, status} (MOBILE.md §4.5/§7.4).
///
/// Copied from [mqttConfig].
@ProviderFor(mqttConfig)
final mqttConfigProvider = FutureProvider<MqttConfig?>.internal(
  mqttConfig,
  name: r'mqttConfigProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mqttConfigHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MqttConfigRef = FutureProviderRef<MqttConfig?>;
String _$incubatorStatusHash() => r'5f163b4c4126063c4a809e7346b98a8fe88d6855';

/// See also [incubatorStatus].
@ProviderFor(incubatorStatus)
final incubatorStatusProvider = FutureProvider<IncubatorStatus?>.internal(
  incubatorStatus,
  name: r'incubatorStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$incubatorStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IncubatorStatusRef = FutureProviderRef<IncubatorStatus?>;
String _$incubatorSettingsHash() => r'a289a45346973388bd572439bc9a8f3c492f4bd7';

/// See also [incubatorSettings].
@ProviderFor(incubatorSettings)
final incubatorSettingsProvider = FutureProvider<IncubatorSettings>.internal(
  incubatorSettings,
  name: r'incubatorSettingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$incubatorSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IncubatorSettingsRef = FutureProviderRef<IncubatorSettings>;
String _$incubatorStatusHistoryHash() =>
    r'2dafc997ff4fb24c1bb90ed2ac70d134eee5ef77';

/// Riwayat grafik: tabel `incubator_status` via
/// `GET /api/incubator/status/history?limit=100` (list ASC).
/// Fallback berlapis agar tidak blank saat backend belum deploy:
/// `/api/incubator/telemetry-logs` -> `/api/telemetry` -> [].
///
/// Copied from [incubatorStatusHistory].
@ProviderFor(incubatorStatusHistory)
final incubatorStatusHistoryProvider =
    FutureProvider<List<TelemetryLog>>.internal(
      incubatorStatusHistory,
      name: r'incubatorStatusHistoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$incubatorStatusHistoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IncubatorStatusHistoryRef = FutureProviderRef<List<TelemetryLog>>;
String _$rotationLogsHash() => r'7b3521130692a285f31e461b2d1839267d1331a4';

/// See also [rotationLogs].
@ProviderFor(rotationLogs)
final rotationLogsProvider = FutureProvider<List<RotationLog>>.internal(
  rotationLogs,
  name: r'rotationLogsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$rotationLogsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RotationLogsRef = FutureProviderRef<List<RotationLog>>;
String _$incubatorSettingsUpdateHash() =>
    r'4dd5b49c602c8d0c3e14da2b8c829dda632403ce';

/// See also [IncubatorSettingsUpdate].
@ProviderFor(IncubatorSettingsUpdate)
final incubatorSettingsUpdateProvider =
    NotifierProvider<
      IncubatorSettingsUpdate,
      AsyncValue<IncubatorSettings>
    >.internal(
      IncubatorSettingsUpdate.new,
      name: r'incubatorSettingsUpdateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$incubatorSettingsUpdateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IncubatorSettingsUpdate = Notifier<AsyncValue<IncubatorSettings>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
