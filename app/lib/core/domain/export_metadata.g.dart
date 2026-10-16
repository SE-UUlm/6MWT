// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_metadata.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
