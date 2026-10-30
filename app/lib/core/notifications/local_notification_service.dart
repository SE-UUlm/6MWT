import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_scheduler.dart';

class LocalNotificationService implements NotificationScheduler {
  LocalNotificationService({
    required this.channelName,
    required this.channelDescription,
  });

  final String channelName;
  final String channelDescription;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError(
        'Local notifications are currently supported only on iOS and Android.',
      );
    }

    if (_initialized) return;

    const initialisationSettings = InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ), //TODO: richtiges icon wählen
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
    );

    final initialized = await _plugin.initialize(
      settings: initialisationSettings,
    );

    if (initialized != true) {
      throw StateError('Notification initialization failed.');
    }

    _initialized = true;
  }

  Future<bool> requestNotificationPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()!;

      await ios.requestPermissions(alert: true, sound: true, badge: false);

      final permissions = await ios.checkPermissions();
      return permissions?.isEnabled == true;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;

    if (await android.areNotificationsEnabled() == true) {
      return true;
    }

    await android.requestNotificationsPermission();

    return await android.areNotificationsEnabled() == true;
  }

  Future<bool> canSchedulePrecisely() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;

    return await android.canScheduleExactNotifications() == true;
  }

  Future<bool> requestPreciseSchedulingPermission() async {
    await initialize();

    if (await canSchedulePrecisely()) {
      return true;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;

    await android.requestExactAlarmsPermission();

    return await android.canScheduleExactNotifications() == true;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!;

      if (await android.areNotificationsEnabled() != true) {
        throw StateError('Notification permission is missing.');
      }

      if (await android.canScheduleExactNotifications() != true) {
        throw StateError('Exact alarm permission is missing.');
      }
    } else {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()!;

      final permissions = await ios.checkPermissions();

      if (permissions?.isEnabled != true) {
        throw StateError('Notification permission is missing.');
      }
    }

    if (!scheduledAt.isAfter(DateTime.now())) {
      throw ArgumentError.value(
        scheduledAt,
        'scheduledAt',
        'Must be in the future.',
      );
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.UTC),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'walk_test_completion',
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          presentBadge: false,
        ),
      ),
    );
  }

  @override
  Future<void> cancel({required int id}) async {
    await initialize();
    await _plugin.cancel(id: id);
  }
}
