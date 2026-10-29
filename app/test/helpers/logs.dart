import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// Hides all logs for the current test, for tests that trigger error logs on
/// purpose. The previous level is restored when the test ends.
void silenceLogs() {
  final previous = Logger.level;
  Logger.level = Level.off;
  addTearDown(() => Logger.level = previous);
}
