import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:six_minute_walk_test/features/walk/presentation/number_format.dart';
import 'package:six_minute_walk_test/l10n/app_localizations.dart';

void main() {
  test('decimals use the separator of the current language', () {
    final de = lookupAppLocalizations(const Locale('de'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(formatDecimal(de, 450.46, 1), '450,5');
    expect(formatDecimal(en, 450.46, 1), '450.5');
    expect(formatDecimal(de, 450, 1), '450,0');
  });
}
