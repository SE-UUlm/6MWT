import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/core/data/database.dart';
import 'package:six_minute_walk_test/core/data/walk_session_repository.dart';
import 'package:six_minute_walk_test/features/walk/presentation/result_screen.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

void main() {
  for (final (gender, label, weight, weightLabel) in [
    (Gender.male, 'Männlich', 75.0, '75 kg'),
    (Gender.female, 'Weiblich', 62.5, '62,5 kg'),
    (Gender.other, 'Divers/Keine Angabe', 0.0, '0 kg'),
  ]) {
    testWidgets('shows $label and $weightLabel in profile details', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ResultScreen(
              session: WalkSessionWithProfile(
                session: WalkSessionRow(
                  id: 'test',
                  startedAt: DateTime.utc(2026),
                  duration: const Duration(minutes: 6),
                  distance: 450,
                  phase: WalkPhase.finished,
                  profileId: 1,
                ),
                profile: Profile(
                  id: 1,
                  timestamp: DateTime.utc(2026),
                  height: 170,
                  age: 30,
                  gender: gender,
                  weight: weight,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text(weightLabel));
      await tester.pumpAndSettle();
      expect(find.text(weightLabel), findsOneWidget);
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
