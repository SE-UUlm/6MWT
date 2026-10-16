import 'dart:async';

import 'package:logger/logger.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Keep errors and fatal messages visible while suppressing routine test logs.
  Logger.level = Level.error;
  await testMain();
}
