// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metadata_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared by exports and the About screen.

@ProviderFor(appInfo)
final appInfoProvider = AppInfoProvider._();

/// Shared by exports and the About screen.

final class AppInfoProvider
    extends $FunctionalProvider<AsyncValue<AppInfo>, AppInfo, FutureOr<AppInfo>>
    with $FutureModifier<AppInfo>, $FutureProvider<AppInfo> {
  /// Shared by exports and the About screen.
  AppInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInfoHash();

  @$internal
  @override
  $FutureProviderElement<AppInfo> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AppInfo> create(Ref ref) {
    return appInfo(ref);
  }
}

String _$appInfoHash() => r'9e677c8983c2bac2f5da37e47e9cfdfc63b58d50';

@ProviderFor(exportMetadataService)
final exportMetadataServiceProvider = ExportMetadataServiceProvider._();

final class ExportMetadataServiceProvider
    extends
        $FunctionalProvider<
          ExportMetadataService,
          ExportMetadataService,
          ExportMetadataService
        >
    with $Provider<ExportMetadataService> {
  ExportMetadataServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportMetadataServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportMetadataServiceHash();

  @$internal
  @override
  $ProviderElement<ExportMetadataService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExportMetadataService create(Ref ref) {
    return exportMetadataService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportMetadataService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportMetadataService>(value),
    );
  }
}

String _$exportMetadataServiceHash() =>
    r'c1519d6771f6292f8777f6a4e4f7560b51cfdde5';
