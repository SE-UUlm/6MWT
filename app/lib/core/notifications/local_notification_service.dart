import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/log.dart';
import '../domain/notification_sender.dart';

final _log = appLogger('LocalNotificationService');

/// Shows and dismisses local notifications on iOS and Android.
///
/// Notifications are shown immediately rather than scheduled ahead of time:
/// the walk test keeps the app running in the background (location
/// foreground service on Android, location background mode on iOS), so the
/// app can post the notification itself when the test ends. This avoids the
/// exact alarm permission on Android.
///
/// Sound follows the device's ringer mode on both platforms. Vibration also
/// happens in silent mode:
/// - Android: the notification channel itself does not vibrate. Instead the
///   app triggers a vibration with alarm usage, which Android also plays in
///   silent and vibrate-only mode.
/// - iOS: the notification sound produces the haptic feedback. In silent mode
///   iOS only vibrates, provided haptics in silent mode are enabled in the
///   system settings (the default).
///
/// Permission requests are separate from showing notifications so a walk can
/// start without opening a permission dialog.
class LocalNotificationService implements NotificationSender {
  LocalNotificationService({
    required this.channelName,
    required this.channelDescription,
  });

  final String channelName;
  final String channelDescription;

  static const _channelId = 'walk_test_end';

  // Earlier channel that vibrated itself. Android keeps channel settings
  // after creation, so it is removed instead of reused.
  static const _legacyChannelIds = ['walk_test_completion'];

  static const _vibrationChannel = MethodChannel(
    'six_minute_walk_test/vibration',
  );

  // Pause, vibrate, pause, vibrate (milliseconds).
  static const _vibrationPattern = [0, 500, 300, 500];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Initializes the notification plugin without requesting permissions.
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
      android: AndroidInitializationSettings('ic_notification_walk'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
    );

    await _plugin.initialize(settings: initialisationSettings);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _android;
      for (final channelId in _legacyChannelIds) {
        await android.deleteNotificationChannel(channelId: channelId);
      }
    }

    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()!;

  IOSFlutterLocalNotificationsPlugin get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()!;

  // Requests notification permission and returns whether notifications are enabled.
  Future<bool> requestNotificationPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _ios;
      await ios.requestPermissions(alert: true, sound: true, badge: false);

      final permissions = await ios.checkPermissions();
      return permissions?.isEnabled == true;
    }

    final android = _android;
    if (await android.areNotificationsEnabled() == true) {
      return true;
    }

    await android.requestNotificationsPermission();

    return await android.areNotificationsEnabled() == true;
  }

  // Shows the notification immediately. On Android the vibration is triggered
  // separately so it also happens in silent mode (see class documentation).
  //
  // Without notification permission only the vibration happens (Android);
  // this is an expected user choice, not an error.
  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      // Vibration does not need the notification permission, so it runs even
      // if the notification itself cannot be shown.
      await _vibrateAndroid();

      if (await _android.areNotificationsEnabled() != true) {
        _log.i('Notifications disabled, only vibrating');
        return;
      }
    } else {
      final permissions = await _ios.checkPermissions();
      if (permissions?.isEnabled != true) {
        _log.i('Notifications disabled, skipping notification');
        return;
      }
    }

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: false,
        ),
        // Only affects presentation while the app is in the foreground: no
        // banner, but the sound (and with it the haptic feedback) still plays.
        // In the background iOS presents the notification according to the
        // user's notification settings.
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBanner: false,
          presentList: false,
          presentSound: true,
          presentBadge: false,
        ),
      ),
    );
  }

  Future<void> _vibrateAndroid() async {
    try {
      await _vibrationChannel.invokeMethod<void>('vibrateAlarm', {
        'pattern': _vibrationPattern,
      });
    } on PlatformException catch (error, stackTrace) {
      // A missing vibration must not prevent the notification.
      _log.w('Vibration failed', error: error, stackTrace: stackTrace);
    }
  }

  // Dismisses the displayed notification identified by [id].
  @override
  Future<void> cancel({required int id}) async {
    await initialize();
    await _plugin.cancel(id: id);
  }
}
