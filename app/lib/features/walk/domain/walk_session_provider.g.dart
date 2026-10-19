// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'walk_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$walkSessionHash() => r'efe89fc38c8b329fd26503b5f544a1b19c358096';

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
