import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_mwt_visualizer/core/domain/export_data.dart';
import 'package:six_mwt_visualizer/features/session_detail/session_info_panel.dart';

void main() {
  for (final fullExport in [false, true]) {
    for (final legacy in [false, true]) {
      for (final omitName in [false, true]) {
        testWidgets(
          'profile: full=$fullExport legacy=$legacy omitName=$omitName',
          (tester) async {
            final profile = <String, dynamic>{
              'id': 1,
              if (!omitName) 'name': null,
              'timestamp': '2026-10-19T12:00:00Z',
              'height': 175,
              'age': 30,
              if (!legacy) 'weight': 70,
              if (!legacy) 'gender': 'female',
            };
            final sessionJson = <String, dynamic>{
              'id': 'session-1',
              'startedAt': '2026-10-19T12:00:00Z',
              'duration': 360,
              'distance': 450,
              'phase': 'finished',
              'profileId': 1,
            };
            final data = ExportData.fromJson(
              fullExport
                  ? {
                      'profiles': [profile],
                      'sessions': [sessionJson],
                    }
                  : {...sessionJson, 'profile': profile},
            );
            final session = data.sessions.single;
            final parsed = data.profileForSession(session)!;
            expect(parsed.name, isNull);
            expect(parsed.weight, legacy ? isNull : 70.0);
            expect(parsed.gender, legacy ? isNull : 'female');
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: SessionInfoPanel(
                    session: session.copyWith(profile: parsed),
                  ),
                ),
              ),
            );
            expect(find.text('Not specified'), findsNWidgets(legacy ? 3 : 1));
            expect(find.text('Weight'), findsOneWidget);
            expect(find.text('Gender'), findsOneWidget);
            if (!legacy) {
              expect(find.text('70.0 kg'), findsOneWidget);
              expect(find.text('Female'), findsOneWidget);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
