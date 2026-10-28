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
  /// **'Über den 6-Minuten-Test'**
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
  /// **'Kurzanleitung lesen'**
  String get bulletPoint_2;

  /// No description provided for @bulletPoint_3.
  ///
  /// In de, this message translates to:
  /// **'Test starten'**
  String get bulletPoint_3;

  /// No description provided for @bulletPoint_4.
  ///
  /// In de, this message translates to:
  /// **'6 Minuten gehen'**
  String get bulletPoint_4;

  /// No description provided for @bulletPoint_5.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis ansehen'**
  String get bulletPoint_5;

  /// No description provided for @instructions_2_text.
  ///
  /// In de, this message translates to:
  /// **'Der Test dauert nur sechs Minuten. Während dieser Zeit misst die App die zurückgelegte Strecke und die verbleibende Zeit.'**
  String get instructions_2_text;

  /// No description provided for @instructions_3_text.
  ///
  /// In de, this message translates to:
  /// **'Um Ihre Fitness bewerten zu können, benötigen wir einige Angaben wie Alter, Geschlecht, Körpergröße und Gewicht. Ihre Gehstrecke wird dann mit Referenzwerten von Menschen mit ähnlichem Profil verglichen.'**
  String get instructions_3_text;

  /// No description provided for @instructions_3_range.
  ///
  /// In de, this message translates to:
  /// **'Die Referenzwerte gelten für Erwachsene zwischen 40 und 100 Jahren mit einer Körpergröße von 150 bis 210 cm. Außerhalb dieser Bereiche ist die Bewertung weniger aussagekräftig.'**
  String get instructions_3_range;

  /// No description provided for @instructions_4_welc.
  ///
  /// In de, this message translates to:
  /// **'Während des Tests'**
  String get instructions_4_welc;

  /// No description provided for @instructions_4_outdoor.
  ///
  /// In de, this message translates to:
  /// **'Gehen Sie nach draußen auf eine ebene Strecke ohne Gefälle und ohne Hindernisse wie Ampeln oder Treppen.'**
  String get instructions_4_outdoor;

  /// No description provided for @instructions_4_pocket.
  ///
  /// In de, this message translates to:
  /// **'Stecken Sie das Handy nach dem Start in die Tasche – so wird am genauesten gemessen.'**
  String get instructions_4_pocket;

  /// No description provided for @instructions_4_walk.
  ///
  /// In de, this message translates to:
  /// **'Gehen Sie 6 Minuten lang so weit wie möglich – gehen, nicht rennen.'**
  String get instructions_4_walk;

  /// No description provided for @instructions_4_timer.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Bildschirm sehen Sie, wie viel Zeit noch übrig ist.'**
  String get instructions_4_timer;

  /// No description provided for @instructions_4_pause.
  ///
  /// In de, this message translates to:
  /// **'Sie dürfen langsamer werden oder stehen bleiben, wenn Sie eine Pause brauchen.'**
  String get instructions_4_pause;

  /// No description provided for @instructions_5_welc.
  ///
  /// In de, this message translates to:
  /// **'Ihre Sicherheit'**
  String get instructions_5_welc;

  /// No description provided for @instructions_5_text.
  ///
  /// In de, this message translates to:
  /// **'Ihre Gesundheit geht vor. Brechen Sie den Test sofort ab, wenn eines dieser Anzeichen auftritt:'**
  String get instructions_5_text;

  /// No description provided for @instructions_5_chest.
  ///
  /// In de, this message translates to:
  /// **'Brustschmerzen'**
  String get instructions_5_chest;

  /// No description provided for @instructions_5_dizzy.
  ///
  /// In de, this message translates to:
  /// **'Schwindel'**
  String get instructions_5_dizzy;

  /// No description provided for @instructions_5_breath.
  ///
  /// In de, this message translates to:
  /// **'Starke Atemnot'**
  String get instructions_5_breath;

  /// No description provided for @instructions_5_doctor.
  ///
  /// In de, this message translates to:
  /// **'Wenn Sie an einer Herz- oder Lungenerkrankung leiden oder unsicher sind, ob der Test für Sie geeignet ist, sprechen Sie vorher mit Ihrer Ärztin oder Ihrem Arzt.'**
  String get instructions_5_doctor;

  /// No description provided for @instructions_6_welc.
  ///
  /// In de, this message translates to:
  /// **'Übersicht der Ergebnisse'**
  String get instructions_6_welc;

  /// No description provided for @instructions_6_text.
  ///
  /// In de, this message translates to:
  /// **'Ihre Gehstrecke wird mit Referenzwerten von Menschen gleichen Alters und gleicher Körpergröße verglichen. Sie sehen, wie viel Prozent der erwarteten Strecke Sie erreicht haben und in welche Kategorie Sie fallen:'**
  String get instructions_6_text;

  /// No description provided for @instructions_7_welc.
  ///
  /// In de, this message translates to:
  /// **'Sie sind bereit!'**
  String get instructions_7_welc;

  /// No description provided for @instructions_7_text.
  ///
  /// In de, this message translates to:
  /// **'Sie wissen jetzt alles, was Sie für den Test brauchen. Suchen Sie sich eine ebene Strecke im Freien und legen Sie los!'**
  String get instructions_7_text;

  /// No description provided for @instructions_7_back.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Kurzanleitung'**
  String get instructions_7_back;

  /// No description provided for @instructions_7_home.
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Startbildschirm'**
  String get instructions_7_home;

  /// No description provided for @profile_title.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Daten'**
  String get profile_title;

  /// No description provided for @profile_text.
  ///
  /// In de, this message translates to:
  /// **'Um möglichst genaue Testergebnisse zu erhalten, geben Sie bitte alle Informationen korrekt ein.'**
  String get profile_text;

  /// No description provided for @profile_sub1.
  ///
  /// In de, this message translates to:
  /// **'Allgemeine Angaben'**
  String get profile_sub1;

  /// No description provided for @profile_sub2.
  ///
  /// In de, this message translates to:
  /// **'Körpermaße'**
  String get profile_sub2;

  /// No description provided for @profile_info.
  ///
  /// In de, this message translates to:
  /// **'Bitte füllen Sie Alter, Geschlecht, Körpergröße und Gewicht aus.'**
  String get profile_info;

  /// No description provided for @profileAgeOutOfRange.
  ///
  /// In de, this message translates to:
  /// **'Bitte geben Sie ein Alter zwischen 1 und 120 Jahren ein.'**
  String get profileAgeOutOfRange;

  /// No description provided for @profileHeightOutOfRange.
  ///
  /// In de, this message translates to:
  /// **'Bitte geben Sie eine Körpergröße zwischen 50 und 250 cm ein.'**
  String get profileHeightOutOfRange;

  /// No description provided for @profileWeightOutOfRange.
  ///
  /// In de, this message translates to:
  /// **'Bitte geben Sie ein Gewicht zwischen 1 und 400 kg ein.'**
  String get profileWeightOutOfRange;

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

  /// No description provided for @genderMale.
  ///
  /// In de, this message translates to:
  /// **'Männlich'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In de, this message translates to:
  /// **'Weiblich'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In de, this message translates to:
  /// **'Divers/Keine Angabe'**
  String get genderOther;

  /// No description provided for @field4.
  ///
  /// In de, this message translates to:
  /// **'Körpergröße'**
  String get field4;

  /// No description provided for @field5.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get field5;

  /// No description provided for @profile_footer.
  ///
  /// In de, this message translates to:
  /// **'Ihre Privatsphäre ist uns wichtig. Diese Informationen werden ausschließlich zur Bewertung Ihrer Fitness verwendet und nicht für andere Zwecke.'**
  String get profile_footer;

  /// No description provided for @quickGuide_title.
  ///
  /// In de, this message translates to:
  /// **'So funktioniert’s'**
  String get quickGuide_title;

  /// No description provided for @quickGuide_step_outdoor.
  ///
  /// In de, this message translates to:
  /// **'Gehen Sie nach draußen auf einen ebenen Weg.'**
  String get quickGuide_step_outdoor;

  /// No description provided for @quickGuide_step_pocket.
  ///
  /// In de, this message translates to:
  /// **'Starten Sie den Test und stecken Sie das Handy in die Tasche – so wird am genauesten gemessen.'**
  String get quickGuide_step_pocket;

  /// No description provided for @quickGuide_step_walk.
  ///
  /// In de, this message translates to:
  /// **'Gehen Sie 6 Minuten lang so weit wie möglich – gehen, nicht rennen. Pausen sind erlaubt.'**
  String get quickGuide_step_walk;

  /// No description provided for @quickGuide_step_end.
  ///
  /// In de, this message translates to:
  /// **'Ein Ton und eine Vibration signalisieren das Ende des Tests.'**
  String get quickGuide_step_end;

  /// No description provided for @quickGuide_more_info.
  ///
  /// In de, this message translates to:
  /// **'Mehr Informationen zum Test'**
  String get quickGuide_more_info;

  /// No description provided for @quickGuide_disclaimer.
  ///
  /// In de, this message translates to:
  /// **'Die Durchführung des Tests erfolgt auf eigene Verantwortung. Wenn Sie an einer Herz- oder Lungenerkrankung leiden oder unsicher sind, ob der Test für Sie geeignet ist, sprechen Sie vorher mit Ihrer Ärztin oder Ihrem Arzt. Brechen Sie den Test sofort ab, wenn Brustschmerzen, Schwindel oder starke Atemnot auftreten.'**
  String get quickGuide_disclaimer;

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

  /// No description provided for @walkPleaseGoFar.
  ///
  /// In de, this message translates to:
  /// **'Bitte legen Sie in 6 Minuten eine möglichst große Strecke zurück.'**
  String get walkPleaseGoFar;

  /// No description provided for @walkNotStarted.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gestartet'**
  String get walkNotStarted;

  /// No description provided for @walkWaitingForGps.
  ///
  /// In de, this message translates to:
  /// **'Warte auf GPS …'**
  String get walkWaitingForGps;

  /// No description provided for @walkWalking.
  ///
  /// In de, this message translates to:
  /// **'Gehen'**
  String get walkWalking;

  /// No description provided for @walkFinished.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get walkFinished;

  /// No description provided for @walkStopped.
  ///
  /// In de, this message translates to:
  /// **'Abgebrochen'**
  String get walkStopped;

  /// No description provided for @walkNotStartedYet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gestartet'**
  String get walkNotStartedYet;

  /// No description provided for @walkLoading.
  ///
  /// In de, this message translates to:
  /// **'Wird geladen …'**
  String get walkLoading;

  /// No description provided for @walkSlideToStop.
  ///
  /// In de, this message translates to:
  /// **'Zum Beenden schieben'**
  String get walkSlideToStop;

  /// No description provided for @walkBackBlocked.
  ///
  /// In de, this message translates to:
  /// **'Der Test läuft noch. Zum Beenden den Schieberegler nutzen.'**
  String get walkBackBlocked;

  /// No description provided for @walkResultCouldNotBeLoaded.
  ///
  /// In de, this message translates to:
  /// **'Das Ergebnis konnte nicht geladen werden.'**
  String get walkResultCouldNotBeLoaded;

  /// No description provided for @walkNoPositionYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Position verfügbar'**
  String get walkNoPositionYet;

  /// No description provided for @walkAccuracy.
  ///
  /// In de, this message translates to:
  /// **'Genauigkeit: {accuracy} m'**
  String walkAccuracy(String accuracy);

  /// No description provided for @walkOfSixMinutes.
  ///
  /// In de, this message translates to:
  /// **'von 6:00 min'**
  String get walkOfSixMinutes;

  /// No description provided for @walkYears.
  ///
  /// In de, this message translates to:
  /// **'{age} Jahre'**
  String walkYears(int age);

  /// No description provided for @walkHeightCm.
  ///
  /// In de, this message translates to:
  /// **'{height} cm'**
  String walkHeightCm(int height);

  /// No description provided for @walkOfExpectedDistance.
  ///
  /// In de, this message translates to:
  /// **'der erwarteten Gehstrecke'**
  String get walkOfExpectedDistance;

  /// No description provided for @aboutTitle.
  ///
  /// In de, this message translates to:
  /// **'Über die App'**
  String get aboutTitle;

  /// No description provided for @aboutProject.
  ///
  /// In de, this message translates to:
  /// **'Diese 6MWT-App wurde im Rahmen eines Software-Engineering-Projekts während des Sommersemesters 2026 an der Universität Ulm entwickelt.'**
  String get aboutProject;

  /// No description provided for @aboutVersion.
  ///
  /// In de, this message translates to:
  /// **'App-Version'**
  String get aboutVersion;

  /// No description provided for @aboutBuild.
  ///
  /// In de, this message translates to:
  /// **'Buildnummer'**
  String get aboutBuild;

  /// No description provided for @aboutCommit.
  ///
  /// In de, this message translates to:
  /// **'Commit-Hash'**
  String get aboutCommit;

  /// No description provided for @aboutUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Nicht verfügbar'**
  String get aboutUnavailable;

  /// No description provided for @aboutAuthors.
  ///
  /// In de, this message translates to:
  /// **'Autoren'**
  String get aboutAuthors;

  /// No description provided for @aboutRepository.
  ///
  /// In de, this message translates to:
  /// **'GitHub-Repository'**
  String get aboutRepository;

  /// No description provided for @aboutProjectLicense.
  ///
  /// In de, this message translates to:
  /// **'Projektlizenz'**
  String get aboutProjectLicense;

  /// No description provided for @aboutLicenses.
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get aboutLicenses;

  /// No description provided for @aboutLinkError.
  ///
  /// In de, this message translates to:
  /// **'Der Link konnte nicht geöffnet werden.'**
  String get aboutLinkError;

  /// No description provided for @deleteSession.
  ///
  /// In de, this message translates to:
  /// **'Gehtest löschen'**
  String get deleteSession;

  /// No description provided for @deleteSessionDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Gehtest löschen?'**
  String get deleteSessionDialogTitle;

  /// No description provided for @deleteSessionDialogMessage.
  ///
  /// In de, this message translates to:
  /// **'Möchten Sie diesen aufgezeichneten Gehtest wirklich löschen? Dies kann nicht rückgängig gemacht werden.'**
  String get deleteSessionDialogMessage;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @sessionDeleted.
  ///
  /// In de, this message translates to:
  /// **'Gehtest gelöscht'**
  String get sessionDeleted;

  /// No description provided for @cannotDeleteActiveSession.
  ///
  /// In de, this message translates to:
  /// **'Ein aktiver Gehtest kann nicht gelöscht werden.'**
  String get cannotDeleteActiveSession;

  /// No description provided for @resultTitle.
  ///
  /// In de, this message translates to:
  /// **'Testergebnisse'**
  String get resultTitle;

  /// No description provided for @resultIntro.
  ///
  /// In de, this message translates to:
  /// **'Hier sind Ihre Ergebnisse aus dem 6-Minuten-Gehtest.'**
  String get resultIntro;

  /// No description provided for @resultPerformance.
  ///
  /// In de, this message translates to:
  /// **'Leistung'**
  String get resultPerformance;

  /// No description provided for @resultExpectedDistance.
  ///
  /// In de, this message translates to:
  /// **'der erwarteten Gehstrecke'**
  String get resultExpectedDistance;

  /// No description provided for @resultNoAssessment.
  ///
  /// In de, this message translates to:
  /// **'Keine Bewertung möglich'**
  String get resultNoAssessment;

  /// No description provided for @resultEarlyStopExplanation.
  ///
  /// In de, this message translates to:
  /// **'Eine Bewertung ist nicht möglich, da der Test vorzeitig abgebrochen wurde.'**
  String get resultEarlyStopExplanation;

  /// No description provided for @resultPerformanceExplanation.
  ///
  /// In de, this message translates to:
  /// **'Ihre Leistung wird anhand Ihres Alters, Ihrer Körpergröße und Ihrer Gehstrecke beurteilt.'**
  String get resultPerformanceExplanation;

  /// No description provided for @resultTestDetails.
  ///
  /// In de, this message translates to:
  /// **'Testdetails'**
  String get resultTestDetails;

  /// No description provided for @resultDistanceWalked.
  ///
  /// In de, this message translates to:
  /// **'Zurückgelegte Strecke'**
  String get resultDistanceWalked;

  /// No description provided for @resultDistanceConfidence.
  ///
  /// In de, this message translates to:
  /// **'Zuverlässigkeit der Distanzmessung'**
  String get resultDistanceConfidence;

  /// No description provided for @resultTestDuration.
  ///
  /// In de, this message translates to:
  /// **'Testdauer'**
  String get resultTestDuration;

  /// No description provided for @resultTestStatus.
  ///
  /// In de, this message translates to:
  /// **'Teststatus'**
  String get resultTestStatus;

  /// No description provided for @resultStoppedEarly.
  ///
  /// In de, this message translates to:
  /// **'Vorzeitig abgebrochen'**
  String get resultStoppedEarly;

  /// No description provided for @resultCompleted.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen'**
  String get resultCompleted;

  /// No description provided for @resultYourProfile.
  ///
  /// In de, this message translates to:
  /// **'Ihr Profil'**
  String get resultYourProfile;

  /// No description provided for @resultName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get resultName;

  /// No description provided for @resultAge.
  ///
  /// In de, this message translates to:
  /// **'Alter'**
  String get resultAge;

  /// No description provided for @resultAgeYears.
  ///
  /// In de, this message translates to:
  /// **'{age} Jahre'**
  String resultAgeYears(int age);

  /// No description provided for @resultHeight.
  ///
  /// In de, this message translates to:
  /// **'Körpergröße'**
  String get resultHeight;

  /// No description provided for @resultHeightCm.
  ///
  /// In de, this message translates to:
  /// **'{height} cm'**
  String resultHeightCm(int height);

  /// No description provided for @resultWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get resultWeight;

  /// No description provided for @resultWeightKg.
  ///
  /// In de, this message translates to:
  /// **'{weight} kg'**
  String resultWeightKg(String weight);

  /// No description provided for @resultGender.
  ///
  /// In de, this message translates to:
  /// **'Geschlecht'**
  String get resultGender;

  /// No description provided for @resultDistanceComparison.
  ///
  /// In de, this message translates to:
  /// **'Streckenvergleich'**
  String get resultDistanceComparison;

  /// No description provided for @resultCalculatingDistanceComparisons.
  ///
  /// In de, this message translates to:
  /// **'Streckenvergleiche werden berechnet …'**
  String get resultCalculatingDistanceComparisons;

  /// No description provided for @resultDistanceComparisonFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Streckenvergleiche konnten nicht berechnet werden.'**
  String get resultDistanceComparisonFailed;

  /// No description provided for @resultLowConfidenceWarning.
  ///
  /// In de, this message translates to:
  /// **'Die Distanzmessung war bei diesem Test ungenau. Die Bewertung ist daher nur eingeschränkt aussagekräftig.'**
  String get resultLowConfidenceWarning;

  /// No description provided for @resultDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Das Ergebnis dient nur zur Orientierung und ersetzt keine ärztliche Beratung. Die Gehstrecke wird geschätzt und kann auch bei hoher Zuverlässigkeit abweichen. Für Folgen oder Entscheidungen auf Grundlage der Ergebnisse übernehmen wir keine Haftung.'**
  String get resultDisclaimer;

  /// No description provided for @resultExportFailed.
  ///
  /// In de, this message translates to:
  /// **'Export fehlgeschlagen: {error}'**
  String resultExportFailed(String error);

  /// No description provided for @resultDeleteFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Löschen des Tests: {error}'**
  String resultDeleteFailed(String error);

  /// No description provided for @historyTitle.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get historyTitle;

  /// No description provided for @historyNoEntries.
  ///
  /// In de, this message translates to:
  /// **'Keine Einträge vorhanden'**
  String get historyNoEntries;

  /// No description provided for @historyFit.
  ///
  /// In de, this message translates to:
  /// **'fit'**
  String get historyFit;

  /// A whole-number percentage. German puts a narrow no-break space before the sign, English none.
  ///
  /// In de, this message translates to:
  /// **'{value} %'**
  String percentValue(int value);

  /// No description provided for @historyToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get historyYesterday;

  /// No description provided for @historyExportFailed.
  ///
  /// In de, this message translates to:
  /// **'Export fehlgeschlagen: {error}'**
  String historyExportFailed(String error);

  /// No description provided for @historyLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {error}'**
  String historyLoadFailed(String error);

  /// No description provided for @instructions_3_heading.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Daten'**
  String get instructions_3_heading;

  /// No description provided for @confidenceHigh.
  ///
  /// In de, this message translates to:
  /// **'Hoch'**
  String get confidenceHigh;

  /// No description provided for @confidenceMedium.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get confidenceMedium;

  /// No description provided for @confidenceLow.
  ///
  /// In de, this message translates to:
  /// **'Niedrig'**
  String get confidenceLow;

  /// No description provided for @comparisonConfidence.
  ///
  /// In de, this message translates to:
  /// **'Zuverlässigkeit: {value}'**
  String comparisonConfidence(String value);

  /// No description provided for @comparisonUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Streckenschätzer nicht verfügbar: {error}'**
  String comparisonUnavailable(String error);

  /// No description provided for @estimatorMain.
  ///
  /// In de, this message translates to:
  /// **'Haupt ({name})'**
  String estimatorMain(String name);

  /// No description provided for @fitnessReducedPhysicalPerformance.
  ///
  /// In de, this message translates to:
  /// **'Verminderte körperliche Leistungs­fähigkeit'**
  String get fitnessReducedPhysicalPerformance;

  /// No description provided for @fitnessLowNormal.
  ///
  /// In de, this message translates to:
  /// **'Niedrig-normal'**
  String get fitnessLowNormal;

  /// No description provided for @fitnessNormalPopulationMean.
  ///
  /// In de, this message translates to:
  /// **'Bevölkerungs­durchschnitt'**
  String get fitnessNormalPopulationMean;

  /// No description provided for @fitnessHighNormal.
  ///
  /// In de, this message translates to:
  /// **'Hoch-normal'**
  String get fitnessHighNormal;

  /// No description provided for @fitnessTopPerformance.
  ///
  /// In de, this message translates to:
  /// **'Spitzenleistung'**
  String get fitnessTopPerformance;

  /// No description provided for @walkErrorLocation.
  ///
  /// In de, this message translates to:
  /// **'Standortberechtigung verweigert oder GPS deaktiviert'**
  String get walkErrorLocation;

  /// No description provided for @walkLocationRequiredTitle.
  ///
  /// In de, this message translates to:
  /// **'Standortzugriff erforderlich'**
  String get walkLocationRequiredTitle;

  /// No description provided for @walkLocationRequiredText.
  ///
  /// In de, this message translates to:
  /// **'Der Test misst die Gehstrecke per GPS und funktioniert ohne Standortzugriff nicht. Bitte erlauben Sie der App den Zugriff auf Ihren Standort, schalten Sie GPS ein und starten Sie den Test erneut.'**
  String get walkLocationRequiredText;

  /// No description provided for @walkErrorActivityRecognition.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung zur Aktivitätserkennung verweigert'**
  String get walkErrorActivityRecognition;

  /// No description provided for @walkErrorSensorUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Sensoren konnten nicht gestartet werden: {error}'**
  String walkErrorSensorUnavailable(String error);

  /// No description provided for @walkErrorSensor.
  ///
  /// In de, this message translates to:
  /// **'Sensorfehler: {error}'**
  String walkErrorSensor(String error);
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
