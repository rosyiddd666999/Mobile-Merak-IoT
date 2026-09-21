// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alerts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$alertsListHash() => r'ef81934ab1d3ec416fb1d4251d675121d09775e0';

/// See also [alertsList].
@ProviderFor(alertsList)
final alertsListProvider = FutureProvider<List<Alert>>.internal(
  alertsList,
  name: r'alertsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alertsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlertsListRef = FutureProviderRef<List<Alert>>;
String _$alertDeleteHash() => r'72a2b5257082a771c3e7e2024770e7660ad03669';

/// See also [AlertDelete].
@ProviderFor(AlertDelete)
final alertDeleteProvider = AsyncNotifierProvider<AlertDelete, void>.internal(
  AlertDelete.new,
  name: r'alertDeleteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alertDeleteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AlertDelete = AsyncNotifier<void>;
String _$alertReaderHash() => r'4388a1892f918de2a1eef54cdfec5e60d50a236b';

/// See also [AlertReader].
@ProviderFor(AlertReader)
final alertReaderProvider = AsyncNotifierProvider<AlertReader, void>.internal(
  AlertReader.new,
  name: r'alertReaderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alertReaderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AlertReader = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
