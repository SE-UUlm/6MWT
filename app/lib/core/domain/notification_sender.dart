/// Shows and dismisses local notifications independently of the platform.
abstract interface class NotificationSender {
  /// Shows a notification immediately. Throws if it cannot be shown.
  ///
  /// Reusing [id] replaces the displayed notification with that identifier.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Dismisses the notification identified by [id].
  Future<void> cancel({required int id});
}
