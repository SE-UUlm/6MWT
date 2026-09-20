import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:six_mwt_visualizer/app.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VisualizerApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
