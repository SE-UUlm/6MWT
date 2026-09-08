// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => '6-Minuten-Gehtest';

  @override
  String get appSubTitle =>
      'Standardisierte Beurteilung der funktionellen Belastbarkeit';

  @override
  String get appProfile => 'Einrichtung des Patientenprofils';

  @override
  String get appCountdown => '6-Minuten-Countdown';

  @override
  String get appResult => 'Ergebnisse und Werte';

  @override
  String get startTest => 'Test starten';

  @override
  String get settings => 'Einstellungen';

  @override
  String get continueButton => 'Weiter';

  @override
  String get instructions => 'Anleitung';

  @override
  String get instructions_1_welc => 'Willkommen';

  @override
  String get instructions_1_text =>
      'Diese App führt Sie Schritt für Schritt durch den 6-Minuten-Gehtest (6MWT). Der Test hilft dabei, Ihre körperliche Leistungsfähigkeit anhand der in sechs Minuten zurückgelegten Strecke zu beurteilen.';

  @override
  String get instructions_2_welc => 'Testverfahren';

  @override
  String get bulletPoint_1 => 'Persönliche Daten eingeben';

  @override
  String get bulletPoint_2 => 'Test starten';

  @override
  String get bulletPoint_3 => 'Gehen Sie 6 Minuten lang';

  @override
  String get bulletPoint_4 => 'Ergebnisse';

  @override
  String get instructions_2_text =>
      'Der Test dauert nur sechs Minuten. Während dieser Zeit misst die App die zurückgelegte Strecke und die verbleibende Zeit.';

  @override
  String get instructions_3_welc => 'Personenbezogene Daten';

  @override
  String get instructions_3_text =>
      'Für eine möglichst präzise Analyse benötigen wir einige Angaben wie Alter, Körpergröße, Gewicht und Geschlecht. Diese Daten dienen dazu, Ihre Ergebnisse besser einordnen zu können.';

  @override
  String get instructions_4_welc => 'Während des Tests';

  @override
  String get instructions_4_text =>
      'Gehen Sie sechs Minuten lang in Ihrem normalen, zügigen Tempo. Die App zeigt die verbleibende Zeit und die bereits zurückgelegte Strecke an.';

  @override
  String get instructions_4_text_2 =>
      'Brechen Sie den Test ab, wenn bei Ihnen Brustschmerzen, Schwindel oder starke Atemnot auftreten.';

  @override
  String get instructions_5_welc => 'Den Test abbrechen';

  @override
  String get instructions_5_text =>
      'Bei Bedarf können Sie den Test jederzeit abbrechen und anschließend entscheiden, wie Sie fortfahren möchten:';

  @override
  String get instructions_5_c1 => 'Zwischenergebnisse werden gespeichert';

  @override
  String get instructions_5_c2 => 'Die Ergebnisse werden angezeigt';

  @override
  String get instructions_5_c3 => 'Der Informationswert mag begrenzt sein';

  @override
  String get instructions_5_f1 => 'Alle bisherigen Daten werden verworfen';

  @override
  String get instructions_5_f2 => 'Sie können den Test erneut starten';

  @override
  String get instructions_6_welc => 'Übersicht der Ergebnisse';

  @override
  String get instructions_6_text =>
      'Your walking distance is classified based on reference values and you get an overview of your performance and values reached.';

  @override
  String get instructions_7_welc => 'Sie sind bereit!';

  @override
  String get instructions_7_text =>
      'Jetzt, da Sie wissen, wie es funktioniert, können Sie jederzeit einen Test starten und abschließen!';
}
