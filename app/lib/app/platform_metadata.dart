import 'package:flutter/services.dart';

import 'log.dart';

final _log = appLogger('PlatformMetadata');

Future<T?> readMetadata<T>(String label, Future<T> Function() read) async {
  try {
    return await read();
  } catch (error, stack) {
    _log.w('Could not read $label', error: error, stackTrace: stack);
    return null;
  }
}

class PlatformMetadata {
  static const channel = MethodChannel(
    'six_minute_walk_test/platform_metadata',
  );

  static Future<String?> getCommitHash() =>
      channel.invokeMethod<String>('getCommitHash');

  static Future<String?> getAndroidId() =>
      channel.invokeMethod<String>('getAndroidId');
}
