import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:six_minute_walk_test/app/app.dart';

void main() {
  testWidgets('home screen offers navigation to the walking test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SixMinuteWalkApp()));

    expect(find.text('6-Minute Walk Test'), findsOneWidget);
    expect(find.text('Start test'), findsOneWidget);
    expect(find.text('Meine Ergebnisse'), findsOneWidget);
  });

  testWidgets('clicking start test leads to the patient information screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SixMinuteWalkApp()));

    await tester.tap(find.text('Start test'));
    await tester.pumpAndSettle();

    expect(find.text('Vorkalibrierung'), findsOneWidget);
    expect(find.text('Patienteninformationen'), findsOneWidget);
  });
}
