import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'6-Minuten-Gehtest'**
  String get appTitle;

  /// No description provided for @appSubTitle.
  ///
  /// In de, this message translates to:
  /// **'Standardisierte Beurteilung der funktionellen Belastbarkeit'**
  String get appSubTitle;

  /// No description provided for @appProfile.
  ///
  /// In de, this message translates to:
  /// **'Einrichtung des Patientenprofils'**
  String get appProfile;

  /// No description provided for @appCountdown.
  ///
  /// In de, this message translates to:
  /// **'6-Minuten-Countdown'**
  String get appCountdown;

  /// No description provided for @appResult.
  ///
  /// In de, this message translates to:
  /// **'Ergebnisse und Werte'**
  String get appResult;

  /// No description provided for @startTest.
  ///
  /// In de, this message translates to:
  /// **'Test starten'**
  String get startTest;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @continueButton.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get continueButton;

  /// No description provided for @instructions.
  ///
  /// In de, this message translates to:
  /// **'Anleitung'**
  String get instructions;

  /// No description provided for @instructions_1_welc.
  ///
  /// In de, this message translates to:
  /// **'Willkommen'**
  String get instructions_1_welc;

  /// No description provided for @instructions_1_text.
  ///
  /// In de, this message translates to:
  /// **'Diese App führt Sie Schritt für Schritt durch den 6-Minuten-Gehtest (6MWT). Der Test hilft dabei, Ihre körperliche Leistungsfähigkeit anhand der in sechs Minuten zurückgelegten Strecke zu beurteilen.'**
  String get instructions_1_text;

  /// No description provided for @instructions_2_welc.
  ///
  /// In de, this message translates to:
  /// **'Testverfahren'**
  String get instructions_2_welc;

  /// No description provided for @bulletPoint_1.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Daten eingeben'**
  String get bulletPoint_1;

  /// No description provided for @bulletPoint_2.
  ///
  /// In de, this message translates to:
  /// **'Test starten'**
  String get bulletPoint_2;

  /// No description provided for @bulletPoint_3.
  ///
  /// In de, this message translates to:
  /// **'Gehen Sie 6 Minuten lang'**
  String get bulletPoint_3;

  /// No description provided for @bulletPoint_4.
  ///
  /// In de, this message translates to:
  /// **'Ergebnisse'**
  String get bulletPoint_4;

  /// No description provided for @instructions_2_text.
  ///
  /// In de, this message translates to:
  /// **'Der Test dauert nur sechs Minuten. Während dieser Zeit misst die App die zurückgelegte Strecke und die verbleibende Zeit.'**
  String get instructions_2_text;

  /// No description provided for @instructions_3_welc.
  ///
  /// In de, this message translates to:
  /// **'Personenbezogene Daten'**
  String get instructions_3_welc;

  /// No description provided for @instructions_3_text.
  ///
  /// In de, this message translates to:
  /// **'Für eine möglichst präzise Analyse benötigen wir einige Angaben wie Alter, Körpergröße, Gewicht und Geschlecht. Diese Daten dienen dazu, Ihre Ergebnisse besser einordnen zu können.'**
  String get instructions_3_text;

  /// No description provided for @instructions_4_welc.
  ///
  /// In de, this message translates to:
  /// **'Während des Tests'**
  String get instructions_4_welc;

  /// No description provided for @instructions_4_text.
  ///
  /// In de, this message translates to:
  /// **'Gehen Sie sechs Minuten lang in Ihrem normalen, zügigen Tempo. Die App zeigt die verbleibende Zeit und die bereits zurückgelegte Strecke an.'**
  String get instructions_4_text;

  /// No description provided for @instructions_4_text_2.
  ///
  /// In de, this message translates to:
  /// **'Brechen Sie den Test ab, wenn bei Ihnen Brustschmerzen, Schwindel oder starke Atemnot auftreten.'**
  String get instructions_4_text_2;

  /// No description provided for @instructions_5_welc.
  ///
  /// In de, this message translates to:
  /// **'Den Test abbrechen'**
  String get instructions_5_welc;

  /// No description provided for @instructions_5_text.
  ///
  /// In de, this message translates to:
  /// **'Bei Bedarf können Sie den Test jederzeit abbrechen und anschließend entscheiden, wie Sie fortfahren möchten:'**
  String get instructions_5_text;

  /// No description provided for @instructions_5_c1.
  ///
  /// In de, this message translates to:
  /// **'Zwischenergebnisse werden gespeichert'**
  String get instructions_5_c1;

  /// No description provided for @instructions_5_c2.
  ///
  /// In de, this message translates to:
  /// **'Die Ergebnisse werden angezeigt'**
  String get instructions_5_c2;

  /// No description provided for @instructions_5_c3.
  ///
  /// In de, this message translates to:
  /// **'Der Informationswert mag begrenzt sein'**
  String get instructions_5_c3;

  /// No description provided for @instructions_5_f1.
  ///
  /// In de, this message translates to:
  /// **'Alle bisherigen Daten werden verworfen'**
  String get instructions_5_f1;

  /// No description provided for @instructions_5_f2.
  ///
  /// In de, this message translates to:
  /// **'Sie können den Test erneut starten'**
  String get instructions_5_f2;

  /// No description provided for @instructions_6_welc.
  ///
  /// In de, this message translates to:
  /// **'Übersicht der Ergebnisse'**
  String get instructions_6_welc;

  /// No description provided for @instructions_6_text.
  ///
  /// In de, this message translates to:
  /// **'Your walking distance is classified based on reference values and you get an overview of your performance and values reached.'**
  String get instructions_6_text;

  /// No description provided for @instructions_7_welc.
  ///
  /// In de, this message translates to:
  /// **'Sie sind bereit!'**
  String get instructions_7_welc;

  /// No description provided for @instructions_7_text.
  ///
  /// In de, this message translates to:
  /// **'Jetzt, da Sie wissen, wie es funktioniert, können Sie jederzeit einen Test starten und abschließen!'**
  String get instructions_7_text;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
