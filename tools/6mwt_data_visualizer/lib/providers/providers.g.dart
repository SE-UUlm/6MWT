// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExportDataNotifier)
final exportDataProvider = ExportDataNotifierProvider._();

final class ExportDataNotifierProvider
    extends $NotifierProvider<ExportDataNotifier, AsyncValue<ExportData?>> {
  ExportDataNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportDataNotifierHash();

  @$internal
  @override
  ExportDataNotifier create() => ExportDataNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ExportData?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ExportData?>>(value),
    );
  }
}

String _$exportDataNotifierHash() =>
    r'87776f638f44f4a0a70a212fffb8b89cfaf6cbff';

abstract class _$ExportDataNotifier extends $Notifier<AsyncValue<ExportData?>> {
  AsyncValue<ExportData?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ExportData?>, AsyncValue<ExportData?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExportData?>, AsyncValue<ExportData?>>,
              AsyncValue<ExportData?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(defaultJsonFiles)
final defaultJsonFilesProvider = DefaultJsonFilesProvider._();

final class DefaultJsonFilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  DefaultJsonFilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultJsonFilesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultJsonFilesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return defaultJsonFiles(ref);
  }
}

String _$defaultJsonFilesHash() => r'd5fc507c7e30d3d5e13d7d55d654c5ff236e2e43';

@ProviderFor(SelectedSession)
final selectedSessionProvider = SelectedSessionProvider._();

final class SelectedSessionProvider
    extends $NotifierProvider<SelectedSession, Session?> {
  SelectedSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedSessionHash();

  @$internal
  @override
  SelectedSession create() => SelectedSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Session? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Session?>(value),
    );
  }
}

String _$selectedSessionHash() => r'79758acddaa49ce2fbf28bd6a58440d99ea9c1ff';

abstract class _$SelectedSession extends $Notifier<Session?> {
  Session? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Session?, Session?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Session?, Session?>,
              Session?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
