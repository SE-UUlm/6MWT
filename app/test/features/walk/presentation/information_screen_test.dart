import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/features/walk/presentation/information_screen.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> showProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/video',
          builder: (_, _) => const Scaffold(body: Text('Video')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(int index) => find.byType(TextField).at(index);
  String value(WidgetTester tester, int index) =>
      tester.widget<TextField>(field(index)).controller!.text;

  testWidgets('age and height accept only digits; name remains unrestricted', (
    tester,
  ) async {
    await showProfile(tester);
    await tester.enterText(field(0), 'Ada Müller');
    expect(value(tester, 0), 'Ada Müller');
    for (final index in [1, 2]) {
      await tester.enterText(field(index), 'a1b7c0');
      expect(value(tester, index), '170');
      await tester.enterText(field(index), '.,-+');
      expect(value(tester, index), isEmpty);
    }
  });

  testWidgets('weight rejects letters, signs and multiple decimal separators', (
    tester,
  ) async {
    await showProfile(tester);
    await tester.enterText(field(3), '72,5');
    for (final input in ['72kg', '-72', '+72', '7,2,5', '7.2.5', '72,5.0']) {
      await tester.enterText(field(3), input);
      expect(value(tester, 3), '72,5');
    }
    await tester.enterText(field(3), '72,');
    expect(value(tester, 3), '72,');
    await tester.enterText(field(3), '');
    expect(value(tester, 3), isEmpty);
  });

  for (final (index, input, message) in [
    (1, '0', 'Bitte geben Sie ein Alter zwischen 1 und 120 Jahren ein.'),
    (1, '121', 'Bitte geben Sie ein Alter zwischen 1 und 120 Jahren ein.'),
    (2, '49', 'Bitte geben Sie eine Körpergröße zwischen 50 und 250 cm ein.'),
    (2, '251', 'Bitte geben Sie eine Körpergröße zwischen 50 und 250 cm ein.'),
    (3, '0,9', 'Bitte geben Sie ein Gewicht zwischen 1 und 400 kg ein.'),
    (3, '400.1', 'Bitte geben Sie ein Gewicht zwischen 1 und 400 kg ein.'),
    (3, '9' * 400, 'Bitte geben Sie ein Gewicht zwischen 1 und 400 kg ein.'),
  ]) {
    testWidgets('rejects out-of-range input in field $index: $input', (
      tester,
    ) async {
      await showProfile(tester);
      await tester.enterText(field(1), '30');
      await tester.enterText(field(2), '175');
      await tester.enterText(field(3), '72.5');
      await tester.tap(find.text('Weiblich'));
      await tester.enterText(field(index), input);
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(await db.select(db.profiles).get(), isEmpty);
    });
  }

  for (final (age, height, weight) in [(1, 50, 1), (120, 250, 400)]) {
    testWidgets('accepts inclusive limits $age, $height, $weight', (
      tester,
    ) async {
      await showProfile(tester);
      await tester.enterText(field(1), '$age');
      await tester.enterText(field(2), '$height');
      await tester.enterText(field(3), '$weight');
      await tester.tap(find.text('Weiblich'));
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      final profile = await db.select(db.profiles).getSingle();
      expect(profile.age, age);
      expect(profile.height, height);
      expect(profile.weight, weight);
      await tester.pumpAndSettle();
      expect(find.text('Video'), findsOneWidget);
    });
  }

  for (final weight in ['72,5', '72.5']) {
    testWidgets('stores weight $weight as 72.5 and continues', (tester) async {
      await showProfile(tester);
      await tester.enterText(field(1), '30');
      await tester.enterText(field(2), '175');
      await tester.enterText(field(3), weight);
      await tester.tap(find.text('Weiblich'));
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      final profile = await db.select(db.profiles).getSingle();
      expect(profile.age, 30);
      expect(profile.height, 175);
      expect(profile.weight, 72.5);
      expect(profile.gender, Gender.female);
      await tester.pumpAndSettle();
      expect(find.text('Video'), findsOneWidget);
    });
  }
}
