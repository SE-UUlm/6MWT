import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:six_minute_walk_test/app/app.dart';

void main() {
  testWidgets('home screen offers navigation to the walking test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SixMinuteWalkApp()));

    expect(find.text('Six Minute Walk Test'), findsOneWidget);
    expect(find.text('Start Walking Test'), findsOneWidget);
    expect(find.text('GPS Debug'), findsOneWidget);
  });

  testWidgets('navigating to the walking test shows the test screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SixMinuteWalkApp()));

    await tester.tap(find.text('Start Walking Test'));
    await tester.pumpAndSettle();

    expect(find.text('Walking Test'), findsOneWidget);
    expect(find.text('06:00'), findsOneWidget);
    expect(find.text('Start Test'), findsOneWidget);
  });
}
