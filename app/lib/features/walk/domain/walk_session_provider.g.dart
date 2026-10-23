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

String _$walkSessionHash() => r'c56fe2ed2348527c87645407f1fe1823f45b0610';

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

@ProviderFor(sessionEstimatorComparisons)
final sessionEstimatorComparisonsProvider =
    SessionEstimatorComparisonsFamily._();

final class SessionEstimatorComparisonsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EstimatorComparison>>,
          List<EstimatorComparison>,
          FutureOr<List<EstimatorComparison>>
        >
    with
        $FutureModifier<List<EstimatorComparison>>,
        $FutureProvider<List<EstimatorComparison>> {
  SessionEstimatorComparisonsProvider._({
    required SessionEstimatorComparisonsFamily super.from,
    required (String, {num? heightCm, String? gender}) super.argument,
  }) : super(
         retry: null,
         name: r'sessionEstimatorComparisonsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionEstimatorComparisonsHash();

  @override
  String toString() {
    return r'sessionEstimatorComparisonsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<EstimatorComparison>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EstimatorComparison>> create(Ref ref) {
    final argument = this.argument as (String, {num? heightCm, String? gender});
    return sessionEstimatorComparisons(
      ref,
      argument.$1,
      heightCm: argument.heightCm,
      gender: argument.gender,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionEstimatorComparisonsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionEstimatorComparisonsHash() =>
    r'6130d2b773493fa8311f21f210b37e47c0b2df86';

final class SessionEstimatorComparisonsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<EstimatorComparison>>,
          (String, {num? heightCm, String? gender})
        > {
  SessionEstimatorComparisonsFamily._()
    : super(
        retry: null,
        name: r'sessionEstimatorComparisonsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionEstimatorComparisonsProvider call(
    String sessionId, {
    num? heightCm,
    String? gender,
  }) => SessionEstimatorComparisonsProvider._(
    argument: (sessionId, heightCm: heightCm, gender: gender),
    from: this,
  );

  @override
  String toString() => r'sessionEstimatorComparisonsProvider';
}
