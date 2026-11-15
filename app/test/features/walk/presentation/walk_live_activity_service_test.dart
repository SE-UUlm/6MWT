import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/presentation/walk_live_activity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('six_minute_walk_test/live_activity');

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late WalkLiveActivityService service;
  late List<MethodCall> calls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    service = WalkLiveActivityService();
    calls = [];

    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('start sends the session timestamps to iOS', () async {
    final startedAt = DateTime.utc(2026, 11, 15, 10);
    final endsAt = startedAt.add(const Duration(minutes: 6));

    final started = await service.start(startedAt: startedAt, endsAt: endsAt);

    expect(started, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'start');
    expect(calls.single.arguments, {
      'startedAt': startedAt.millisecondsSinceEpoch,
      'endsAt': endsAt.millisecondsSinceEpoch,
    });
  });

  test('end requests removal of the Live Activity', () async {
    await service.end();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'end');
    expect(calls.single.arguments, isNull);
  });

  test('start return false when iOS declines the activity', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => false);

    final started = await service.start(
      startedAt: DateTime.utc(2026, 11, 15, 10),
      endsAt: DateTime.utc(2026, 11, 15, 10, 6),
    );

    expect(started, isFalse);
  });

  test('does not call the iOS channel on Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final started = await service.start(
      startedAt: DateTime.utc(2026, 11, 15, 10),
      endsAt: DateTime.utc(2026, 11, 15, 10, 6),
    );
    await service.end();

    expect(started, isFalse);
    expect(calls, isEmpty);
  });

  test('native start errors return falsee instead of escaping', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'LIVE_ACTIVITY_START_FAILED');
    });

    final started = await service.start(
      startedAt: DateTime.utc(2026, 11, 15, 10),
      endsAt: DateTime.utc(2026, 11, 15, 10, 6),
    );

    expect(started, isFalse);
  });

  test('native end errors do not escape', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'LIVA_ACTIVITY_END_FAILED');
    });

    await expectLater(service.end(), completes);
  });

  test('missing native channel does not interruptthe test', () async {
    messenger.setMockMethodCallHandler(channel, null);

    final started = await service.start(
      startedAt: DateTime.utc(2026, 11, 15, 10),
      endsAt: DateTime.utc(2026, 11, 15, 10, 6),
    );

    expect(started, isFalse);
    await expectLater(service.end(), completes);
  });
}
