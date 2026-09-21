// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'users_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$usersListHash() => r'38424760dce771cba83e776e80f9819e84c3d990';

/// See also [usersList].
@ProviderFor(usersList)
final usersListProvider = FutureProvider<List<User>>.internal(
  usersList,
  name: r'usersListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$usersListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UsersListRef = FutureProviderRef<List<User>>;
String _$userCreateHash() => r'ffb030327b808a7bc8fcd1ffd3b21a58ac823900';

/// See also [UserCreate].
@ProviderFor(UserCreate)
final userCreateProvider = AsyncNotifierProvider<UserCreate, User?>.internal(
  UserCreate.new,
  name: r'userCreateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userCreateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserCreate = AsyncNotifier<User?>;
String _$userDeleteHash() => r'fbc3bcfd0a777619f83dd78fc82f1a0d25534863';

/// See also [UserDelete].
@ProviderFor(UserDelete)
final userDeleteProvider = AsyncNotifierProvider<UserDelete, void>.internal(
  UserDelete.new,
  name: r'userDeleteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userDeleteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserDelete = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
