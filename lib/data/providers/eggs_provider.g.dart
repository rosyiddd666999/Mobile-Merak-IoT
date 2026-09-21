// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eggs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eggsListHash() => r'88acd674c3693379e26f7ba71c778cc7d28b6da8';

/// See also [eggsList].
@ProviderFor(eggsList)
final eggsListProvider = FutureProvider<List<Egg>>.internal(
  eggsList,
  name: r'eggsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$eggsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EggsListRef = FutureProviderRef<List<Egg>>;
String _$eggDetailHash() => r'f6e113a72cab2344d74aba538f02f56f596484ac';

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

/// See also [eggDetail].
@ProviderFor(eggDetail)
const eggDetailProvider = EggDetailFamily();

/// See also [eggDetail].
class EggDetailFamily extends Family<AsyncValue<Egg>> {
  /// See also [eggDetail].
  const EggDetailFamily();

  /// See also [eggDetail].
  EggDetailProvider call(String id) {
    return EggDetailProvider(id);
  }

  @override
  EggDetailProvider getProviderOverride(covariant EggDetailProvider provider) {
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
  String? get name => r'eggDetailProvider';
}

/// See also [eggDetail].
class EggDetailProvider extends FutureProvider<Egg> {
  /// See also [eggDetail].
  EggDetailProvider(String id)
    : this._internal(
        (ref) => eggDetail(ref as EggDetailRef, id),
        from: eggDetailProvider,
        name: r'eggDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$eggDetailHash,
        dependencies: EggDetailFamily._dependencies,
        allTransitiveDependencies: EggDetailFamily._allTransitiveDependencies,
        id: id,
      );

  EggDetailProvider._internal(
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
  Override overrideWith(FutureOr<Egg> Function(EggDetailRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: EggDetailProvider._internal(
        (ref) => create(ref as EggDetailRef),
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
  FutureProviderElement<Egg> createElement() {
    return _EggDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EggDetailProvider && other.id == id;
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
mixin EggDetailRef on FutureProviderRef<Egg> {
  /// The parameter `id` of this provider.
  String get id;
}

class _EggDetailProviderElement extends FutureProviderElement<Egg>
    with EggDetailRef {
  _EggDetailProviderElement(super.provider);

  @override
  String get id => (origin as EggDetailProvider).id;
}

String _$eggCreateHash() => r'2262e6f0ceb0acc559f60e6abafd6f4a28c8cd28';

/// See also [EggCreate].
@ProviderFor(EggCreate)
final eggCreateProvider = AsyncNotifierProvider<EggCreate, Egg?>.internal(
  EggCreate.new,
  name: r'eggCreateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$eggCreateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EggCreate = AsyncNotifier<Egg?>;
String _$eggUpdateHash() => r'aff3422fb442dac5956596a11c2d3d9cefd26f8a';

/// See also [EggUpdate].
@ProviderFor(EggUpdate)
final eggUpdateProvider = AsyncNotifierProvider<EggUpdate, Egg?>.internal(
  EggUpdate.new,
  name: r'eggUpdateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$eggUpdateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EggUpdate = AsyncNotifier<Egg?>;
String _$eggDeleteHash() => r'50f7ba5a3b861786982c5de649c6af5c02162c9d';

/// See also [EggDelete].
@ProviderFor(EggDelete)
final eggDeleteProvider = AsyncNotifierProvider<EggDelete, void>.internal(
  EggDelete.new,
  name: r'eggDeleteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$eggDeleteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EggDelete = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
