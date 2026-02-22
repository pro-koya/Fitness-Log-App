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
  String get initialSetupWeightLabel => 'Weight';

  @override
  String get initialSetupDistanceLabel => 'Distance';

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
  String get averageWeightLabel => 'Avg. Weight';

  @override
  String get selectMonthYear => 'Select month & year';

  @override
  String get lastMonthShort => 'Last month';

  @override
  String get thisMonthShort => 'This month';

  @override
  String get nextMonthShort => 'Next month';

  @override
  String get allRecordsTitle => 'All Records';

  @override
  String totalWorkoutsCount(int count) {
    return '$count workouts total';
  }

  @override
  String moreExercisesHint(int count) {
    return '+$count more…';
  }

  @override
  String get tapForDetailHint => 'Tap for details';

  @override
  String get exerciseAlreadyAdded => 'Already added';

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
  String get paywallTitleHistory => 'Keep all your workout history';

  @override
  String get paywallTitleChart => 'See how you\'re progressing';

  @override
  String get paywallTitleTheme => 'Make it truly yours';

  @override
  String get paywallTitleStats => 'Understand your training habits';

  @override
  String get paywallTitleExport => 'Export your data';

  @override
  String get paywallBodyHistory =>
      'Your training so far has real value. With Pro, you can keep and review all your workout records anytime.';

  @override
  String get paywallBodyChart =>
      'Changes in numbers show your consistency. With Pro, you can track your progress through clear and simple charts.';

  @override
  String get paywallBodyTheme =>
      'When something feels right, it\'s easier to keep going. With Pro, you can customize the app\'s theme to match your style.';

  @override
  String get paywallBodyStats =>
      'Looking back helps you stay consistent. With Pro, you can review detailed weekly and monthly training statistics.';

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
  String get paywallCompareLast20 => 'Last 30';

  @override
  String get paywallCompareUnlimited => 'Unlimited';

  @override
  String get paywallCompareCharts => 'Charts';

  @override
  String get paywallCompareTheme => 'Theme';

  @override
  String get paywallCompareChartsTheme => 'Charts & Theme';

  @override
  String get paywallCompareAds => 'Ads';

  @override
  String get paywallCompareAdsShow => 'Show';

  @override
  String get paywallCompareAdsHide => 'Hide';

  @override
  String get paywallCompareDefault => 'Default';

  @override
  String get paywallCompareCustom => 'Custom';

  @override
  String get lockedSessionHint => 'Unlock full history with Pro';

  @override
  String get lockedSessionSubHint =>
      'Free shows the latest 30 sessions. Go Pro to view everything.';

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
  String get paywallTitleBackup => 'Keep your records safe';

  @override
  String get paywallBodyBackup =>
      'Your workout history is worth protecting. With Pro, you can back up your data and keep it safe.';

  @override
  String get paywallTitleAds => 'Hide ads and focus on your workout';

  @override
  String get paywallBodyAds =>
      'With Pro, ads are removed and you get full access to history, theme, backup, and more.';

  @override
  String get settingsPlanSection => 'Plan';

  @override
  String get settingsUpgradeToPro => 'Upgrade to Pro';

  @override
  String get settingsProPlanDescription =>
      'Hide ads, full history, theme, backup & more';

  @override
  String get adHideWithProCta => 'Hide ads with Pro?';

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
  String get backupFormatLabel => 'Backup format';

  @override
  String get backupFormatJson => 'JSON (for restore)';

  @override
  String get backupFormatCsv => 'CSV (for analysis)';

  @override
  String get createBackupButton => 'Create Backup';

  @override
  String get restoreSectionTitle => 'Restore from Backup';

  @override
  String get restoreSectionDescription =>
      'Import data from a JSON or CSV backup file';

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
  String get backupCompleteTitle => 'Backup Complete';

  @override
  String get backupCompleteMessage =>
      'Your backup file has been saved to the location you selected.';

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
  String get paywallTrialTitle => 'Would you like to keep\nthis habit going?';

  @override
  String get paywallTrialDescription =>
      'With Pro, all your workout records are saved, so you can look back on your progress and keep training.';

  @override
  String get paywallTrialNotice =>
      'You can cancel anytime during the free trial.';

  @override
  String get paywallCtaStartTrial => 'Continue for free';

  @override
  String get settingsManageSubscription => 'Manage Subscription';

  @override
  String get settingsManageSubscriptionHint =>
      'Cancel or change your subscription';

  @override
  String get paywallSubscriptionDisclaimer =>
      'Payment will be charged to your Apple ID account at the end of the free trial. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage and cancel your subscription in your Apple ID account settings.';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortByDateDesc => 'Date (Newest)';

  @override
  String get sortByDateAsc => 'Date (Oldest)';

  @override
  String get sortByWeightDesc => 'Weight (Heaviest)';

  @override
  String get sortByWeightAsc => 'Weight (Lightest)';

  @override
  String get sortByRepsDesc => 'Reps (Most)';

  @override
  String get sortByRepsAsc => 'Reps (Least)';

  @override
  String get sortByTimeDesc => 'Time (Longest)';

  @override
  String get sortByTimeAsc => 'Time (Shortest)';

  @override
  String get sortByDistanceDesc => 'Distance (Longest)';

  @override
  String get sortByDistanceAsc => 'Distance (Shortest)';

  @override
  String get bodyWeightTitle => 'Body Weight';

  @override
  String get bodyWeightLabel => 'Weight';

  @override
  String get bodyWeightMemoHint => 'Memo (optional, e.g., before breakfast)';

  @override
  String get bodyWeightSaved => 'Body weight saved';

  @override
  String get bodyWeightUpdated => 'Body weight updated';

  @override
  String get bodyWeightDeleted => 'Record deleted';

  @override
  String get bodyWeightNoData => 'No body weight records yet. Start recording!';

  @override
  String get bodyWeightDeleteConfirm => 'Delete this record?';

  @override
  String get bodyWeightSummary => 'Summary';

  @override
  String get bodyWeightCurrentWeight => 'Current';

  @override
  String get bodyWeightStartingWeight => 'Starting';

  @override
  String get bodyWeightTotalChange => 'Change';

  @override
  String get bodyWeightMinWeight => 'Min';

  @override
  String get bodyWeightMaxWeight => 'Max';

  @override
  String get bodyWeightTotalRecords => 'Records';

  @override
  String get bodyWeightInsightTitle => 'Monthly Insight';

  @override
  String bodyWeightInsightMessage(int workoutCount, String weightChange) {
    return 'This month: $workoutCount workouts, weight change: $weightChange';
  }

  @override
  String bodyWeightInsightNoData(int workoutCount) {
    return 'This month: $workoutCount workouts. Record your weight to see trends!';
  }

  @override
  String get bodyWeightHistory => 'History';

  @override
  String get importDataMigrationSection => 'Data Migration';

  @override
  String get importKintoreMemoTitle => 'Import from KintoreMemo (Realm)';

  @override
  String get importKintoreMemoDescription =>
      'Import default.realm exported via iMazing etc.';

  @override
  String get importSelectFile => 'Select File';

  @override
  String get importAnalyzing => 'Analyzing...';

  @override
  String get importPreviewTitle => 'Preview';

  @override
  String importPreviewWorkoutCount(Object count) {
    return 'Exercises: $count';
  }

  @override
  String importPreviewTotalSets(Object count) {
    return 'Sets: $count';
  }

  @override
  String importPreviewDateRange(Object end, Object start) {
    return 'Date range: $start - $end';
  }

  @override
  String importPreviewSampleExercises(Object exercises) {
    return 'Sample exercises: $exercises';
  }

  @override
  String get importExecute => 'Import';

  @override
  String importSuccess(Object session, Object set) {
    return 'Import complete (sessions: $session, sets: $set)';
  }

  @override
  String get importErrorEncrypted =>
      'This Realm file is encrypted. Please select an unencrypted file.';

  @override
  String get importErrorSchemaMismatch =>
      'Invalid file format. Please select default.realm from KintoreMemo.';

  @override
  String get importErrorInvalidFile =>
      'Invalid file. Please select a .realm file.';

  @override
  String importErrorUnknown(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get importGuideTitle => 'How to get the Realm file';

  @override
  String get importGuideStep1Title => 'Connect to PC';

  @override
  String get importGuideStep1Desc =>
      'Connect your iPhone to a PC/Mac and open a file management tool such as iMazing or 3uTools.';

  @override
  String get importGuideStep2Title => 'Find the file';

  @override
  String get importGuideStep2Desc =>
      'Open the KintoreMemo app folder and find \"default.realm\" in the Documents directory.';

  @override
  String get importGuideStep3Title => 'Transfer to device';

  @override
  String get importGuideStep3Desc =>
      'Export the file and send it to your iPhone\'s Files app via AirDrop, iCloud Drive, or email.';

  @override
  String get importGuideTip =>
      'After transferring, tap \"Select File\" below to pick the .realm file from the Files app.';

  @override
  String get importReimportTitle => 'Already Imported';

  @override
  String get importReimportMessage =>
      'This data has already been imported. Would you like to clear the previous import and re-import?';

  @override
  String get importReimportCancel => 'Cancel';

  @override
  String get importReimportConfirm => 'Re-import';

  @override
  String get importCsvTitle => 'Import from CSV';

  @override
  String get importCsvDescription =>
      'Import data from a CSV or JSON file exported by Liftly. Existing data will be overwritten.';

  @override
  String get importCsvTileDescription =>
      'Import from CSV/JSON exported by Liftly';

  @override
  String get importCsvSelectFile => 'Select File';

  @override
  String get importCsvFormatHint =>
      'Select a CSV or JSON file exported by Liftly\'s backup feature.';

  @override
  String get workoutCompletionTitle => 'Workout Recorded';

  @override
  String workoutCompletionSummary(
    int exerciseCount,
    int setCount,
    String volume,
    String unit,
  ) {
    return '$exerciseCount exercises, $setCount sets, $volume$unit total volume';
  }

  @override
  String workoutCompletionExerciseLine(
    String name,
    int setCount,
    String weight,
    String unit,
  ) {
    return '$name $setCount sets, top weight $weight$unit';
  }

  @override
  String workoutCompletionExerciseLineTime(
    String name,
    int setCount,
    String duration,
  ) {
    return '$name $setCount sets, best $duration';
  }

  @override
  String get syncSectionTitle => 'Sync (Pro)';

  @override
  String get syncSectionDescription =>
      'Save data to the cloud for use across devices';

  @override
  String get syncSignUp => 'Sign up';

  @override
  String get syncLogin => 'Log in';

  @override
  String get syncSignInWithGoogle => 'Sign in with Google';

  @override
  String get syncSigningIn => 'Signing in...';

  @override
  String get syncSignOut => 'Sign out';

  @override
  String get syncSignUpSuccess => 'Account created.';

  @override
  String get syncSignUpConfirmEmail =>
      'If email confirmation is enabled, check your email and confirm, then log in.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncSyncSuccess => 'Sync completed';

  @override
  String get syncSyncFailed => 'Sync failed';

  @override
  String syncSyncFailedWithReason(String reason) {
    return 'Sync failed: $reason';
  }

  @override
  String get syncRegisterButton => 'Register';

  @override
  String get syncSignUpEmailAlreadyRegistered =>
      'This email address is already registered.';

  @override
  String get syncForgotPassword => 'Forgot password?';

  @override
  String get syncResetEmailPrompt =>
      'Enter your registered email address. We will send you a reset link.';

  @override
  String get syncSendResetLink => 'Send reset email';

  @override
  String get syncResetEmailSent =>
      'We have sent a password reset email. Please follow the link in the email to set a new password.';

  @override
  String get syncResetEmailLimitExceeded =>
      'Email send rate limit reached. Please try again in about an hour. For production, configure custom SMTP in the Supabase dashboard.';

  @override
  String get syncInProgress => 'Syncing...';

  @override
  String get syncManualHint =>
      'Sync is manual. Use \"Push to cloud\" or \"Pull from cloud\" to sync.';

  @override
  String get syncPushToServer => 'Push to cloud';

  @override
  String get syncPullFromServer => 'Pull from cloud';

  @override
  String get syncPushShort => 'Push';

  @override
  String get syncPullShort => 'Pull';

  @override
  String get syncConfirmTitle => 'Confirm';

  @override
  String get syncConfirmPushMessage =>
      'All cloud data will be replaced by this device\'s data.';

  @override
  String get syncConfirmPullMessage =>
      'All device data will be replaced by cloud data.';

  @override
  String get syncConfirmExecute => 'Execute';

  @override
  String syncLastSynced(String time) {
    return 'Last synced: $time';
  }

  @override
  String get syncNotSignedIn => 'Not signed in';

  @override
  String get syncNotConfigured => 'Supabase not configured';

  @override
  String get paywallCompareSync => 'Sync';

  @override
  String get csvGuideOpenButton => 'CSV format guide';

  @override
  String get csvGuideTitle => 'CSV format for import';

  @override
  String get csvGuideIntro =>
      'The CSV file must have a header row and data rows. Column order and names must match the table below.';

  @override
  String get csvGuideRequired => 'Required';

  @override
  String get csvGuideOptional => 'Optional';

  @override
  String get csvGuideSampleTitle => 'Sample (first 2 data rows)';

  @override
  String get csvGuideNotesTitle => 'Notes';

  @override
  String get csvGuideNoteEncoding =>
      'Save as UTF-8 (e.g. \"UTF-8 CSV\" in Excel).';

  @override
  String get csvGuideNoteDate =>
      'Date: YYYY-MM-DD or YYYY/MM/DD. Start time: ISO8601 (e.g. 2024-01-15T19:30:00.000) or leave empty.';

  @override
  String get csvGuideNoteQuotes =>
      'If a cell contains a comma or newline, wrap the whole cell in double quotes.';

  @override
  String get csvGuideColSessionDate => 'Workout date (YYYY-MM-DD etc.)';

  @override
  String get csvGuideColSessionStartedAt =>
      'Session start time (ISO8601 or empty)';

  @override
  String get csvGuideColExerciseName => 'Exercise name';

  @override
  String get csvGuideColBodyPart => 'Body part (e.g. chest, back; optional)';

  @override
  String get csvGuideColSetNumber => 'Set number (1, 2, 3…)';

  @override
  String get csvGuideColWeightKg => 'Weight (kg)';

  @override
  String get csvGuideColWeightLb => 'Weight (lb)';

  @override
  String get csvGuideColReps => 'Reps (leave empty for time-based)';

  @override
  String get csvGuideColDurationSeconds => 'Duration in seconds (optional)';

  @override
  String get csvGuideColDistanceMeters => 'Distance in meters (optional)';

  @override
  String get csvGuideColMemo => 'Memo (optional)';
}
