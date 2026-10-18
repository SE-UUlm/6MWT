import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/app/router.dart';
import 'package:six_minute_walk_test/core/domain/app_info.dart';
import 'package:six_minute_walk_test/features/about/about_screen.dart';
import 'package:six_minute_walk_test/features/home/home_screen.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

const buildInfo = AppInfo(
  version: '2.1.0',
  buildNumber: '42',
  commitHash: '0123456789abcdef0123456789abcdef01234567',
);

Future<void> scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  Future<void> showAbout(
    WidgetTester tester, {
    Future<AppInfo> Function()? load,
    String language = 'en',
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appInfoProvider.overrideWith(
            (ref) => load?.call() ?? Future.value(buildInfo),
          ),
        ],
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const AboutScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('home info button opens the real about route and returns', (
    tester,
  ) async {
    router.go('/');
    addTearDown(() => router.go('/'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appInfoProvider.overrideWith((ref) async => buildInfo)],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('About the app'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('2.1.0'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  for (final language in ['de', 'en']) {
    testWidgets('shows build metadata and project details in $language', (
      tester,
    ) async {
      await showAbout(tester, language: language);
      expect(
        find.text(language == 'de' ? 'Über die App' : 'About the app'),
        findsOneWidget,
      );
      expect(find.text('2.1.0'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('01234567'), findsOneWidget);
      expect(
        find.textContaining(
          language == 'de' ? 'Universität Ulm' : 'Ulm University',
        ),
        findsOneWidget,
      );
      await scrollTo(tester, find.textContaining('Moritz Beck'));
      expect(find.textContaining('Lea-Marie Kindermann'), findsOneWidget);
      expect(find.textContaining('lucamariej'), findsOneWidget);
      await scrollTo(tester, find.text('GPL-3.0-or-later'));
      expect(find.text(AboutScreen.repositoryUri.toString()), findsOneWidget);
    });
  }

  testWidgets('loading leaves project information accessible', (tester) async {
    final pending = Completer<AppInfo>();
    await showAbout(tester, load: () => pending.future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Ulm University'), findsOneWidget);
    pending.complete(buildInfo);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('2.1.0'), findsOneWidget);
  });

  testWidgets('missing and empty metadata have localized fallbacks', (
    tester,
  ) async {
    await showAbout(
      tester,
      language: 'de',
      load: () async => const AppInfo(version: '', buildNumber: ' '),
    );
    expect(find.text('Nicht verfügbar'), findsNWidgets(3));
  });

  testWidgets('missing commit preserves available version and build', (
    tester,
  ) async {
    await showAbout(
      tester,
      load: () async => const AppInfo(version: '2.1.0', buildNumber: '42'),
    );
    expect(find.text('2.1.0'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
  });

  testWidgets('provider failure keeps the page usable', (tester) async {
    await showAbout(tester, load: () async => throw StateError('unavailable'));
    expect(find.text('Not available'), findsNWidgets(3));
    expect(find.textContaining('Ulm University'), findsOneWidget);
  });

  for (final outcome in ['success', 'false', 'exception']) {
    testWidgets('repository launch handles $outcome', (tester) async {
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (outcome == 'exception') throw PlatformException(code: 'failed');
        return outcome == 'success';
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await showAbout(tester);
      final link = find.widgetWithText(TextButton, 'GitHub repository');
      await scrollTo(tester, link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      expect(calls.single.method, 'launch');
      expect(calls.single.arguments['url'], 'https://github.com/SE-UUlm/6MWT');
      expect(calls.single.arguments['useSafariVC'], false);
      expect(calls.single.arguments['useWebView'], false);
      expect(
        find.text('The link could not be opened.'),
        outcome == 'success' ? findsNothing : findsOneWidget,
      );
    });
  }

  testWidgets('licenses open and return to about', (tester) async {
    await showAbout(tester);
    final licenses = find.widgetWithText(TextButton, 'Open-source licenses');
    await scrollTo(tester, licenses);
    await tester.tap(licenses);
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
  });

  testWidgets('narrow screen and large text keep all content reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showAbout(tester, language: 'de', textScale: 2);
    await scrollTo(tester, find.text('01234567'));
    expect(tester.takeException(), isNull);
    await scrollTo(
      tester,
      find.widgetWithText(TextButton, 'Open-Source-Lizenzen'),
    );
    expect(tester.takeException(), isNull);
  });
}
