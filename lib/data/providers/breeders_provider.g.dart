// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'breeders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$breedersListHash() => r'ebf33ae23a0ad2aa729fc5f047311109b227708e';

/// See also [breedersList].
@ProviderFor(breedersList)
final breedersListProvider = FutureProvider<List<Breeder>>.internal(
  breedersList,
  name: r'breedersListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$breedersListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BreedersListRef = FutureProviderRef<List<Breeder>>;
String _$breederDetailHash() => r'1274dc2a8dbe7817dd85964f6146c4c850a7d18b';

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

/// See also [breederDetail].
@ProviderFor(breederDetail)
const breederDetailProvider = BreederDetailFamily();

/// See also [breederDetail].
class BreederDetailFamily extends Family<AsyncValue<Breeder>> {
  /// See also [breederDetail].
  const BreederDetailFamily();

  /// See also [breederDetail].
  BreederDetailProvider call(String id) {
    return BreederDetailProvider(id);
  }

  @override
  BreederDetailProvider getProviderOverride(
    covariant BreederDetailProvider provider,
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
  String? get name => r'breederDetailProvider';
}

/// See also [breederDetail].
class BreederDetailProvider extends FutureProvider<Breeder> {
  /// See also [breederDetail].
  BreederDetailProvider(String id)
    : this._internal(
        (ref) => breederDetail(ref as BreederDetailRef, id),
        from: breederDetailProvider,
        name: r'breederDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$breederDetailHash,
        dependencies: BreederDetailFamily._dependencies,
        allTransitiveDependencies:
            BreederDetailFamily._allTransitiveDependencies,
        id: id,
      );

  BreederDetailProvider._internal(
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
    FutureOr<Breeder> Function(BreederDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BreederDetailProvider._internal(
        (ref) => create(ref as BreederDetailRef),
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
  FutureProviderElement<Breeder> createElement() {
    return _BreederDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BreederDetailProvider && other.id == id;
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
mixin BreederDetailRef on FutureProviderRef<Breeder> {
  /// The parameter `id` of this provider.
  String get id;
}

class _BreederDetailProviderElement extends FutureProviderElement<Breeder>
    with BreederDetailRef {
  _BreederDetailProviderElement(super.provider);

  @override
  String get id => (origin as BreederDetailProvider).id;
}

String _$breederLineageHash() => r'0c06157da87784844ee2573cd8750828404367ae';

/// See also [breederLineage].
@ProviderFor(breederLineage)
const breederLineageProvider = BreederLineageFamily();

/// See also [breederLineage].
class BreederLineageFamily extends Family<AsyncValue<BreederLineage>> {
  /// See also [breederLineage].
  const BreederLineageFamily();

  /// See also [breederLineage].
  BreederLineageProvider call(String id) {
    return BreederLineageProvider(id);
  }

  @override
  BreederLineageProvider getProviderOverride(
    covariant BreederLineageProvider provider,
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
  String? get name => r'breederLineageProvider';
}

/// See also [breederLineage].
class BreederLineageProvider extends FutureProvider<BreederLineage> {
  /// See also [breederLineage].
  BreederLineageProvider(String id)
    : this._internal(
        (ref) => breederLineage(ref as BreederLineageRef, id),
        from: breederLineageProvider,
        name: r'breederLineageProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$breederLineageHash,
        dependencies: BreederLineageFamily._dependencies,
        allTransitiveDependencies:
            BreederLineageFamily._allTransitiveDependencies,
        id: id,
      );

  BreederLineageProvider._internal(
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
    FutureOr<BreederLineage> Function(BreederLineageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BreederLineageProvider._internal(
        (ref) => create(ref as BreederLineageRef),
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
  FutureProviderElement<BreederLineage> createElement() {
    return _BreederLineageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BreederLineageProvider && other.id == id;
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
mixin BreederLineageRef on FutureProviderRef<BreederLineage> {
  /// The parameter `id` of this provider.
  String get id;
}

class _BreederLineageProviderElement
    extends FutureProviderElement<BreederLineage>
    with BreederLineageRef {
  _BreederLineageProviderElement(super.provider);

  @override
  String get id => (origin as BreederLineageProvider).id;
}

String _$breederCompareHash() => r'b3bdacae09f62e6490ef4e15549193990cd3d302';

/// See also [breederCompare].
@ProviderFor(breederCompare)
const breederCompareProvider = BreederCompareFamily();

/// See also [breederCompare].
class BreederCompareFamily
    extends Family<AsyncValue<List<BreederCompareItem>>> {
  /// See also [breederCompare].
  const BreederCompareFamily();

  /// See also [breederCompare].
  BreederCompareProvider call(List<String> ids) {
    return BreederCompareProvider(ids);
  }

  @override
  BreederCompareProvider getProviderOverride(
    covariant BreederCompareProvider provider,
  ) {
    return call(provider.ids);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'breederCompareProvider';
}

/// See also [breederCompare].
class BreederCompareProvider extends FutureProvider<List<BreederCompareItem>> {
  /// See also [breederCompare].
  BreederCompareProvider(List<String> ids)
    : this._internal(
        (ref) => breederCompare(ref as BreederCompareRef, ids),
        from: breederCompareProvider,
        name: r'breederCompareProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$breederCompareHash,
        dependencies: BreederCompareFamily._dependencies,
        allTransitiveDependencies:
            BreederCompareFamily._allTransitiveDependencies,
        ids: ids,
      );

  BreederCompareProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.ids,
  }) : super.internal();

  final List<String> ids;

  @override
  Override overrideWith(
    FutureOr<List<BreederCompareItem>> Function(BreederCompareRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BreederCompareProvider._internal(
        (ref) => create(ref as BreederCompareRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        ids: ids,
      ),
    );
  }

  @override
  FutureProviderElement<List<BreederCompareItem>> createElement() {
    return _BreederCompareProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BreederCompareProvider && other.ids == ids;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, ids.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BreederCompareRef on FutureProviderRef<List<BreederCompareItem>> {
  /// The parameter `ids` of this provider.
  List<String> get ids;
}

class _BreederCompareProviderElement
    extends FutureProviderElement<List<BreederCompareItem>>
    with BreederCompareRef {
  _BreederCompareProviderElement(super.provider);

  @override
  List<String> get ids => (origin as BreederCompareProvider).ids;
}

String _$breederCreateHash() => r'19cbe863d1cb6367e1e73e05abfb5af4419149ba';

/// See also [BreederCreate].
@ProviderFor(BreederCreate)
final breederCreateProvider =
    AsyncNotifierProvider<BreederCreate, Breeder?>.internal(
      BreederCreate.new,
      name: r'breederCreateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$breederCreateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BreederCreate = AsyncNotifier<Breeder?>;
String _$breederUpdateHash() => r'2b047586ae7ed10ce75b2f03a11216dbf0223192';

/// See also [BreederUpdate].
@ProviderFor(BreederUpdate)
final breederUpdateProvider =
    AsyncNotifierProvider<BreederUpdate, Breeder?>.internal(
      BreederUpdate.new,
      name: r'breederUpdateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$breederUpdateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BreederUpdate = AsyncNotifier<Breeder?>;
String _$breederDeleteHash() => r'3d324926afda0ad9e7f6fbaee009198d21e0f786';

/// See also [BreederDelete].
@ProviderFor(BreederDelete)
final breederDeleteProvider =
    AsyncNotifierProvider<BreederDelete, void>.internal(
      BreederDelete.new,
      name: r'breederDeleteProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$breederDeleteHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BreederDelete = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
