import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:six_minute_walk_test/app/log.dart';

final _log = appLogger('WalkLiveActivityService');

/// Calls the native iOS Live Activity channel without interrupting the test
/// when the feature is unavailable or a platform call fails.
class WalkLiveActivityService {
  static const _channel = MethodChannel('six_minute_walk_test/live_activity');

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> start({
    required DateTime startedAt,
    required DateTime endsAt,
  }) async {
    if (!_isSupportedPlatform) return false;

    try {
      return await _channel.invokeMethod<bool>('start', {
            'startedAt': startedAt.millisecondsSinceEpoch,
            'endsAt': endsAt.millisecondsSinceEpoch,
          }) ??
          false;
    } on PlatformException catch (error, stack) {
      _log.w('Cannot start Live Activity', error: error, stackTrace: stack);
      return false;
    } on MissingPluginException catch (error, stack) {
      _log.w(
        'Live Activity channel is unavailable',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  Future<void> end() async {
    if (!_isSupportedPlatform) return;

    try {
      await _channel.invokeMethod<bool>('end');
    } on PlatformException catch (error, stack) {
      _log.w('Cannot end Live Activity', error: error, stackTrace: stack);
    } on MissingPluginException catch (error, stack) {
      _log.w(
        'Live Activity channel is unavailable',
        error: error,
        stackTrace: stack,
      );
    }
  }
}
