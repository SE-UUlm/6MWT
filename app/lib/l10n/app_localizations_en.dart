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
  String get appProfile => 'Set up patient profile';

  @override
  String get appCountdown => '6-minute countdown';

  @override
  String get appResult => 'Results and measurements';

  @override
  String get home_walk => 'Walk';

  @override
  String get home_walksb => 'Walk as far as possible in 6 minutes';

  @override
  String get home_performance => 'Performance';

  @override
  String get home_performancesb => 'Measure your endurance objectively';

  @override
  String get home_progress => 'Progress';

  @override
  String get home_progresssb => 'Compare results';

  @override
  String get home_result => 'My Results';

  @override
  String get home_resultsb => 'View previous tests';

  @override
  String get home_instruction => 'About the 6-minute test';

  @override
  String get home_instructionsb => 'Detailed instructions';

  @override
  String get startTest => 'Start Test';

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
  String get bulletPoint_1 => 'Enter personal information';

  @override
  String get bulletPoint_2 => 'Start the test';

  @override
  String get bulletPoint_3 => 'Walk for 6 minutes';

  @override
  String get bulletPoint_4 => 'Results';

  @override
  String get instructions_2_text =>
      'The test takes only six minutes. During this time, the app measures the distance covered and the remaining time.';

  @override
  String get instructions_3_welc => 'Personal information';

  @override
  String get instructions_3_text =>
      'For the most accurate analysis possible, we need some information such as your age, height, weight and gender. This data helps us interpret your results.';

  @override
  String get instructions_4_welc => 'During the test';

  @override
  String get instructions_4_text =>
      'Walk at your normal, brisk pace for six minutes. The app displays the remaining time and the distance you have already covered.';

  @override
  String get instructions_4_text_2 =>
      'Stop the test if you experience chest pain, dizziness or severe shortness of breath.';

  @override
  String get instructions_5_welc => 'Stopping the test';

  @override
  String get instructions_5_text =>
      'You can stop the test at any time if needed and then decide how you would like to proceed:';

  @override
  String get instructions_5_c1 => 'Intermediate results are saved';

  @override
  String get instructions_5_c2 => 'The results are displayed';

  @override
  String get instructions_5_c3 => 'The results may be less conclusive';

  @override
  String get instructions_5_f1 => 'All previous data is discarded';

  @override
  String get instructions_5_f2 => 'You can restart the test';

  @override
  String get instructions_6_welc => 'Results overview';

  @override
  String get instructions_6_text =>
      'Your walking distance is assessed using reference values. You receive an overview of your performance and measured results.';

  @override
  String get instructions_7_welc => 'You\'re ready!';

  @override
  String get instructions_7_text =>
      'Now that you know how it works, you can start and complete a test whenever you\'re ready!';

  @override
  String get profile_title => 'Pre-calibration';

  @override
  String get profile_text =>
      'To obtain the most accurate test results, please enter all information correctly.';

  @override
  String get profile_sub1 => 'Patient information';

  @override
  String get profile_sub2 => 'Anthropometry';

  @override
  String get profile_info =>
      'Please enter your age, gender, height and weight.';

  @override
  String get profileAgeOutOfRange =>
      'Please enter an age between 1 and 120 years.';

  @override
  String get profileHeightOutOfRange =>
      'Please enter a height between 50 and 250 cm.';

  @override
  String get profileWeightOutOfRange =>
      'Please enter a weight between 1 and 400 kg.';

  @override
  String get field1 => 'Name';

  @override
  String get field2 => 'Age in years';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other/Prefer not to say';

  @override
  String get field4 => 'Height';

  @override
  String get field5 => 'Weight';

  @override
  String get profile_footer =>
      'Your privacy is important to us. This information will not be used for any other purpose.';

  @override
  String get video_title => 'Test preparation';

  @override
  String get video_text =>
      'Walk back and forth along the marked course (e.g. 6 metres), starting in the middle. Walk at your own pace. If you are unsure how the test works, watch the video below for guidance.';

  @override
  String get walk_info => 'Please go as far as possible in 6 minutes.';

  @override
  String get walk_idstance => 'Distance';

  @override
  String get walk_status => 'Status';

  @override
  String get walk_assessment => 'Assessment';

  @override
  String get walk_start => 'Not started';

  @override
  String get walk_position => 'Current Position';

  @override
  String get walk_duration => 'Duration';

  @override
  String get walk_profile => 'Profile';

  @override
  String get walk_test_start => 'Start Test';

  @override
  String get walk_reset => 'Reset';

  @override
  String get walkPleaseGoFar => 'Please go as far as possible in 6 minutes.';

  @override
  String get walkNotStarted => 'Not started';

  @override
  String get walkWaitingForGps => 'Waiting for GPS...';

  @override
  String get walkWalking => 'Walking';

  @override
  String get walkFinished => 'Finished';

  @override
  String get walkStopped => 'Stopped';

  @override
  String get walkNotStartedYet => 'Not started yet';

  @override
  String get walkLoading => 'Loading...';

  @override
  String get walkSlideToStop => 'Slide to stop';

  @override
  String get walkResultCouldNotBeLoaded => 'Result could not be loaded.';

  @override
  String get walkNoPositionYet => 'No position yet';

  @override
  String walkAccuracy(String accuracy) {
    return 'Accuracy: $accuracy m';
  }

  @override
  String get walkOfSixMinutes => 'of 6:00 min';

  @override
  String walkYears(int age) {
    return '$age years';
  }

  @override
  String walkHeightCm(int height) {
    return '$height cm';
  }

  @override
  String get walkOfExpectedDistance => 'of expected distance';

  @override
  String get walkStartTestButton => 'Start Test';

  @override
  String walkDistanceUnit(String distance) {
    return '$distance m';
  }

  @override
  String get aboutTitle => 'About the app';

  @override
  String get aboutProject =>
      'This 6MWT app was developed as part of a software engineering project during the summer semester of 2026 at Ulm University.';

  @override
  String get aboutVersion => 'App version';

  @override
  String get aboutBuild => 'Build number';

  @override
  String get aboutCommit => 'Commit hash';

  @override
  String get aboutUnavailable => 'Not available';

  @override
  String get aboutAuthors => 'Authors';

  @override
  String get aboutRepository => 'GitHub repository';

  @override
  String get aboutProjectLicense => 'Project license';

  @override
  String get aboutLicenses => 'Open-source licenses';

  @override
  String get aboutLinkError => 'The link could not be opened.';

  @override
  String get deleteSession => 'Delete walk test';

  @override
  String get deleteSessionDialogTitle => 'Delete walk test?';

  @override
  String get deleteSessionDialogMessage =>
      'Are you sure you want to delete this recorded walk test? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get sessionDeleted => 'Walk test deleted';

  @override
  String get cannotDeleteActiveSession =>
      'An active walk test cannot be deleted.';

  @override
  String get resultTitle => 'Test Results';

  @override
  String get resultIntro =>
      'Here are your results from the 6-minute walk test.';

  @override
  String get resultPerformance => 'Performance';

  @override
  String get resultExpectedDistance => 'of expected distance';

  @override
  String get resultNoAssessment => 'No assessment possible';

  @override
  String get resultEarlyStopExplanation =>
      'An assessment is not possible because the test was stopped early.';

  @override
  String get resultPerformanceExplanation =>
      'Your performance is based on your age, height and walking distance.';

  @override
  String get resultTestDetails => 'Test Details';

  @override
  String get resultDistanceWalked => 'Distance walked';

  @override
  String get resultDistanceConfidence => 'Distance confidence';

  @override
  String get resultTestDuration => 'Test duration';

  @override
  String get resultTestStatus => 'Test status';

  @override
  String get resultStoppedEarly => 'Stopped early';

  @override
  String get resultCompleted => 'Completed';

  @override
  String get resultYourProfile => 'Your Profile';

  @override
  String get resultName => 'Name';

  @override
  String get resultAge => 'Age';

  @override
  String resultAgeYears(int age) {
    return '$age years';
  }

  @override
  String get resultHeight => 'Height';

  @override
  String resultHeightCm(int height) {
    return '$height cm';
  }

  @override
  String get resultWeight => 'Weight';

  @override
  String resultWeightKg(String weight) {
    return '$weight kg';
  }

  @override
  String get resultGender => 'Gender';

  @override
  String get resultDistanceComparison => 'Distance comparison';

  @override
  String get resultCalculatingDistanceComparisons =>
      'Calculating distance comparisons...';

  @override
  String get resultDistanceComparisonFailed =>
      'Could not calculate distance comparisons.';

  @override
  String get resultDisclaimer =>
      'The result provides guidance based on your recorded walking distance and personal data.';

  @override
  String resultExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String resultDeleteFailed(String error) {
    return 'Error deleting test: $error';
  }

  @override
  String get historyTitle => 'History';

  @override
  String get historyNoEntries => 'No entries available';

  @override
  String get historyFit => 'fit';

  @override
  String get historyToday => 'Today';

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String historyExportFailed(String error) {
    return 'Export failed: $error';
  }
}
