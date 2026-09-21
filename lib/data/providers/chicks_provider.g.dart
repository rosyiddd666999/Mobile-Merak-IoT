// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chicks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chicksListHash() => r'c7938c35d2be72f507615cbf7e282558ea633886';

/// See also [chicksList].
@ProviderFor(chicksList)
final chicksListProvider = FutureProvider<List<Chick>>.internal(
  chicksList,
  name: r'chicksListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chicksListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChicksListRef = FutureProviderRef<List<Chick>>;
String _$chickDetailHash() => r'dfcf6e6f94b0a11a425eaa2af47509e53aee93d0';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [chickDetail].
@ProviderFor(chickDetail)
const chickDetailProvider = ChickDetailFamily();

/// See also [chickDetail].
class ChickDetailFamily extends Family<AsyncValue<Chick>> {
  /// See also [chickDetail].
  const ChickDetailFamily();

  /// See also [chickDetail].
  ChickDetailProvider call(String id) {
    return ChickDetailProvider(id);
  }

  @override
  ChickDetailProvider getProviderOverride(
    covariant ChickDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chickDetailProvider';
}

/// See also [chickDetail].
class ChickDetailProvider extends FutureProvider<Chick> {
  /// See also [chickDetail].
  ChickDetailProvider(String id)
    : this._internal(
        (ref) => chickDetail(ref as ChickDetailRef, id),
        from: chickDetailProvider,
        name: r'chickDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chickDetailHash,
        dependencies: ChickDetailFamily._dependencies,
        allTransitiveDependencies: ChickDetailFamily._allTransitiveDependencies,
        id: id,
      );

  ChickDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Chick> Function(ChickDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChickDetailProvider._internal(
        (ref) => create(ref as ChickDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  FutureProviderElement<Chick> createElement() {
    return _ChickDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChickDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChickDetailRef on FutureProviderRef<Chick> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ChickDetailProviderElement extends FutureProviderElement<Chick>
    with ChickDetailRef {
  _ChickDetailProviderElement(super.provider);

  @override
  String get id => (origin as ChickDetailProvider).id;
}

String _$chickCreateHash() => r'4ebcfc3d356a093cf492e475b77d747699def7f0';

/// See also [ChickCreate].
@ProviderFor(ChickCreate)
final chickCreateProvider = AsyncNotifierProvider<ChickCreate, Chick?>.internal(
  ChickCreate.new,
  name: r'chickCreateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chickCreateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChickCreate = AsyncNotifier<Chick?>;
String _$chickUpdateHash() => r'7698878b0c1a1ea62822cb14c164b79122cd63ba';

/// See also [ChickUpdate].
@ProviderFor(ChickUpdate)
final chickUpdateProvider = AsyncNotifierProvider<ChickUpdate, Chick?>.internal(
  ChickUpdate.new,
  name: r'chickUpdateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chickUpdateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChickUpdate = AsyncNotifier<Chick?>;
String _$chickDeleteHash() => r'e0b839150754999e1ae8af167ae0310c7806bac1';

/// See also [ChickDelete].
@ProviderFor(ChickDelete)
final chickDeleteProvider = AsyncNotifierProvider<ChickDelete, void>.internal(
  ChickDelete.new,
  name: r'chickDeleteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chickDeleteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChickDelete = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
