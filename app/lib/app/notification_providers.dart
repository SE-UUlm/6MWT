import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/domain/notification_scheduler.dart';
import '../core/notifications/local_notification_service.dart';
import '../l10n/app_localizations.dart';

part 'notification_providers.g.dart';

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

@Riverpod(keepAlive: true)
NotificationScheduler notificationScheduler(Ref ref) {
  return ref.watch(localNotificationServiceProvider);
}
