/// Shows and dismisses local notifications independently of the platform.
abstract interface class NotificationSender {
  /// Shows a notification immediately.
  ///
  /// Completes without showing anything if the user has disabled
  /// notifications. Throws if showing fails for another reason.
  ///
  /// Reusing [id] replaces the displayed notification with that identifier.
  Future<void> show({
    required int id,
    required String title,
    required String body,
  });

  /// Dismisses the notification identified by [id].
  Future<void> cancel({required int id});
}
