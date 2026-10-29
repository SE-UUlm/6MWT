import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

// Formats [value] with a fixed number of [decimals] and the decimal separator
// of the current language, e.g. "450,5" in German and "450.5" in English.
String formatDecimal(AppLocalizations l10n, double value, int decimals) =>
    NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: decimals,
    ).format(value);
