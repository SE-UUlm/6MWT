import 'package:six_minute_walk_test/core/notifications/local_notification_service.dart';

/// Replaces the notification plugin, which is not available in widget tests.
///
/// Reports a configurable permission state and records every call.
class FakeNotificationService extends LocalNotificationService {
  FakeNotificationService({this.enabled = true, this.failing = false})
    : super(channelName: 'test', channelDescription: 'test');

  bool enabled;
  final bool failing;

  int permissionRequests = 0;
  int checks = 0;
  final List<String> shownTitles = [];
  final List<int> cancelledIds = [];

  @override
  Future<bool> requestNotificationPermission() async {
    permissionRequests++;
    return areNotificationsEnabled();
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    checks++;
    if (failing) {
      throw StateError('check failed');
    }
    return enabled;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    shownTitles.add(title);
  }

  @override
  Future<void> cancel({required int id}) async {
    cancelledIds.add(id);
  }
}
