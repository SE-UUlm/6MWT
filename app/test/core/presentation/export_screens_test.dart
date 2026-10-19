import 'package:six_minute_walk_test/core/domain/walk_phase.dart';
import 'package:six_minute_walk_test/app/metadata_providers.dart';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/app/metadata_service.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/providers.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/core/domain/export_metadata.dart';
import 'package:six_minute_walk_test/features/history/history_screen.dart';
import 'package:six_minute_walk_test/features/walk/presentation/result_screen.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

void main() {
  for (final history in [false, true]) {
    for (final unavailable in [false, true]) {
      testWidgets('history=$history, unavailable metadata=$unavailable', (
        tester,
      ) async {
        final db = AppDatabase(NativeDatabase.memory());
        final directory = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('6mwt-export-test'),
        ))!;
        addTearDown(() async {
          await db.close();
          await directory.delete(recursive: true);
        });
        late WalkSessionWithProfile entry;
        await tester.runAsync(() async {
          final profileId = await db
              .into(db.profiles)
              .insert(
                ProfilesCompanion.insert(
                  height: 175,
                  age: 30,
                  gender: Gender.other,
                  weight: 70,
                ),
              );
          final session = WalkSessionRow(
            id: 'session-12345678',
            startedAt: DateTime.utc(2026, 10, 16),
            duration: const Duration(minutes: 6),
            distance: 450,
            phase: WalkPhase.finished,
            profileId: profileId,
          );
          await WalkSessionRepository(db).saveSession(session);
          entry = WalkSessionWithProfile(
            session: session,
            profile: await db.select(db.profiles).getSingle(),
          );
        });
        Map<String, dynamic>? exported;
        final messenger = tester.binding.defaultBinaryMessenger;
        const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
        const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
        messenger.setMockMethodCallHandler(
          pathChannel,
          (_) async => directory.path,
        );
        messenger.setMockMethodCallHandler(shareChannel, (call) async {
          final path = (call.arguments['paths'] as List).single as String;
          exported =
              jsonDecode(await File(path).readAsString())
                  as Map<String, dynamic>;
          return 'test-share';
        });
        addTearDown(() {
          messenger.setMockMethodCallHandler(pathChannel, null);
          messenger.setMockMethodCallHandler(shareChannel, null);
        });
        final appInfo = AppInfoService(
          loadPackageInfo: () async => throw MissingPluginException(),
          loadCommitHash: () async => unavailable ? null : 'test-commit',
        );
        final deviceInfo = DeviceInfoService(
          operatingSystem: 'android',
          loadAndroidInfo: () async => throw MissingPluginException(),
          loadAndroidId: () async {
            if (unavailable) throw PlatformException(code: 'unavailable');
            return 'test-id';
          },
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              exportMetadataServiceProvider.overrideWithValue(
                ExportMetadataService(
                  loadAppInfo: appInfo.load,
                  loadDeviceInfo: deviceInfo.load,
                ),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: history
                  ? const HistoryScreen()
                  : ResultScreen(session: entry),
            ),
          ),
        );
        await tester.runAsync(() async {
          await tester.tap(find.byIcon(Icons.share));
          for (var attempt = 0; attempt < 100 && exported == null; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        expect(exported, isNotNull);
        expect(
          exported!['deviceInfo']['deviceId'],
          unavailable ? null : 'test-id',
        );
        expect(
          exported!['appInfo']['commitHash'],
          unavailable ? null : 'test-commit',
        );
        expect(exported!['appInfo']['version'], isNull);
        final session = history
            ? (exported!['sessions'] as List).single
            : exported!;
        expect(session['id'], entry.session.id);
        expect(session['distance'], 450);
        expect(session['samples'], isEmpty);
        final profile = history
            ? (exported!['profiles'] as List).single
            : exported!['profile'];
        expect(profile['name'], isNull);
        expect(profile['weight'], 70);
        expect(profile['gender'], 'other');
        expect(exported!['exportedAt'], endsWith('Z'));
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
      });
    }
  }
}
