// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cctv_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cctvSnapshotsHash() => r'c01a862eb2b1c2dafbc49c722f331e2b124a1a01';

/// Riwayat snapshot CCTV (`GET /api/cctv-snapshots`, terbaru dulu bila API
/// mendukung `?limit`). Live stream tetap via MJPEG; ini galeri statis.
///
/// Copied from [cctvSnapshots].
@ProviderFor(cctvSnapshots)
final cctvSnapshotsProvider = FutureProvider<List<CctvSnapshot>>.internal(
  cctvSnapshots,
  name: r'cctvSnapshotsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cctvSnapshotsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CctvSnapshotsRef = FutureProviderRef<List<CctvSnapshot>>;
String _$cctvHash() => r'0f1c2ec23f090cd1e8af3db2f2976a5a4fc69390';

/// See also [Cctv].
@ProviderFor(Cctv)
final cctvProvider = NotifierProvider<Cctv, CctvState>.internal(
  Cctv.new,
  name: r'cctvProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cctvHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Cctv = Notifier<CctvState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
