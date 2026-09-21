// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$salesListHash() => r'f71718e210372d7269d29bc12f40f81f6f7cb8c0';

/// See also [salesList].
@ProviderFor(salesList)
final salesListProvider = FutureProvider<List<Sale>>.internal(
  salesList,
  name: r'salesListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$salesListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SalesListRef = FutureProviderRef<List<Sale>>;
String _$saleDetailHash() => r'2743af29d904783bbab91e9c85085951cfcdfe42';

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

/// See also [saleDetail].
@ProviderFor(saleDetail)
const saleDetailProvider = SaleDetailFamily();

/// See also [saleDetail].
class SaleDetailFamily extends Family<AsyncValue<Sale>> {
  /// See also [saleDetail].
  const SaleDetailFamily();

  /// See also [saleDetail].
  SaleDetailProvider call(String id) {
    return SaleDetailProvider(id);
  }

  @override
  SaleDetailProvider getProviderOverride(
    covariant SaleDetailProvider provider,
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
  String? get name => r'saleDetailProvider';
}

/// See also [saleDetail].
class SaleDetailProvider extends FutureProvider<Sale> {
  /// See also [saleDetail].
  SaleDetailProvider(String id)
    : this._internal(
        (ref) => saleDetail(ref as SaleDetailRef, id),
        from: saleDetailProvider,
        name: r'saleDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$saleDetailHash,
        dependencies: SaleDetailFamily._dependencies,
        allTransitiveDependencies: SaleDetailFamily._allTransitiveDependencies,
        id: id,
      );

  SaleDetailProvider._internal(
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
    FutureOr<Sale> Function(SaleDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SaleDetailProvider._internal(
        (ref) => create(ref as SaleDetailRef),
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
  FutureProviderElement<Sale> createElement() {
    return _SaleDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SaleDetailProvider && other.id == id;
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
mixin SaleDetailRef on FutureProviderRef<Sale> {
  /// The parameter `id` of this provider.
  String get id;
}

class _SaleDetailProviderElement extends FutureProviderElement<Sale>
    with SaleDetailRef {
  _SaleDetailProviderElement(super.provider);

  @override
  String get id => (origin as SaleDetailProvider).id;
}

String _$saleCreateHash() => r'ef389cd73f806b0272b9ff260fc0bbcac3112c87';

/// See also [SaleCreate].
@ProviderFor(SaleCreate)
final saleCreateProvider = AsyncNotifierProvider<SaleCreate, Sale?>.internal(
  SaleCreate.new,
  name: r'saleCreateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$saleCreateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SaleCreate = AsyncNotifier<Sale?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
