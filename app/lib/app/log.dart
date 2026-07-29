import 'package:logger/logger.dart';

/// App-wide logger factory.
///
/// Usage:
/// ```dart
/// import 'package:six_minute_walk_test/app/log.dart';
///
/// final _log = appLogger('MyClass');
/// _log.d('debug info');
/// _log.w('warning');
/// _log.e('error', error: exception, stackTrace: stack);
/// ```
Logger appLogger(String tag) => Logger(
  printer: PrefixPrinter(
    PrettyPrinter(),
    debug: '[$tag]',
    info: '[$tag]',
    warning: '[$tag]',
    error: '[$tag]',
    fatal: '[$tag]',
    trace: '[$tag]',
  ),
  filter: DevelopmentFilter(),
);
