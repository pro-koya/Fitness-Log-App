// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeMessage => 'Welcome to Liftly';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get unitLabel => 'Unit';

  @override
  String get unitKg => 'kg';

  @override
  String get unitLb => 'lb';

  @override
  String get startButton => 'Start';

  @override
  String get appName => 'Liftly';

  @override
  String get startWorkoutButton => 'Start Workout';

  @override
  String get resumeWorkoutButton => 'Resume Workout';

  @override
  String get newWorkoutButton => 'Start New';

  @override
  String workoutInProgressSummary(int exerciseCount, int setCount) {
    return '$exerciseCount exercises, $setCount sets';
  }

  @override
  String get settingsButton => 'Settings';

  @override
  String get addExerciseButton => 'Add Exercise';

  @override
  String get completeButton => 'Complete';

  @override
  String get tutorialCompletionTitle => 'You\'re all set!';

  @override
  String get tutorialCompletionMessage =>
      'You\'re ready to start logging your workouts. Tap Complete when you finish a session.';

  @override
  String previousRecord(String records) {
    return 'Previous: $records';
  }

  @override
  String get previousRecordNone => 'Previous: —';

  @override
  String get reproduceButton => 'Reproduce Previous';

  @override
  String get addSetButton => 'Add Set';

  @override
  String setLabel(int number) {
    return 'Set $number';
  }

  @override
  String get weightLabel => 'Weight';

  @override
  String get repsLabel => 'Reps';

  @override
  String get copyButton => 'Copy';

  @override
  String get deleteButton => 'Delete';

  @override
  String get timerLabel => 'Timer';

  @override
  String get timerStart => 'Start';

  @override
  String get timerPause => 'Pause';

  @override
  String get timerReset => 'Reset';

  @override
  String get timerClose => 'Close';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get backButton => 'Back';

  @override
  String get workoutDetailTitle => 'Workout Detail';

  @override
  String sessionTime(String startTime, String endTime) {
    return '$startTime - $endTime';
  }

  @override
  String get emptyStateMessage => 'No workout recorded on this day.';

  @override
  String get exerciseProgressTitle => 'Exercise Progress';

  @override
  String get topWeightLabel => 'Top Weight';

  @override
  String get totalVolumeLabel => 'Total Volume';

  @override
  String get emptyProgressMessage =>
      'Not enough data to show graph. Keep recording your workouts!';

  @override
  String get deleteSetConfirmTitle => 'Delete this set?';

  @override
  String deleteSetConfirmMessage(
    int number,
    double weight,
    String unit,
    int reps,
  ) {
    return 'Set $number: $weight$unit/$reps reps';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get confirmButton => 'OK';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get recentWorkoutsLabel => 'Recent Workouts';

  @override
  String get errorLoadingWorkouts => 'Error loading workouts';

  @override
  String get noWorkoutHistory => 'No workout history yet';

  @override
  String get unknownDate => 'Unknown date';

  @override
  String durationLabel(String duration) {
    return 'Duration: $duration';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get workoutInProgress => 'Workout in progress';

  @override
  String get startNewWorkoutButton => 'Start New Workout';

  @override
  String get editWorkoutButton => 'Edit Workout';

  @override
  String get deleteWorkoutButton => 'Delete Workout';

  @override
  String setsCountLabel(int count) {
    return '$count sets';
  }

  @override
  String get noSetsRecorded => 'No sets recorded';

  @override
  String get deleteWorkoutDialogTitle => 'Delete Workout';

  @override
  String get deleteWorkoutDialogMessage =>
      'Are you sure you want to delete this workout? This action cannot be undone.';

  @override
  String errorDeletingWorkout(String error) {
    return 'Error deleting workout: $error';
  }

  @override
  String get saveButton => 'Save';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String monthlyWorkoutCount(int count) {
    return '$count workouts';
  }

  @override
  String get thisMonthLabel => 'This Month';

  @override
  String get streakLabel => 'Streak';

  @override
  String streakDays(int count) {
    return '$count days';
  }

  @override
  String get searchExercisePlaceholder => 'Search exercises...';

  @override
  String get selectExerciseTitle => 'Select Exercise';

  @override
  String get addCustomExerciseButton => 'Add Custom Exercise';

  @override
  String get customExerciseDialogTitle => 'Add Custom Exercise';

  @override
  String get exerciseNameLabel => 'Exercise Name';

  @override
  String get addButton => 'Add';

  @override
  String get historyTitle => 'History';

  @override
  String get viewDetailsButton => 'View Details';

  @override
  String exerciseCount(int count) {
    return '$count exercises';
  }

  @override
  String setCount(int count) {
    return '$count sets';
  }

  @override
  String workoutSummaryTitle(String date) {
    return 'Workout on $date';
  }

  @override
  String get noWorkoutsThisMonth => 'No workouts this month';

  @override
  String get deleteExerciseDialogTitle => 'Delete Exercise?';

  @override
  String deleteExerciseDialogMessage(String exerciseName) {
    return 'Are you sure you want to delete \"$exerciseName\"? This will remove all sets for this exercise.';
  }

  @override
  String get deleteCustomExerciseDialogTitle => 'Delete Custom Exercise?';

  @override
  String deleteCustomExerciseDialogMessage(String exerciseName) {
    return 'Are you sure you want to delete \"$exerciseName\"? This action cannot be undone.';
  }

  @override
  String exerciseDeleted(String exerciseName) {
    return 'Deleted \"$exerciseName\"';
  }

  @override
  String get exerciseHistoryTitle => 'Exercise History';

  @override
  String get noHistoryAvailable => 'No history available';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String weeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String monthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String yearsAgo(int count) {
    return '$count years ago';
  }

  @override
  String get monthlySummary => 'Monthly Summary';

  @override
  String get totalDuration => 'Total Duration';

  @override
  String get totalSets => 'Total Sets';

  @override
  String get totalVolume => 'Total Volume';

  @override
  String get totalTime => 'Total Time';

  @override
  String get setsUnit => 'sets';

  @override
  String get topExercises => 'Top Exercises';

  @override
  String get timesUnit => 'times';

  @override
  String get weeklyTrend => 'Weekly Trend';

  @override
  String get memoLabel => 'Memo';

  @override
  String get memoHistory => 'Memo History';

  @override
  String get noMemoRecorded => 'No memo';

  @override
  String get memoSearch => 'Search Memos';

  @override
  String get memoSearchPlaceholder => 'Search by keyword...';

  @override
  String get memoSearchNoResults => 'No memos found';

  @override
  String get memoSearchHint => 'Enter a keyword to search your workout memos';

  @override
  String get previousLabel => 'Previous:';

  @override
  String get historyButton => 'History';

  @override
  String get reproducePreviousButton => 'Reproduce Previous';

  @override
  String get memoPlaceholder => 'Add notes (e.g., form cues, how it felt...)';

  @override
  String get showLess => 'Show less';

  @override
  String showMoreSets(int count) {
    return '+$count more';
  }

  @override
  String get deleteExerciseTooltip => 'Delete exercise';

  @override
  String get weightTab => 'Weight';

  @override
  String get repsTab => 'Reps';

  @override
  String get volumeTab => 'Volume';

  @override
  String get noDataForExercise => 'No workout data found for this exercise.';

  @override
  String get summaryLabel => 'Summary';

  @override
  String get totalWorkouts => 'Total Workouts';

  @override
  String get latestTopWeight => 'Latest Top Weight';

  @override
  String get latestBestTime => 'Latest Best Time';

  @override
  String get latestTopReps => 'Latest Top Reps';

  @override
  String get latestTopVolume => 'Latest Top Volume';

  @override
  String get startingWeight => 'Starting Weight';

  @override
  String get startingBestTime => 'Starting Best Time';

  @override
  String get startingTopReps => 'Starting Top Reps';

  @override
  String get startingTopVolume => 'Starting Top Volume';

  @override
  String get improvement => 'Improvement';

  @override
  String get repsUnit => 'reps';

  @override
  String noBodyPartWorkoutsThisMonth(String bodyPart) {
    return 'No $bodyPart workouts recorded this month.';
  }

  @override
  String get distanceUnitLabel => 'Distance Unit';

  @override
  String get distanceUnitKm => 'km';

  @override
  String get distanceUnitMile => 'mile';

  @override
  String get timeTab => 'Time';

  @override
  String get distanceTab => 'Distance';

  @override
  String get paceTab => 'Pace';

  @override
  String get latestBestDistance => 'Latest Best Distance';

  @override
  String get startingBestDistance => 'Starting Best Distance';

  @override
  String get paywallTitleHistory => 'View your full history';

  @override
  String get paywallTitleChart => 'See your progress in charts';

  @override
  String get paywallTitleTheme => 'Personalize your theme';

  @override
  String get paywallTitleStats => 'View detailed stats';

  @override
  String get paywallTitleExport => 'Export your data';

  @override
  String get paywallBodyHistory =>
      'Free shows your latest 20 sessions. Go Pro to unlock full history, charts, and stats to see your progress.';

  @override
  String get paywallBodyChart =>
      'Track your growth with detailed charts and graphs. Available with Pro.';

  @override
  String get paywallBodyTheme =>
      'Customize your app\'s look with your favorite colors. Available with Pro.';

  @override
  String get paywallBodyStats =>
      'Get detailed weekly and monthly statistics. Available with Pro.';

  @override
  String get paywallBodyExport =>
      'Export your workout data to CSV. Available with Pro.';

  @override
  String get paywallCtaTryPro => 'Try Pro';

  @override
  String get paywallCtaNotNow => 'Not now';

  @override
  String get paywallCompareHistory => 'History';

  @override
  String get paywallCompareLast20 => 'Last 20';

  @override
  String get paywallCompareUnlimited => 'Unlimited';

  @override
  String get paywallCompareCharts => 'Charts';

  @override
  String get paywallCompareTheme => 'Theme';

  @override
  String get paywallCompareDefault => 'Default';

  @override
  String get paywallCompareCustom => 'Custom';

  @override
  String get lockedSessionHint => 'Unlock full history with Pro';

  @override
  String get lockedSessionSubHint =>
      'Free shows the latest 20 sessions. Go Pro to view everything.';

  @override
  String get proLabel => 'Pro';

  @override
  String get freeLabel => 'Free';

  @override
  String get paywallPriceMonthly => '¥150/month';

  @override
  String get paywallPriceYearly => '¥1,500/year';

  @override
  String get paywallPriceOr => 'or';

  @override
  String get shareWorkoutButton => 'Share';

  @override
  String get shareWorkoutDialogTitle => 'Share Workout';

  @override
  String get copyToClipboard => 'Copy to Clipboard';

  @override
  String get copiedToClipboard => 'Copied to Clipboard';

  @override
  String get themeSettingsTitle => 'Theme Settings';

  @override
  String get presetThemesLabel => 'Preset Themes';

  @override
  String get customColorsLabel => 'Custom Colors';

  @override
  String get primaryColorLabel => 'Primary Color';

  @override
  String get secondaryColorLabel => 'Secondary Color';

  @override
  String get previewLabel => 'Preview';

  @override
  String get resetToDefaultLabel => 'Reset to Default';

  @override
  String get resetThemeConfirmMessage => 'Reset theme settings to default?';

  @override
  String get contrastWarning => 'Low contrast may affect readability';

  @override
  String get themeLabel => 'Theme';

  @override
  String get invalidHexColor => 'Invalid color code';

  @override
  String get hexColorHint => 'e.g. #1976D2';

  @override
  String get selectColor => 'Select Color';

  @override
  String get colorPalette => 'Color Palette';

  @override
  String get colorCategoryBasic => 'Basic';

  @override
  String get colorCategoryRed => 'Red';

  @override
  String get colorCategoryPink => 'Pink';

  @override
  String get colorCategoryPurple => 'Purple';

  @override
  String get colorCategoryBlue => 'Blue';

  @override
  String get colorCategoryGreen => 'Green';

  @override
  String get colorCategoryOrange => 'Orange';

  @override
  String get colorCategoryBrown => 'Brown';

  @override
  String get paywallTitleBackup => 'Backup your data';

  @override
  String get paywallBodyBackup =>
      'Back up your data to transfer to a new device. Available with Pro.';

  @override
  String get backupLabel => 'Backup';

  @override
  String get backupTitle => 'Backup & Restore';

  @override
  String get backupSectionTitle => 'Create Backup';

  @override
  String get backupSectionDescription =>
      'Export all your workout data to a file';

  @override
  String get createBackupButton => 'Create Backup';

  @override
  String get restoreSectionTitle => 'Restore from Backup';

  @override
  String get restoreSectionDescription => 'Import data from a backup file';

  @override
  String get restoreBackupButton => 'Select Backup File';

  @override
  String get backupWarning =>
      'Restoring will overwrite all current data. Make sure to backup current data first if needed.';

  @override
  String get creatingBackup => 'Creating backup...';

  @override
  String get backupCreated => 'Backup created successfully';

  @override
  String get loadingBackup => 'Loading backup file...';

  @override
  String get restoringData => 'Restoring data...';

  @override
  String get restoreCompleted => 'Data restored successfully';

  @override
  String get invalidBackupFile => 'Invalid backup file format';

  @override
  String get incompatibleBackupVersion =>
      'This backup version is not compatible';

  @override
  String get restoreConfirmTitle => 'Restore Data?';

  @override
  String restoreConfirmBackupDate(String date) {
    return 'Backup date: $date';
  }

  @override
  String restoreConfirmSessionCount(int count) {
    return 'Sessions: $count';
  }

  @override
  String restoreConfirmExerciseCount(int count) {
    return 'Exercises: $count';
  }

  @override
  String get restoreConfirmWarning => 'Current data will be overwritten';

  @override
  String get restoreButton => 'Restore';

  @override
  String get paywallSubscriptionMonthly => 'Monthly';

  @override
  String get paywallSubscriptionYearly => 'Yearly';

  @override
  String get paywallSubscriptionYearlySave => 'Save 17%';

  @override
  String get paywallSubscriptionPurchasing => 'Processing...';

  @override
  String get paywallSubscriptionError => 'Purchase failed. Please try again.';

  @override
  String get paywallRestorePurchases => 'Restore Purchases';

  @override
  String get paywallRestoreSuccess => 'Purchases restored';

  @override
  String get paywallRestoreNoSubscription => 'No active subscription found';

  @override
  String get paywallRestoring => 'Restoring...';

  @override
  String get paywallTermsOfService => 'Terms of Service';

  @override
  String get paywallPrivacyPolicy => 'Privacy Policy';

  @override
  String get paywallTrialTitle => 'Start your 1-month free trial';

  @override
  String get paywallTrialDescription =>
      'Try all Pro features free for 1 month. After the trial ends, your subscription will automatically begin.';

  @override
  String get paywallTrialNotice =>
      'To avoid being charged, cancel anytime during the free trial period.';

  @override
  String get paywallCtaStartTrial => 'Start Free Trial';

  @override
  String get settingsManageSubscription => 'Manage Subscription';

  @override
  String get settingsManageSubscriptionHint =>
      'Cancel or change your subscription';

  @override
  String get paywallSubscriptionDisclaimer =>
      'Payment will be charged to your Apple ID account at the end of the free trial. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage and cancel your subscription in your Apple ID account settings.';
}
