// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

final class DatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'dd3a24de1631730545e1b0efe8be81b12b9d76d9';

@ProviderFor(sampleRepository)
final sampleRepositoryProvider = SampleRepositoryProvider._();

final class SampleRepositoryProvider
    extends
        $FunctionalProvider<
          SampleRepository,
          SampleRepository,
          SampleRepository
        >
    with $Provider<SampleRepository> {
  SampleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sampleRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sampleRepositoryHash();

  @$internal
  @override
  $ProviderElement<SampleRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SampleRepository create(Ref ref) {
    return sampleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SampleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SampleRepository>(value),
    );
  }
}

String _$sampleRepositoryHash() => r'9fe7c0b2fb1e62a0b5127f154ba821e54c8ebf45';

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileRepository,
          ProfileRepository,
          ProfileRepository
        >
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileRepository>(value),
    );
  }
}

String _$profileRepositoryHash() => r'4b207e74f8e386bcbc56bdd6ac9baeb0640d2710';

@ProviderFor(walkSessionRepository)
final walkSessionRepositoryProvider = WalkSessionRepositoryProvider._();

final class WalkSessionRepositoryProvider
    extends
        $FunctionalProvider<
          WalkSessionRepository,
          WalkSessionRepository,
          WalkSessionRepository
        >
    with $Provider<WalkSessionRepository> {
  WalkSessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walkSessionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walkSessionRepositoryHash();

  @$internal
  @override
  $ProviderElement<WalkSessionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WalkSessionRepository create(Ref ref) {
    return walkSessionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalkSessionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalkSessionRepository>(value),
    );
  }
}

String _$walkSessionRepositoryHash() =>
    r'090be2dbce0d98fceb59431ee6992655246442f6';
