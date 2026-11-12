import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/domain/notification_sender.dart';
import '../core/notifications/local_notification_service.dart';
import '../l10n/app_localizations.dart';

part 'notification_providers.g.dart';

/// Provides the shared notification service with channel metadata localized to the user's preferred locale.
/// The service is initialized lazily on first use.
@Riverpod(keepAlive: true)
LocalNotificationService localNotificationService(Ref ref) {
  final locale = basicLocaleListResolution(
    WidgetsBinding.instance.platformDispatcher.locales,
    const [Locale('en'), Locale('de')],
  );

  final l10n = lookupAppLocalizations(locale);

  return LocalNotificationService(
    channelName: l10n.notificationChannelName,
    channelDescription: l10n.notificationChannelDescription,
  );
}

/// Exposes the notification service through the NotificationSender interface,
/// allowing other parts of the app to show notifications without depending on the concrete implementation.
@Riverpod(keepAlive: true)
NotificationSender notificationSender(Ref ref) {
  return ref.watch(localNotificationServiceProvider);
}
