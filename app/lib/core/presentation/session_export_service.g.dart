// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_export_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionExportService)
final sessionExportServiceProvider = SessionExportServiceProvider._();

final class SessionExportServiceProvider
    extends
        $FunctionalProvider<
          SessionExportService,
          SessionExportService,
          SessionExportService
        >
    with $Provider<SessionExportService> {
  SessionExportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionExportServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionExportServiceHash();

  @$internal
  @override
  $ProviderElement<SessionExportService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionExportService create(Ref ref) {
    return sessionExportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionExportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionExportService>(value),
    );
  }
}

String _$sessionExportServiceHash() =>
    r'95ce4485bfcc7d8e6faf9eb8b497ad13fa824a2b';
