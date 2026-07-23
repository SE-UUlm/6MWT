// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walk_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(locationService)
final locationServiceProvider = LocationServiceProvider._();

final class LocationServiceProvider
    extends
        $FunctionalProvider<LocationService, LocationService, LocationService>
    with $Provider<LocationService> {
  LocationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationServiceHash();

  @$internal
  @override
  $ProviderElement<LocationService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocationService create(Ref ref) {
    return locationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationService>(value),
    );
  }
}

String _$locationServiceHash() => r'38ada00c14c0c2521e7d291f9897c53df2e7008a';

@ProviderFor(walkSession)
final walkSessionProvider = WalkSessionProvider._();

final class WalkSessionProvider
    extends $FunctionalProvider<WalkSession, WalkSession, WalkSession>
    with $Provider<WalkSession> {
  WalkSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walkSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walkSessionHash();

  @$internal
  @override
  $ProviderElement<WalkSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WalkSession create(Ref ref) {
    return walkSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalkSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalkSession>(value),
    );
  }
}

String _$walkSessionHash() => r'11287192c8b133f97c19ee5c5ba379c8e8722648';

@ProviderFor(walkSessionState)
final walkSessionStateProvider = WalkSessionStateProvider._();

final class WalkSessionStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<WalkSessionState>,
          WalkSessionState,
          Stream<WalkSessionState>
        >
    with $FutureModifier<WalkSessionState>, $StreamProvider<WalkSessionState> {
  WalkSessionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walkSessionStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walkSessionStateHash();

  @$internal
  @override
  $StreamProviderElement<WalkSessionState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<WalkSessionState> create(Ref ref) {
    return walkSessionState(ref);
  }
}

String _$walkSessionStateHash() => r'3d26b6e8e1a02f2dc5e0a92e38cfee295c1821af';
