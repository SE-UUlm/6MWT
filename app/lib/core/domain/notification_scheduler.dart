/// Schedules and cancels local notifications independently of the platform.
abstract interface class NotificationScheduler {
  /// Completes when scheduling succeeds. Throws if scheduling fails.
  ///
  /// [scheduledAt] must be in the future.
  /// Reusing [id] replaces the pending notification with that identifier.
  Future<void> schedule({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
    String? payload,
  });

  /// Cancels the notification identified by [id].
  Future<void> cancel({required int id});
}
