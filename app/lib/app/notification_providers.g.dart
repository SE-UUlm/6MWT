// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the shared notification service with channel metadata localized to the user's preferred locale.
/// The service is initialized lazily on first use.

@ProviderFor(localNotificationService)
final localNotificationServiceProvider = LocalNotificationServiceProvider._();

/// Provides the shared notification service with channel metadata localized to the user's preferred locale.
/// The service is initialized lazily on first use.

final class LocalNotificationServiceProvider
    extends
        $FunctionalProvider<
          LocalNotificationService,
          LocalNotificationService,
          LocalNotificationService
        >
    with $Provider<LocalNotificationService> {
  /// Provides the shared notification service with channel metadata localized to the user's preferred locale.
  /// The service is initialized lazily on first use.
  LocalNotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localNotificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localNotificationServiceHash();

  @$internal
  @override
  $ProviderElement<LocalNotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalNotificationService create(Ref ref) {
    return localNotificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalNotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalNotificationService>(value),
    );
  }
}

String _$localNotificationServiceHash() =>
    r'0317c75de3f590588721b2f96091142974a69d4e';

/// Exposes the notification service through the NotificationSender interface,
/// allowing other parts of the app to show notifications without depending on the concrete implementation.

@ProviderFor(notificationSender)
final notificationSenderProvider = NotificationSenderProvider._();

/// Exposes the notification service through the NotificationSender interface,
/// allowing other parts of the app to show notifications without depending on the concrete implementation.

final class NotificationSenderProvider
    extends
        $FunctionalProvider<
          NotificationSender,
          NotificationSender,
          NotificationSender
        >
    with $Provider<NotificationSender> {
  /// Exposes the notification service through the NotificationSender interface,
  /// allowing other parts of the app to show notifications without depending on the concrete implementation.
  NotificationSenderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSenderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSenderHash();

  @$internal
  @override
  $ProviderElement<NotificationSender> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationSender create(Ref ref) {
    return notificationSender(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationSender value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationSender>(value),
    );
  }
}

String _$notificationSenderHash() =>
    r'84286bfb09ec18cd23859cfff15ce9e38049cf9d';
