// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => '6-Minute Walk Test';

  @override
  String get appSubTitle =>
      'Standardized assessment of functional exercise capacity';

  @override
  String get appProfile => 'Patient profile setup';

  @override
  String get appCountdown => '6-minute countdown';

  @override
  String get appResult => 'Results and values';

  @override
  String get startTest => 'Start test';

  @override
  String get settings => 'Settings';

  @override
  String get continueButton => 'Continue';

  @override
  String get instructions => 'Instructions';

  @override
  String get instructions_1_welc => 'Welcome';

  @override
  String get instructions_1_text =>
      'This app guides you step by step through the 6-Minute Walk Test (6MWT). The test helps assess your physical performance based on the distance covered in six minutes.';

  @override
  String get instructions_2_welc => 'Test procedure';

  @override
  String get bulletPoint_1 => 'Enter personal data';

  @override
  String get bulletPoint_2 => 'Start the test';

  @override
  String get bulletPoint_3 => 'Walk for 6 minutes';

  @override
  String get bulletPoint_4 => 'Results';

  @override
  String get instructions_2_text =>
      'The test only takes six minutes. During this time, the app measures the distance covered and the remaining time.';

  @override
  String get instructions_3_welc => 'Personal data';

  @override
  String get instructions_3_text =>
      'For the most accurate analysis possible, we need some information such as age, height, weight, and sex. This data helps us better interpret your results.';

  @override
  String get instructions_4_welc => 'During the test';

  @override
  String get instructions_4_text =>
      'Walk for six minutes at your normal, brisk pace. The app displays the remaining time and the distance you have already covered.';

  @override
  String get instructions_4_text_2 =>
      'Stop the test if you experience chest pain, dizziness, or severe shortness of breath.';

  @override
  String get instructions_5_welc => 'Stopping the test';

  @override
  String get instructions_5_text =>
      'If necessary, you can stop the test at any time and then decide how you would like to proceed:';

  @override
  String get instructions_5_c1 => 'Interim results will be saved';

  @override
  String get instructions_5_c2 => 'The results will be displayed';

  @override
  String get instructions_5_c3 => 'The informational value may be limited';

  @override
  String get instructions_5_f1 => 'All previous data will be discarded';

  @override
  String get instructions_5_f2 => 'You can start the test again';

  @override
  String get instructions_6_welc => 'Overview of results';

  @override
  String get instructions_6_text =>
      'Your walking distance is classified based on reference values, and you get an overview of your performance and the values achieved.';

  @override
  String get instructions_7_welc => 'You are ready!';

  @override
  String get instructions_7_text =>
      'Now that you know how it works, you can start and complete a test at any time!';
}
