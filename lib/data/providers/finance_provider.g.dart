// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$financeListHash() => r'601de2b9abb88505e90857e70239e37ec41c8ffa';

/// See also [financeList].
@ProviderFor(financeList)
final financeListProvider = FutureProvider<List<FinanceEntry>>.internal(
  financeList,
  name: r'financeListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$financeListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FinanceListRef = FutureProviderRef<List<FinanceEntry>>;
String _$financeCreateHash() => r'1b21ab2f6fd555b842d8beffaf9dc0bbaca53774';

/// See also [FinanceCreate].
@ProviderFor(FinanceCreate)
final financeCreateProvider =
    AsyncNotifierProvider<FinanceCreate, FinanceEntry?>.internal(
      FinanceCreate.new,
      name: r'financeCreateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$financeCreateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FinanceCreate = AsyncNotifier<FinanceEntry?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
