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

  /// No description provided for @home_walk.
  ///
  /// In de, this message translates to:
  /// **'Gehen'**
  String get home_walk;

  /// No description provided for @home_walksb.
  ///
  /// In de, this message translates to:
  /// **'So weit wie möglich in 6 Minuten gehen'**
  String get home_walksb;

  /// No description provided for @home_performance.
  ///
  /// In de, this message translates to:
  /// **'Leistung'**
  String get home_performance;

  /// No description provided for @home_performancesb.
  ///
  /// In de, this message translates to:
  /// **'Deine Ausdauer objektiv messen'**
  String get home_performancesb;

  /// No description provided for @home_progress.
  ///
  /// In de, this message translates to:
  /// **'Fortschritt'**
  String get home_progress;

  /// No description provided for @home_progresssb.
  ///
  /// In de, this message translates to:
  /// **'Ergebnisse vergleichen'**
  String get home_progresssb;

  /// No description provided for @home_result.
  ///
  /// In de, this message translates to:
  /// **'Meine Ergebnisse'**
  String get home_result;

  /// No description provided for @home_resultsb.
  ///
  /// In de, this message translates to:
  /// **'Frühere Tests ansehen'**
  String get home_resultsb;

  /// No description provided for @home_instruction.
  ///
  /// In de, this message translates to:
  /// **'Über den 6 Minuten Test'**
  String get home_instruction;

  /// No description provided for @home_instructionsb.
  ///
  /// In de, this message translates to:
  /// **'Ausführliche Anleitung'**
  String get home_instructionsb;

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

  /// No description provided for @profile_title.
  ///
  /// In de, this message translates to:
  /// **'Vorkalibrierung'**
  String get profile_title;

  /// No description provided for @profile_text.
  ///
  /// In de, this message translates to:
  /// **'Um möglichst genaue Testergebnisse zu erhalten, geben Sie bitte alle Informationen korrekt ein'**
  String get profile_text;

  /// No description provided for @profile_sub1.
  ///
  /// In de, this message translates to:
  /// **'Patienteninformationen'**
  String get profile_sub1;

  /// No description provided for @profile_sub2.
  ///
  /// In de, this message translates to:
  /// **'Anthropometrie'**
  String get profile_sub2;

  /// No description provided for @profile_info.
  ///
  /// In de, this message translates to:
  /// **'Bitte füllen Sie Alter und Körpergröße aus.'**
  String get profile_info;

  /// No description provided for @field1.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get field1;

  /// No description provided for @field2.
  ///
  /// In de, this message translates to:
  /// **'Alter in Jahren'**
  String get field2;

  /// No description provided for @field3_1.
  ///
  /// In de, this message translates to:
  /// **'Männlich'**
  String get field3_1;

  /// No description provided for @field3_2.
  ///
  /// In de, this message translates to:
  /// **'Weiblich'**
  String get field3_2;

  /// No description provided for @field4.
  ///
  /// In de, this message translates to:
  /// **'Höhe'**
  String get field4;

  /// No description provided for @field5.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get field5;

  /// No description provided for @profile_footer.
  ///
  /// In de, this message translates to:
  /// **'Ihre Privatsphäre ist uns wichtig. Diese Informationen werden für keine anderen Zwecke verwendet.'**
  String get profile_footer;

  /// No description provided for @video_title.
  ///
  /// In de, this message translates to:
  /// **'Testvorbereitung'**
  String get video_title;

  /// No description provided for @video_text.
  ///
  /// In de, this message translates to:
  /// **'Gehen Sie die markierte Strecke (z. B. 6 Meter) in der Mitte beginnend hin und her. Gehen Sie in Ihrem eigenen Tempo. Wenn Sie unsicher sind, wie der Test abläuft, sehen Sie sich zur Orientierung das untenstehende Video an.'**
  String get video_text;

  /// No description provided for @walk_info.
  ///
  /// In de, this message translates to:
  /// **'Bitte lege in 6 Minuten eine möglichst große Strecke zurück.'**
  String get walk_info;

  /// No description provided for @walk_idstance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get walk_idstance;

  /// No description provided for @walk_status.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get walk_status;

  /// No description provided for @walk_assessment.
  ///
  /// In de, this message translates to:
  /// **'Bewertung'**
  String get walk_assessment;

  /// No description provided for @walk_start.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gestartet'**
  String get walk_start;

  /// No description provided for @walk_position.
  ///
  /// In de, this message translates to:
  /// **'Aktuelle Position'**
  String get walk_position;

  /// No description provided for @walk_duration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get walk_duration;

  /// No description provided for @walk_profile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get walk_profile;

  /// No description provided for @walk_test_start.
  ///
  /// In de, this message translates to:
  /// **'Starte Test'**
  String get walk_test_start;

  /// No description provided for @walk_reset.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get walk_reset;
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
