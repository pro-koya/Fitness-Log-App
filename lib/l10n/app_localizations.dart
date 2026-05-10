import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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
    Locale('en'),
    Locale('ja'),
  ];

  /// Welcome message on initial setup screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Liftly'**
  String get welcomeMessage;

  /// Label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// Label for unit selection
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitLb.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get unitLb;

  /// Button to complete initial setup
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @initialSetupWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get initialSetupWeightLabel;

  /// No description provided for @initialSetupDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get initialSetupDistanceLabel;

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Liftly'**
  String get appName;

  /// No description provided for @exerciseListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exerciseListTooltip;

  /// No description provided for @tutorialStartWorkoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap this button to start your workout'**
  String get tutorialStartWorkoutMessage;

  /// No description provided for @homeDifferentiatorHint.
  ///
  /// In en, this message translates to:
  /// **'Copy last set in one tap. Rest timer built in.'**
  String get homeDifferentiatorHint;

  /// Button to start new workout session
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkoutButton;

  /// Button to resume in-progress workout
  ///
  /// In en, this message translates to:
  /// **'Resume Workout'**
  String get resumeWorkoutButton;

  /// Button to start new workout when there's in-progress session
  ///
  /// In en, this message translates to:
  /// **'Start New'**
  String get newWorkoutButton;

  /// Summary of in-progress workout
  ///
  /// In en, this message translates to:
  /// **'{exerciseCount} exercises, {setCount} sets'**
  String workoutInProgressSummary(int exerciseCount, int setCount);

  /// Button to open settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsButton;

  /// Button to add exercise
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExerciseButton;

  /// No description provided for @workoutEmptyStateHint.
  ///
  /// In en, this message translates to:
  /// **'Add an exercise to start logging sets'**
  String get workoutEmptyStateHint;

  /// Button to complete workout
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeButton;

  /// Title of tutorial completion dialog
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get tutorialCompletionTitle;

  /// Message shown when tutorial is completed
  ///
  /// In en, this message translates to:
  /// **'You\'re ready to start logging your workouts. Tap Complete when you finish a session.'**
  String get tutorialCompletionMessage;

  /// Label for previous record
  ///
  /// In en, this message translates to:
  /// **'Previous: {records}'**
  String previousRecord(String records);

  /// Label when there's no previous record
  ///
  /// In en, this message translates to:
  /// **'Previous: —'**
  String get previousRecordNone;

  /// Button to reproduce all sets from previous
  ///
  /// In en, this message translates to:
  /// **'Reproduce Previous'**
  String get reproduceButton;

  /// Button to add set
  ///
  /// In en, this message translates to:
  /// **'Add Set'**
  String get addSetButton;

  /// Label for set number
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String setLabel(int number);

  /// Label for weight input
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// Label for reps input
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// Button to copy from previous
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// Button to delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// Label for timer
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerLabel;

  /// No description provided for @timerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timerStart;

  /// No description provided for @timerPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get timerPause;

  /// No description provided for @timerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get timerReset;

  /// No description provided for @timerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get timerClose;

  /// No description provided for @timerRestComplete.
  ///
  /// In en, this message translates to:
  /// **'Rest Complete!'**
  String get timerRestComplete;

  /// No description provided for @timerRestCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Your rest time is over. Ready for the next set?'**
  String get timerRestCompleteMessage;

  /// No description provided for @timerTapTimeToSet.
  ///
  /// In en, this message translates to:
  /// **'Tap time to set'**
  String get timerTapTimeToSet;

  /// No description provided for @timerQuickStart.
  ///
  /// In en, this message translates to:
  /// **'Quick Start'**
  String get timerQuickStart;

  /// No description provided for @timerNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Timer ended'**
  String get timerNotificationTitle;

  /// No description provided for @timerNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your rest timer has finished.'**
  String get timerNotificationBody;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so we can tell you when your rest timer ends, even when the app is in the background.'**
  String get notificationPermissionMessage;

  /// No description provided for @notificationPermissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get notificationPermissionAllow;

  /// No description provided for @notificationPermissionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notificationPermissionNotNow;

  /// No description provided for @notificationSettingsEnableLabel.
  ///
  /// In en, this message translates to:
  /// **'Send notifications'**
  String get notificationSettingsEnableLabel;

  /// No description provided for @notificationStateOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get notificationStateOn;

  /// No description provided for @notificationStateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notificationStateOff;

  /// No description provided for @notificationSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSectionLabel;

  /// Title for settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Button to go back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// Title for workout detail screen
  ///
  /// In en, this message translates to:
  /// **'Workout Detail'**
  String get workoutDetailTitle;

  /// AppBar title for workout input screen
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutInputTitle;

  /// Session time range
  ///
  /// In en, this message translates to:
  /// **'{startTime} - {endTime}'**
  String sessionTime(String startTime, String endTime);

  /// Message when there's no workout
  ///
  /// In en, this message translates to:
  /// **'No workout recorded on this day.'**
  String get emptyStateMessage;

  /// Title for exercise progress screen
  ///
  /// In en, this message translates to:
  /// **'Exercise Progress'**
  String get exerciseProgressTitle;

  /// Label for top weight metric
  ///
  /// In en, this message translates to:
  /// **'Top Weight'**
  String get topWeightLabel;

  /// Label for total volume metric
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolumeLabel;

  /// Message when there's not enough data for graph
  ///
  /// In en, this message translates to:
  /// **'Not enough data to show graph. Keep recording your workouts!'**
  String get emptyProgressMessage;

  /// Title for delete set confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this set?'**
  String get deleteSetConfirmTitle;

  /// Message for delete set confirmation
  ///
  /// In en, this message translates to:
  /// **'Set {number}: {weight}{unit}/{reps} reps'**
  String deleteSetConfirmMessage(
    int number,
    double weight,
    String unit,
    int reps,
  );

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirmButton;

  /// General error message
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(String error);

  /// No description provided for @errorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorLoadFailed;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Label for recent workouts section
  ///
  /// In en, this message translates to:
  /// **'Recent Workouts'**
  String get recentWorkoutsLabel;

  /// No description provided for @navHomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get navHomeLabel;

  /// No description provided for @navHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistoryLabel;

  /// No description provided for @navListLabel.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get navListLabel;

  /// No description provided for @navWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get navWeightLabel;

  /// No description provided for @listMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse exercises, records, and memos'**
  String get listMenuSubtitle;

  /// No description provided for @listMenuExerciseListDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your registered exercises'**
  String get listMenuExerciseListDescription;

  /// No description provided for @listMenuAllRecordsDescription.
  ///
  /// In en, this message translates to:
  /// **'View all workout records by date'**
  String get listMenuAllRecordsDescription;

  /// No description provided for @listMenuMemoSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Search memos by keyword'**
  String get listMenuMemoSearchDescription;

  /// No description provided for @navSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettingsLabel;

  /// Error message when workouts fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading workouts'**
  String get errorLoadingWorkouts;

  /// Message when there's no workout history
  ///
  /// In en, this message translates to:
  /// **'No workout history yet'**
  String get noWorkoutHistory;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDate;

  /// Duration label with time
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String durationLabel(String duration);

  /// Duration format with hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}min'**
  String durationHoursMinutes(int hours, int minutes);

  /// Duration format with minutes only
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @workoutInProgress.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get workoutInProgress;

  /// Button to start a new workout
  ///
  /// In en, this message translates to:
  /// **'Start New Workout'**
  String get startNewWorkoutButton;

  /// No description provided for @editWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Workout'**
  String get editWorkoutButton;

  /// No description provided for @deleteWorkoutButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Workout'**
  String get deleteWorkoutButton;

  /// Label for number of sets
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String setsCountLabel(int count);

  /// No description provided for @noSetsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No sets recorded'**
  String get noSetsRecorded;

  /// No description provided for @deleteWorkoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Workout'**
  String get deleteWorkoutDialogTitle;

  /// No description provided for @deleteWorkoutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this workout? This action cannot be undone.'**
  String get deleteWorkoutDialogMessage;

  /// Error message when workout deletion fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting workout: {error}'**
  String errorDeletingWorkout(String error);

  /// Button to save settings
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Message shown when settings are saved successfully
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @settingsUnsavedHint.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes'**
  String get settingsUnsavedHint;

  /// Shows the number of workouts completed this month
  ///
  /// In en, this message translates to:
  /// **'{count} workouts'**
  String monthlyWorkoutCount(int count);

  /// Label for this month's workout count
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonthLabel;

  /// Label for workout streak
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakLabel;

  /// Shows the current workout streak in days
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String streakDays(int count);

  /// Label for average weight in monthly summary
  ///
  /// In en, this message translates to:
  /// **'Avg. Weight'**
  String get averageWeightLabel;

  /// Title for calendar month/year picker dialog
  ///
  /// In en, this message translates to:
  /// **'Select month & year'**
  String get selectMonthYear;

  /// No description provided for @lastMonthShort.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonthShort;

  /// No description provided for @thisMonthShort.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonthShort;

  /// No description provided for @nextMonthShort.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonthShort;

  /// No description provided for @allRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Records'**
  String get allRecordsTitle;

  /// Total number of training sessions
  ///
  /// In en, this message translates to:
  /// **'{count} workouts total'**
  String totalWorkoutsCount(int count);

  /// No description provided for @moreExercisesHint.
  ///
  /// In en, this message translates to:
  /// **'+{count} more…'**
  String moreExercisesHint(int count);

  /// No description provided for @tapForDetailHint.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get tapForDetailHint;

  /// No description provided for @exerciseAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get exerciseAlreadyAdded;

  /// Placeholder text for exercise search field
  ///
  /// In en, this message translates to:
  /// **'Search exercises...'**
  String get searchExercisePlaceholder;

  /// Title for exercise selection modal
  ///
  /// In en, this message translates to:
  /// **'Select Exercise'**
  String get selectExerciseTitle;

  /// Button to add a custom exercise
  ///
  /// In en, this message translates to:
  /// **'Add Custom Exercise'**
  String get addCustomExerciseButton;

  /// Title for custom exercise input dialog
  ///
  /// In en, this message translates to:
  /// **'Add Custom Exercise'**
  String get customExerciseDialogTitle;

  /// Label for exercise name input
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseNameLabel;

  /// Button to add item
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// Title for history screen
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// Button to view workout details
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsButton;

  /// Number of exercises in a workout
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String exerciseCount(int count);

  /// Number of sets in a workout
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String setCount(int count);

  /// Title for workout summary
  ///
  /// In en, this message translates to:
  /// **'Workout on {date}'**
  String workoutSummaryTitle(String date);

  /// Message when there are no workouts in the current month
  ///
  /// In en, this message translates to:
  /// **'No workouts this month'**
  String get noWorkoutsThisMonth;

  /// Title for delete exercise confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Exercise?'**
  String get deleteExerciseDialogTitle;

  /// Message for delete exercise confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{exerciseName}\"? This will remove all sets for this exercise.'**
  String deleteExerciseDialogMessage(String exerciseName);

  /// Title for delete custom exercise confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Custom Exercise?'**
  String get deleteCustomExerciseDialogTitle;

  /// Message for delete custom exercise confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{exerciseName}\"? This action cannot be undone.'**
  String deleteCustomExerciseDialogMessage(String exerciseName);

  /// Snackbar message when exercise is deleted
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{exerciseName}\"'**
  String exerciseDeleted(String exerciseName);

  /// Title for exercise history dialog
  ///
  /// In en, this message translates to:
  /// **'Exercise History'**
  String get exerciseHistoryTitle;

  /// Message when there's no history for an exercise
  ///
  /// In en, this message translates to:
  /// **'No history available'**
  String get noHistoryAvailable;

  /// Label for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Label for yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Label for days ago
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// Label for weeks ago
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeksAgo(int count);

  /// Label for months ago
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgo(int count);

  /// Label for years ago
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String yearsAgo(int count);

  /// Title for monthly summary section
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get monthlySummary;

  /// Label for total training duration
  ///
  /// In en, this message translates to:
  /// **'Total Duration'**
  String get totalDuration;

  /// Label for total sets count
  ///
  /// In en, this message translates to:
  /// **'Total Sets'**
  String get totalSets;

  /// Label for total volume (weight/reps)
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolume;

  /// Label for total time (for time-based exercises)
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get totalTime;

  /// Unit for sets
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get setsUnit;

  /// Title for most frequent exercises
  ///
  /// In en, this message translates to:
  /// **'Top Exercises'**
  String get topExercises;

  /// Unit for frequency count
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get timesUnit;

  /// Title for weekly workout trend chart
  ///
  /// In en, this message translates to:
  /// **'Weekly Trend'**
  String get weeklyTrend;

  /// Label for memo section
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get memoLabel;

  /// Title for memo history section
  ///
  /// In en, this message translates to:
  /// **'Memo History'**
  String get memoHistory;

  /// Message when there's no memo
  ///
  /// In en, this message translates to:
  /// **'No memo'**
  String get noMemoRecorded;

  /// Title for memo search screen
  ///
  /// In en, this message translates to:
  /// **'Search Memos'**
  String get memoSearch;

  /// Placeholder for memo search input
  ///
  /// In en, this message translates to:
  /// **'Search by keyword...'**
  String get memoSearchPlaceholder;

  /// Message when no memos match the search
  ///
  /// In en, this message translates to:
  /// **'No memos found'**
  String get memoSearchNoResults;

  /// Hint text for memo search
  ///
  /// In en, this message translates to:
  /// **'Enter a keyword to search your workout memos'**
  String get memoSearchHint;

  /// Label for previous record section
  ///
  /// In en, this message translates to:
  /// **'Previous:'**
  String get previousLabel;

  /// Button to view exercise history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyButton;

  /// Button to reproduce previous sets
  ///
  /// In en, this message translates to:
  /// **'Reproduce Previous'**
  String get reproducePreviousButton;

  /// Placeholder text for memo input
  ///
  /// In en, this message translates to:
  /// **'Add notes (e.g., form cues, how it felt...)'**
  String get memoPlaceholder;

  /// Button to show less items
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// Button to show more sets
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String showMoreSets(int count);

  /// Tooltip for delete exercise button
  ///
  /// In en, this message translates to:
  /// **'Delete exercise'**
  String get deleteExerciseTooltip;

  /// Tab label for weight chart
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightTab;

  /// Tab label for reps chart
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsTab;

  /// Tab label for volume chart
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeTab;

  /// Message when there's no data for exercise progress
  ///
  /// In en, this message translates to:
  /// **'No workout data found for this exercise.'**
  String get noDataForExercise;

  /// Label for summary section
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryLabel;

  /// Label for total workouts count
  ///
  /// In en, this message translates to:
  /// **'Total Workouts'**
  String get totalWorkouts;

  /// Label for latest top weight
  ///
  /// In en, this message translates to:
  /// **'Latest Top Weight'**
  String get latestTopWeight;

  /// Label for latest best time
  ///
  /// In en, this message translates to:
  /// **'Latest Best Time'**
  String get latestBestTime;

  /// Label for latest top reps
  ///
  /// In en, this message translates to:
  /// **'Latest Top Reps'**
  String get latestTopReps;

  /// Label for latest top volume
  ///
  /// In en, this message translates to:
  /// **'Latest Top Volume'**
  String get latestTopVolume;

  /// Label for starting weight
  ///
  /// In en, this message translates to:
  /// **'Starting Weight'**
  String get startingWeight;

  /// Label for starting best time
  ///
  /// In en, this message translates to:
  /// **'Starting Best Time'**
  String get startingBestTime;

  /// Label for starting top reps
  ///
  /// In en, this message translates to:
  /// **'Starting Top Reps'**
  String get startingTopReps;

  /// Label for starting top volume
  ///
  /// In en, this message translates to:
  /// **'Starting Top Volume'**
  String get startingTopVolume;

  /// No description provided for @maxTopVolume.
  ///
  /// In en, this message translates to:
  /// **'Max Top Volume'**
  String get maxTopVolume;

  /// Label for improvement stat
  ///
  /// In en, this message translates to:
  /// **'Improvement'**
  String get improvement;

  /// No description provided for @allTimeBestSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'All-time best'**
  String get allTimeBestSectionTitle;

  /// No description provided for @allTimeMaxWeight.
  ///
  /// In en, this message translates to:
  /// **'All-time max weight'**
  String get allTimeMaxWeight;

  /// No description provided for @allTimeMaxReps.
  ///
  /// In en, this message translates to:
  /// **'All-time max reps'**
  String get allTimeMaxReps;

  /// No description provided for @allTimeMaxVolume.
  ///
  /// In en, this message translates to:
  /// **'All-time max volume'**
  String get allTimeMaxVolume;

  /// Label for best reps achieved at each weight
  ///
  /// In en, this message translates to:
  /// **'Best reps by weight'**
  String get bestRepsByWeight;

  /// Unit for reps
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsUnit;

  /// Message when there are no workouts for a specific body part this month
  ///
  /// In en, this message translates to:
  /// **'No {bodyPart} workouts recorded this month.'**
  String noBodyPartWorkoutsThisMonth(String bodyPart);

  /// Label for distance unit selection
  ///
  /// In en, this message translates to:
  /// **'Distance Unit'**
  String get distanceUnitLabel;

  /// Kilometers unit
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get distanceUnitKm;

  /// Miles unit
  ///
  /// In en, this message translates to:
  /// **'mile'**
  String get distanceUnitMile;

  /// Tab label for time chart
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeTab;

  /// Tab label for distance chart
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceTab;

  /// Tab label for pace chart
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get paceTab;

  /// Label for latest best distance
  ///
  /// In en, this message translates to:
  /// **'Latest Best Distance'**
  String get latestBestDistance;

  /// Label for starting best distance
  ///
  /// In en, this message translates to:
  /// **'Starting Best Distance'**
  String get startingBestDistance;

  /// Paywall title for history - affirms value of user's effort
  ///
  /// In en, this message translates to:
  /// **'Keep all your workout history'**
  String get paywallTitleHistory;

  /// Paywall title for chart - gentle invitation to see growth
  ///
  /// In en, this message translates to:
  /// **'See how you\'re progressing'**
  String get paywallTitleChart;

  /// Paywall title for theme - personal connection
  ///
  /// In en, this message translates to:
  /// **'Make it truly yours'**
  String get paywallTitleTheme;

  /// Paywall title for stats - reflection helps consistency
  ///
  /// In en, this message translates to:
  /// **'Understand your training habits'**
  String get paywallTitleStats;

  /// Paywall title for export feature
  ///
  /// In en, this message translates to:
  /// **'Export your data'**
  String get paywallTitleExport;

  /// Paywall body for history - affirms user's effort
  ///
  /// In en, this message translates to:
  /// **'Your training so far has real value. With Pro, you can keep and review all your workout records anytime.'**
  String get paywallBodyHistory;

  /// Paywall body for chart - numbers as proof of consistency
  ///
  /// In en, this message translates to:
  /// **'Changes in numbers show your consistency. With Pro, you can track your progress through clear and simple charts.'**
  String get paywallBodyChart;

  /// Paywall body for theme - comfort supports habit
  ///
  /// In en, this message translates to:
  /// **'When something feels right, it\'s easier to keep going. With Pro, you can customize the app\'s theme to match your style.'**
  String get paywallBodyTheme;

  /// Paywall body for stats - reflection reinforces habit
  ///
  /// In en, this message translates to:
  /// **'Looking back helps you stay consistent. With Pro, you can review detailed weekly and monthly training statistics.'**
  String get paywallBodyStats;

  /// Paywall body for export feature
  ///
  /// In en, this message translates to:
  /// **'Export your workout data to CSV. Available with Pro.'**
  String get paywallBodyExport;

  /// CTA button text for trying Pro
  ///
  /// In en, this message translates to:
  /// **'Try Pro'**
  String get paywallCtaTryPro;

  /// Secondary CTA for dismissing paywall
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get paywallCtaNotNow;

  /// Comparison table row for history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get paywallCompareHistory;

  /// Free tier history limit
  ///
  /// In en, this message translates to:
  /// **'Last 30'**
  String get paywallCompareLast20;

  /// Pro tier unlimited access
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get paywallCompareUnlimited;

  /// Comparison table row for charts
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get paywallCompareCharts;

  /// Comparison table row for theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get paywallCompareTheme;

  /// Comparison table combined row for charts and theme
  ///
  /// In en, this message translates to:
  /// **'Charts & Theme'**
  String get paywallCompareChartsTheme;

  /// Comparison table row for ads
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get paywallCompareAds;

  /// Free tier: ads are shown
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get paywallCompareAdsShow;

  /// Pro tier: ads are hidden
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get paywallCompareAdsHide;

  /// Free tier default theme
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get paywallCompareDefault;

  /// Pro tier custom theme
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get paywallCompareCustom;

  /// Hint for locked session
  ///
  /// In en, this message translates to:
  /// **'Unlock full history with Pro'**
  String get lockedSessionHint;

  /// Sub hint for locked session
  ///
  /// In en, this message translates to:
  /// **'Free shows the latest 30 sessions. Go Pro to view everything.'**
  String get lockedSessionSubHint;

  /// Pro label
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proLabel;

  /// Free label
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeLabel;

  /// Monthly price for Pro
  ///
  /// In en, this message translates to:
  /// **'¥150/month'**
  String get paywallPriceMonthly;

  /// Yearly price for Pro
  ///
  /// In en, this message translates to:
  /// **'¥1,500/year'**
  String get paywallPriceYearly;

  /// Or separator between prices
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get paywallPriceOr;

  /// Button to share workout to SNS
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareWorkoutButton;

  /// Title for workout share dialog
  ///
  /// In en, this message translates to:
  /// **'Share Workout'**
  String get shareWorkoutDialogTitle;

  /// Button to copy text to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// Message when text is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied to Clipboard'**
  String get copiedToClipboard;

  /// Title for theme settings screen
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettingsTitle;

  /// Label for preset themes section
  ///
  /// In en, this message translates to:
  /// **'Preset Themes'**
  String get presetThemesLabel;

  /// Label for custom colors section
  ///
  /// In en, this message translates to:
  /// **'Custom Colors'**
  String get customColorsLabel;

  /// Label for primary color
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get primaryColorLabel;

  /// Label for secondary color
  ///
  /// In en, this message translates to:
  /// **'Secondary Color'**
  String get secondaryColorLabel;

  /// Label for theme preview section
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// Label for reset to default button
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefaultLabel;

  /// Confirmation message for resetting theme
  ///
  /// In en, this message translates to:
  /// **'Reset theme settings to default?'**
  String get resetThemeConfirmMessage;

  /// Warning message for low contrast
  ///
  /// In en, this message translates to:
  /// **'Low contrast may affect readability'**
  String get contrastWarning;

  /// Label for theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get themeCustomLabel;

  /// Error message for invalid hex color
  ///
  /// In en, this message translates to:
  /// **'Invalid color code'**
  String get invalidHexColor;

  /// Hint for hex color input
  ///
  /// In en, this message translates to:
  /// **'e.g. #1976D2'**
  String get hexColorHint;

  /// Title for color picker
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// Tooltip for color palette button
  ///
  /// In en, this message translates to:
  /// **'Color Palette'**
  String get colorPalette;

  /// Basic color category
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get colorCategoryBasic;

  /// Red color category
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorCategoryRed;

  /// Pink color category
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorCategoryPink;

  /// Purple color category
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorCategoryPurple;

  /// Blue color category
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorCategoryBlue;

  /// Green color category
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorCategoryGreen;

  /// Orange color category
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorCategoryOrange;

  /// Brown color category
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorCategoryBrown;

  /// Paywall title for backup - protect valuable records
  ///
  /// In en, this message translates to:
  /// **'Keep your records safe'**
  String get paywallTitleBackup;

  /// Paywall body for backup - records deserve protection
  ///
  /// In en, this message translates to:
  /// **'Your workout history is worth protecting. With Pro, you can back up your data and keep it safe.'**
  String get paywallBodyBackup;

  /// Paywall title for hiding ads with Pro
  ///
  /// In en, this message translates to:
  /// **'Hide ads and focus on your workout'**
  String get paywallTitleAds;

  /// Paywall body for ads - Pro benefits
  ///
  /// In en, this message translates to:
  /// **'With Pro, ads are removed and you get full access to history, theme, backup, and more.'**
  String get paywallBodyAds;

  /// Settings section label for plan/subscription
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get settingsPlanSection;

  /// Button to open paywall from settings
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get settingsUpgradeToPro;

  /// Short description of Pro benefits
  ///
  /// In en, this message translates to:
  /// **'Hide ads, full history, theme, backup & more'**
  String get settingsProPlanDescription;

  /// No description provided for @proValueOneLiner.
  ///
  /// In en, this message translates to:
  /// **'Sync across devices & no ads—focus on logging'**
  String get proValueOneLiner;

  /// Gentle CTA near banner ad to lead to Pro
  ///
  /// In en, this message translates to:
  /// **'Hide ads with Pro?'**
  String get adHideWithProCta;

  /// Label for backup section
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupLabel;

  /// Title for backup screen
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupTitle;

  /// No description provided for @backupSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Save data to transfer to another device'**
  String get backupSettingsDescription;

  /// Title for backup creation section
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get backupSectionTitle;

  /// Description for backup section
  ///
  /// In en, this message translates to:
  /// **'Export all your workout data to a file'**
  String get backupSectionDescription;

  /// Label for backup format selection
  ///
  /// In en, this message translates to:
  /// **'Backup format'**
  String get backupFormatLabel;

  /// JSON format option - can restore in app
  ///
  /// In en, this message translates to:
  /// **'JSON (for restore)'**
  String get backupFormatJson;

  /// CSV format option - for spreadsheets/analysis
  ///
  /// In en, this message translates to:
  /// **'CSV (for analysis)'**
  String get backupFormatCsv;

  /// Button to create backup
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackupButton;

  /// Title for restore section
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreSectionTitle;

  /// Description for restore section
  ///
  /// In en, this message translates to:
  /// **'Import data from a JSON or CSV backup file'**
  String get restoreSectionDescription;

  /// Button to select backup file
  ///
  /// In en, this message translates to:
  /// **'Select Backup File'**
  String get restoreBackupButton;

  /// Warning about restore overwriting data
  ///
  /// In en, this message translates to:
  /// **'Restoring will overwrite all current data. Make sure to backup current data first if needed.'**
  String get backupWarning;

  /// Loading message while creating backup
  ///
  /// In en, this message translates to:
  /// **'Creating backup...'**
  String get creatingBackup;

  /// Success message when backup is created
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreated;

  /// Title for backup success dialog
  ///
  /// In en, this message translates to:
  /// **'Backup Complete'**
  String get backupCompleteTitle;

  /// Message for backup success dialog
  ///
  /// In en, this message translates to:
  /// **'Your backup file has been saved to the location you selected.'**
  String get backupCompleteMessage;

  /// Loading message while reading backup
  ///
  /// In en, this message translates to:
  /// **'Loading backup file...'**
  String get loadingBackup;

  /// Loading message while restoring data
  ///
  /// In en, this message translates to:
  /// **'Restoring data...'**
  String get restoringData;

  /// Success message when restore is complete
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully'**
  String get restoreCompleted;

  /// Error message for invalid backup file
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file format'**
  String get invalidBackupFile;

  /// Error message for incompatible backup version
  ///
  /// In en, this message translates to:
  /// **'This backup version is not compatible'**
  String get incompatibleBackupVersion;

  /// Title for restore confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Restore Data?'**
  String get restoreConfirmTitle;

  /// Shows backup date in confirmation
  ///
  /// In en, this message translates to:
  /// **'Backup date: {date}'**
  String restoreConfirmBackupDate(String date);

  /// Shows session count in confirmation
  ///
  /// In en, this message translates to:
  /// **'Sessions: {count}'**
  String restoreConfirmSessionCount(int count);

  /// Shows exercise count in confirmation
  ///
  /// In en, this message translates to:
  /// **'Exercises: {count}'**
  String restoreConfirmExerciseCount(int count);

  /// Warning in restore confirmation
  ///
  /// In en, this message translates to:
  /// **'Current data will be overwritten'**
  String get restoreConfirmWarning;

  /// Button to confirm restore
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreButton;

  /// Monthly subscription option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallSubscriptionMonthly;

  /// Yearly subscription option
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallSubscriptionYearly;

  /// Yearly subscription save percentage
  ///
  /// In en, this message translates to:
  /// **'Save 17%'**
  String get paywallSubscriptionYearlySave;

  /// Message while purchase is processing
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get paywallSubscriptionPurchasing;

  /// Error message when purchase fails
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get paywallSubscriptionError;

  /// Button to restore previous purchases
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get paywallRestorePurchases;

  /// No description provided for @paywallRestoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Restore previously purchased Pro plan'**
  String get paywallRestoreDescription;

  /// Message when purchases are restored
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get paywallRestoreSuccess;

  /// Message when no subscription is found
  ///
  /// In en, this message translates to:
  /// **'No active subscription found'**
  String get paywallRestoreNoSubscription;

  /// Message while restoring purchases
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get paywallRestoring;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalTitle;

  /// Terms of service link
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get paywallTermsOfService;

  /// Privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get paywallPrivacyPolicy;

  /// Paywall headline - gentle encouragement to continue
  ///
  /// In en, this message translates to:
  /// **'For ultimate focus.'**
  String get paywallTrialTitle;

  /// Paywall description - focus on state change, not features
  ///
  /// In en, this message translates to:
  /// **'Unlock advanced features with Pro, including ad removal and cloud synchronization.'**
  String get paywallTrialDescription;

  /// Notice about cancellation during trial
  ///
  /// In en, this message translates to:
  /// **'You can cancel anytime during the free trial.'**
  String get paywallTrialNotice;

  /// CTA button text - gentle invitation to try
  ///
  /// In en, this message translates to:
  /// **'Continue for free'**
  String get paywallCtaStartTrial;

  /// Settings menu item for managing subscription
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get settingsManageSubscription;

  /// Hint text for manage subscription
  ///
  /// In en, this message translates to:
  /// **'Cancel or change your subscription'**
  String get settingsManageSubscriptionHint;

  /// No description provided for @subscriptionManagementOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open subscription settings'**
  String get subscriptionManagementOpenError;

  /// Subscription disclaimer for paywall
  ///
  /// In en, this message translates to:
  /// **'Payment will be charged to your Apple ID account at the end of the free trial. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage and cancel your subscription in your Apple ID account settings.'**
  String get paywallSubscriptionDisclaimer;

  /// Label for sort button
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortLabel;

  /// Sort by date descending
  ///
  /// In en, this message translates to:
  /// **'Date (Newest)'**
  String get sortByDateDesc;

  /// Sort by date ascending
  ///
  /// In en, this message translates to:
  /// **'Date (Oldest)'**
  String get sortByDateAsc;

  /// Sort by weight descending
  ///
  /// In en, this message translates to:
  /// **'Weight (Heaviest)'**
  String get sortByWeightDesc;

  /// Sort by weight ascending
  ///
  /// In en, this message translates to:
  /// **'Weight (Lightest)'**
  String get sortByWeightAsc;

  /// Sort by reps descending
  ///
  /// In en, this message translates to:
  /// **'Reps (Most)'**
  String get sortByRepsDesc;

  /// Sort by reps ascending
  ///
  /// In en, this message translates to:
  /// **'Reps (Least)'**
  String get sortByRepsAsc;

  /// Sort by time descending
  ///
  /// In en, this message translates to:
  /// **'Time (Longest)'**
  String get sortByTimeDesc;

  /// Sort by time ascending
  ///
  /// In en, this message translates to:
  /// **'Time (Shortest)'**
  String get sortByTimeAsc;

  /// Sort by distance descending
  ///
  /// In en, this message translates to:
  /// **'Distance (Longest)'**
  String get sortByDistanceDesc;

  /// Sort by distance ascending
  ///
  /// In en, this message translates to:
  /// **'Distance (Shortest)'**
  String get sortByDistanceAsc;

  /// Title for body weight screen
  ///
  /// In en, this message translates to:
  /// **'Body Weight'**
  String get bodyWeightTitle;

  /// Label for body weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get bodyWeightLabel;

  /// Hint for body weight memo input
  ///
  /// In en, this message translates to:
  /// **'Memo (optional, e.g., before breakfast)'**
  String get bodyWeightMemoHint;

  /// Message when body weight is saved
  ///
  /// In en, this message translates to:
  /// **'Body weight saved'**
  String get bodyWeightSaved;

  /// Message when body weight is updated
  ///
  /// In en, this message translates to:
  /// **'Body weight updated'**
  String get bodyWeightUpdated;

  /// Message when body weight record is deleted
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get bodyWeightDeleted;

  /// Message when there are no body weight records
  ///
  /// In en, this message translates to:
  /// **'No body weight records yet. Start recording!'**
  String get bodyWeightNoData;

  /// Confirmation for deleting body weight record
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get bodyWeightDeleteConfirm;

  /// Title for body weight summary section
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get bodyWeightSummary;

  /// Label for current body weight
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get bodyWeightCurrentWeight;

  /// Label for starting body weight
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get bodyWeightStartingWeight;

  /// Label for total body weight change
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get bodyWeightTotalChange;

  /// Label for minimum body weight
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get bodyWeightMinWeight;

  /// Label for maximum body weight
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get bodyWeightMaxWeight;

  /// Label for total body weight records
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get bodyWeightTotalRecords;

  /// Title for monthly insight section
  ///
  /// In en, this message translates to:
  /// **'Monthly Insight'**
  String get bodyWeightInsightTitle;

  /// Monthly insight message with workout count and weight change
  ///
  /// In en, this message translates to:
  /// **'This month: {workoutCount} workouts, weight change: {weightChange}'**
  String bodyWeightInsightMessage(int workoutCount, String weightChange);

  /// Monthly insight when no weight data for this month
  ///
  /// In en, this message translates to:
  /// **'This month: {workoutCount} workouts. Record your weight to see trends!'**
  String bodyWeightInsightNoData(int workoutCount);

  /// Title for body weight history section
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get bodyWeightHistory;

  /// No description provided for @importDataMigrationSection.
  ///
  /// In en, this message translates to:
  /// **'Data Migration'**
  String get importDataMigrationSection;

  /// No description provided for @importFromOtherAppsLabel.
  ///
  /// In en, this message translates to:
  /// **'Import from other apps'**
  String get importFromOtherAppsLabel;

  /// No description provided for @importKintoreMemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from KintoreMemo (Realm)'**
  String get importKintoreMemoTitle;

  /// No description provided for @importKintoreMemoDescription.
  ///
  /// In en, this message translates to:
  /// **'Import default.realm exported via iMazing etc.'**
  String get importKintoreMemoDescription;

  /// No description provided for @importSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get importSelectFile;

  /// No description provided for @importAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get importAnalyzing;

  /// No description provided for @importPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get importPreviewTitle;

  /// No description provided for @importPreviewWorkoutCount.
  ///
  /// In en, this message translates to:
  /// **'Exercises: {count}'**
  String importPreviewWorkoutCount(Object count);

  /// No description provided for @importPreviewTotalSets.
  ///
  /// In en, this message translates to:
  /// **'Sets: {count}'**
  String importPreviewTotalSets(Object count);

  /// No description provided for @importPreviewDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range: {start} - {end}'**
  String importPreviewDateRange(Object end, Object start);

  /// No description provided for @importPreviewSampleExercises.
  ///
  /// In en, this message translates to:
  /// **'Sample exercises: {exercises}'**
  String importPreviewSampleExercises(Object exercises);

  /// No description provided for @importExecute.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importExecute;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import complete (sessions: {session}, sets: {set})'**
  String importSuccess(Object session, Object set);

  /// No description provided for @importErrorEncrypted.
  ///
  /// In en, this message translates to:
  /// **'This Realm file is encrypted. Please select an unencrypted file.'**
  String get importErrorEncrypted;

  /// No description provided for @importErrorSchemaMismatch.
  ///
  /// In en, this message translates to:
  /// **'Invalid file format. Please select default.realm from KintoreMemo.'**
  String get importErrorSchemaMismatch;

  /// No description provided for @importErrorInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid file. Please select a .realm file.'**
  String get importErrorInvalidFile;

  /// No description provided for @importErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importErrorUnknown(Object error);

  /// No description provided for @importGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'How to get the Realm file'**
  String get importGuideTitle;

  /// No description provided for @importGuideStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Connect to PC'**
  String get importGuideStep1Title;

  /// No description provided for @importGuideStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Connect your iPhone to a PC/Mac and open a file management tool such as iMazing or 3uTools.'**
  String get importGuideStep1Desc;

  /// No description provided for @importGuideStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Find the file'**
  String get importGuideStep2Title;

  /// No description provided for @importGuideStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Open the KintoreMemo app folder and find \"default.realm\" in the Documents directory.'**
  String get importGuideStep2Desc;

  /// No description provided for @importGuideStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Transfer to device'**
  String get importGuideStep3Title;

  /// No description provided for @importGuideStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Export the file and send it to your iPhone\'s Files app via AirDrop, iCloud Drive, or email.'**
  String get importGuideStep3Desc;

  /// No description provided for @importGuideTip.
  ///
  /// In en, this message translates to:
  /// **'After transferring, tap \"Select File\" below to pick the .realm file from the Files app.'**
  String get importGuideTip;

  /// No description provided for @importReimportTitle.
  ///
  /// In en, this message translates to:
  /// **'Already Imported'**
  String get importReimportTitle;

  /// No description provided for @importReimportMessage.
  ///
  /// In en, this message translates to:
  /// **'This data has already been imported. Would you like to clear the previous import and re-import?'**
  String get importReimportMessage;

  /// No description provided for @importReimportCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get importReimportCancel;

  /// No description provided for @importReimportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Re-import'**
  String get importReimportConfirm;

  /// No description provided for @importCsvTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV'**
  String get importCsvTitle;

  /// No description provided for @importCsvDescription.
  ///
  /// In en, this message translates to:
  /// **'Import data from a CSV or JSON file exported by Liftly. Existing data will be overwritten.'**
  String get importCsvDescription;

  /// No description provided for @importCsvTileDescription.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV/JSON exported by Liftly'**
  String get importCsvTileDescription;

  /// No description provided for @importCsvSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get importCsvSelectFile;

  /// No description provided for @importCsvFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Select a CSV or JSON file exported by Liftly\'s backup feature.'**
  String get importCsvFormatHint;

  /// No description provided for @workoutCompletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout Recorded'**
  String get workoutCompletionTitle;

  /// Title for in-app review prompt dialog
  ///
  /// In en, this message translates to:
  /// **'Thanks for logging your workouts!'**
  String get reviewPromptTitle;

  /// Message for in-app review prompt dialog
  ///
  /// In en, this message translates to:
  /// **'How does this update feel so far? If you\'d like, we\'d love to hear your feedback in a review.'**
  String get reviewPromptMessage;

  /// Label for star rating in review prompt
  ///
  /// In en, this message translates to:
  /// **'How would you rate the app?'**
  String get reviewPromptRateLabel;

  /// Button to open store review
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get reviewPromptWriteReview;

  /// Button to dismiss review prompt
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get reviewPromptLater;

  /// No description provided for @workoutCompletionSummary.
  ///
  /// In en, this message translates to:
  /// **'{exerciseCount} exercises, {setCount} sets, {volume}{unit} total volume'**
  String workoutCompletionSummary(
    int exerciseCount,
    int setCount,
    String volume,
    String unit,
  );

  /// No description provided for @workoutCompletionExerciseLine.
  ///
  /// In en, this message translates to:
  /// **'{name} {setCount} sets, top weight {weight}{unit}'**
  String workoutCompletionExerciseLine(
    String name,
    int setCount,
    String weight,
    String unit,
  );

  /// No description provided for @workoutCompletionExerciseLineTime.
  ///
  /// In en, this message translates to:
  /// **'{name} {setCount} sets, best {duration}'**
  String workoutCompletionExerciseLineTime(
    String name,
    int setCount,
    String duration,
  );

  /// No description provided for @syncSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Sync'**
  String get syncSectionTitle;

  /// No description provided for @syncSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your training records to the cloud. Synced data can be used for connected features and across devices.'**
  String get syncSectionDescription;

  /// No description provided for @syncSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get syncSignUp;

  /// No description provided for @syncLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get syncLogin;

  /// No description provided for @syncSignInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get syncSignInWithApple;

  /// No description provided for @syncSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get syncSignInWithGoogle;

  /// No description provided for @syncSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get syncSigningIn;

  /// No description provided for @syncSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get syncSignOut;

  /// No description provided for @syncDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get syncDeleteAccount;

  /// No description provided for @syncDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get syncDeleteAccountTitle;

  /// No description provided for @syncDeleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Your cloud account and synced data will be deleted. Local records on this device remain on the device.'**
  String get syncDeleteAccountMessage;

  /// No description provided for @syncSignUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created.'**
  String get syncSignUpSuccess;

  /// No description provided for @syncSignUpConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'If email confirmation is enabled, check your email and confirm, then log in.'**
  String get syncSignUpConfirmEmail;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get syncSyncSuccess;

  /// No description provided for @syncSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncSyncFailed;

  /// No description provided for @syncSyncFailedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {reason}'**
  String syncSyncFailedWithReason(String reason);

  /// No description provided for @syncRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get syncRegisterButton;

  /// No description provided for @syncSignUpEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email address is already registered.'**
  String get syncSignUpEmailAlreadyRegistered;

  /// No description provided for @syncForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get syncForgotPassword;

  /// No description provided for @syncResetEmailPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered email address. We will send you a reset link.'**
  String get syncResetEmailPrompt;

  /// No description provided for @syncSendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get syncSendResetLink;

  /// No description provided for @syncResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'We have sent a password reset email. Please follow the link in the email to set a new password.'**
  String get syncResetEmailSent;

  /// No description provided for @syncResetEmailLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'Email send rate limit reached. Please try again in about an hour. For production, configure custom SMTP in the Supabase dashboard.'**
  String get syncResetEmailLimitExceeded;

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncInProgress;

  /// No description provided for @syncManualHint.
  ///
  /// In en, this message translates to:
  /// **'Sync is manual. Use \"Push to cloud\" or \"Pull from cloud\" to sync.'**
  String get syncManualHint;

  /// No description provided for @syncPushToServer.
  ///
  /// In en, this message translates to:
  /// **'Push to cloud'**
  String get syncPushToServer;

  /// No description provided for @syncPullFromServer.
  ///
  /// In en, this message translates to:
  /// **'Pull from cloud'**
  String get syncPullFromServer;

  /// No description provided for @syncPushShort.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get syncPushShort;

  /// No description provided for @syncPullShort.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get syncPullShort;

  /// No description provided for @syncConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get syncConfirmTitle;

  /// No description provided for @syncConfirmPushMessage.
  ///
  /// In en, this message translates to:
  /// **'All cloud data will be replaced by this device\'s data.'**
  String get syncConfirmPushMessage;

  /// No description provided for @syncConfirmPullMessage.
  ///
  /// In en, this message translates to:
  /// **'All device data will be replaced by cloud data.'**
  String get syncConfirmPullMessage;

  /// No description provided for @syncConfirmExecute.
  ///
  /// In en, this message translates to:
  /// **'Execute'**
  String get syncConfirmExecute;

  /// No description provided for @syncLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String syncLastSynced(String time);

  /// No description provided for @syncNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get syncNotSignedIn;

  /// No description provided for @syncNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Supabase not configured'**
  String get syncNotConfigured;

  /// No description provided for @paywallCompareSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get paywallCompareSync;

  /// No description provided for @csvGuideOpenButton.
  ///
  /// In en, this message translates to:
  /// **'CSV format guide'**
  String get csvGuideOpenButton;

  /// No description provided for @csvGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'CSV format for import'**
  String get csvGuideTitle;

  /// No description provided for @csvGuideIntro.
  ///
  /// In en, this message translates to:
  /// **'The CSV file must have a header row and data rows. Column order and names must match the table below.'**
  String get csvGuideIntro;

  /// No description provided for @csvGuideRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get csvGuideRequired;

  /// No description provided for @csvGuideOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get csvGuideOptional;

  /// No description provided for @csvGuideSampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample (first 2 data rows)'**
  String get csvGuideSampleTitle;

  /// No description provided for @csvGuideNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get csvGuideNotesTitle;

  /// No description provided for @csvGuideNoteEncoding.
  ///
  /// In en, this message translates to:
  /// **'Save as UTF-8 (e.g. \"UTF-8 CSV\" in Excel).'**
  String get csvGuideNoteEncoding;

  /// No description provided for @csvGuideNoteDate.
  ///
  /// In en, this message translates to:
  /// **'Date: YYYY-MM-DD or YYYY/MM/DD. Start time: ISO8601 (e.g. 2024-01-15T19:30:00.000) or leave empty.'**
  String get csvGuideNoteDate;

  /// No description provided for @csvGuideNoteQuotes.
  ///
  /// In en, this message translates to:
  /// **'If a cell contains a comma or newline, wrap the whole cell in double quotes.'**
  String get csvGuideNoteQuotes;

  /// No description provided for @csvGuideColSessionDate.
  ///
  /// In en, this message translates to:
  /// **'Workout date (YYYY-MM-DD etc.)'**
  String get csvGuideColSessionDate;

  /// No description provided for @csvGuideColSessionStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Session start time (ISO8601 or empty)'**
  String get csvGuideColSessionStartedAt;

  /// No description provided for @csvGuideColExerciseName.
  ///
  /// In en, this message translates to:
  /// **'Exercise name'**
  String get csvGuideColExerciseName;

  /// No description provided for @csvGuideColBodyPart.
  ///
  /// In en, this message translates to:
  /// **'Body part (e.g. chest, back; optional)'**
  String get csvGuideColBodyPart;

  /// No description provided for @csvGuideColSetNumber.
  ///
  /// In en, this message translates to:
  /// **'Set number (1, 2, 3…)'**
  String get csvGuideColSetNumber;

  /// No description provided for @csvGuideColWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get csvGuideColWeightKg;

  /// No description provided for @csvGuideColWeightLb.
  ///
  /// In en, this message translates to:
  /// **'Weight (lb)'**
  String get csvGuideColWeightLb;

  /// No description provided for @csvGuideColReps.
  ///
  /// In en, this message translates to:
  /// **'Reps (leave empty for time-based)'**
  String get csvGuideColReps;

  /// No description provided for @csvGuideColDurationSeconds.
  ///
  /// In en, this message translates to:
  /// **'Duration in seconds (optional)'**
  String get csvGuideColDurationSeconds;

  /// No description provided for @csvGuideColDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'Distance in meters (optional)'**
  String get csvGuideColDistanceMeters;

  /// No description provided for @csvGuideColMemo.
  ///
  /// In en, this message translates to:
  /// **'Memo (optional)'**
  String get csvGuideColMemo;

  /// No description provided for @goalSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set goal'**
  String get goalSetTitle;

  /// No description provided for @goalValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Target value'**
  String get goalValueLabel;

  /// No description provided for @goalDeadlineOptional.
  ///
  /// In en, this message translates to:
  /// **'Deadline (optional)'**
  String get goalDeadlineOptional;

  /// No description provided for @goalSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get goalSave;

  /// No description provided for @goalDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove goal'**
  String get goalDelete;

  /// No description provided for @goalDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove this goal?'**
  String get goalDeleteConfirmMessage;

  /// No description provided for @goalProgressRemaining.
  ///
  /// In en, this message translates to:
  /// **'{value} to goal'**
  String goalProgressRemaining(String value);

  /// No description provided for @goalProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% to goal'**
  String goalProgressPercent(int percent);

  /// No description provided for @goalProUpsell.
  ///
  /// In en, this message translates to:
  /// **'Goal tracking is available for free.'**
  String get goalProUpsell;

  /// No description provided for @goalAchievedTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals achieved'**
  String get goalAchievedTitle;

  /// No description provided for @goalsAchievedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Goals achieved this week'**
  String get goalsAchievedThisWeek;

  /// No description provided for @goalAchievedMessage.
  ///
  /// In en, this message translates to:
  /// **'Goal achieved on {exercise}: {value}.'**
  String goalAchievedMessage(String exercise, String value);

  /// No description provided for @goalTypeWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get goalTypeWeight;

  /// No description provided for @goalTypeReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get goalTypeReps;

  /// No description provided for @goalTypeVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get goalTypeVolume;

  /// No description provided for @goalTypeTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get goalTypeTime;

  /// No description provided for @goalTypeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get goalTypeDistance;

  /// No description provided for @goalListTitle.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalListTitle;

  /// No description provided for @goalPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get goalPriorityLabel;

  /// No description provided for @goalAchievementRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get goalAchievementRateLabel;

  /// No description provided for @goalPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get goalPriorityLow;

  /// No description provided for @goalPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get goalPriorityMedium;

  /// No description provided for @goalPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get goalPriorityHigh;

  /// No description provided for @goalListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No goals set'**
  String get goalListEmpty;

  /// No description provided for @listMenuGoalListDescription.
  ///
  /// In en, this message translates to:
  /// **'View all your goals'**
  String get listMenuGoalListDescription;

  /// No description provided for @goalTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goalTargetLabel;

  /// No description provided for @goalDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get goalDueLabel;

  /// No description provided for @goalTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get goalTimeMinutes;

  /// No description provided for @goalTimeSeconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get goalTimeSeconds;

  /// No description provided for @bulkGoalSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set goals in bulk'**
  String get bulkGoalSetTitle;

  /// No description provided for @bulkGoalButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Bulk set'**
  String get bulkGoalButtonLabel;

  /// No description provided for @bulkGoalCourseLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal level'**
  String get bulkGoalCourseLabel;

  /// No description provided for @bulkGoalCourseEasy.
  ///
  /// In en, this message translates to:
  /// **'Take it easy (1.1×)'**
  String get bulkGoalCourseEasy;

  /// No description provided for @bulkGoalCourseMedium.
  ///
  /// In en, this message translates to:
  /// **'Step it up (1.2×)'**
  String get bulkGoalCourseMedium;

  /// No description provided for @bulkGoalCourseHard.
  ///
  /// In en, this message translates to:
  /// **'Push hard (1.3×)'**
  String get bulkGoalCourseHard;

  /// No description provided for @bulkGoalCourseMax.
  ///
  /// In en, this message translates to:
  /// **'Go big (1.5×)'**
  String get bulkGoalCourseMax;

  /// No description provided for @bulkGoalCourseShortEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get bulkGoalCourseShortEasy;

  /// No description provided for @bulkGoalCourseShortMedium.
  ///
  /// In en, this message translates to:
  /// **'Step up'**
  String get bulkGoalCourseShortMedium;

  /// No description provided for @bulkGoalCourseShortHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get bulkGoalCourseShortHard;

  /// No description provided for @bulkGoalCourseShortMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get bulkGoalCourseShortMax;

  /// No description provided for @bulkGoalCourseCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get bulkGoalCourseCustom;

  /// No description provided for @bulkGoalCustomMultiplierHint.
  ///
  /// In en, this message translates to:
  /// **'Enter multiplier (e.g. 1.25)'**
  String get bulkGoalCustomMultiplierHint;

  /// No description provided for @bulkGoalCustomMultiplierInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a multiplier between 0.1 and 10'**
  String get bulkGoalCustomMultiplierInvalid;

  /// No description provided for @bulkGoalPastBest.
  ///
  /// In en, this message translates to:
  /// **'Past best'**
  String get bulkGoalPastBest;

  /// No description provided for @bulkGoalPastBestRepsUnit.
  ///
  /// In en, this message translates to:
  /// **' reps'**
  String get bulkGoalPastBestRepsUnit;

  /// No description provided for @bulkGoalSupplementTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get bulkGoalSupplementTitle;

  /// No description provided for @bulkGoalSupplementMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Target values are calculated by multiplying your current best record for each exercise by the selected rate (1.1× to 1.5×).'**
  String get bulkGoalSupplementMultiplier;

  /// No description provided for @bulkGoalSupplementExercises.
  ///
  /// In en, this message translates to:
  /// **'Only exercises with past training history are shown.'**
  String get bulkGoalSupplementExercises;

  /// No description provided for @bulkGoalSelectExercises.
  ///
  /// In en, this message translates to:
  /// **'Select exercises to set goals'**
  String get bulkGoalSelectExercises;

  /// No description provided for @bulkGoalSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get bulkGoalSelectAll;

  /// No description provided for @bulkGoalDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get bulkGoalDeselectAll;

  /// No description provided for @bulkGoalExecute.
  ///
  /// In en, this message translates to:
  /// **'Set goals in bulk'**
  String get bulkGoalExecute;

  /// No description provided for @bulkGoalConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get bulkGoalConfirmTitle;

  /// No description provided for @bulkGoalConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Set goals for {count} selected exercise(s)? Existing goals will be overwritten.'**
  String bulkGoalConfirmMessage(int count);

  /// No description provided for @bulkGoalResultMessage.
  ///
  /// In en, this message translates to:
  /// **'Goals set for {count} exercise(s)'**
  String bulkGoalResultMessage(int count);

  /// No description provided for @bulkGoalResultMessageWithSkipped.
  ///
  /// In en, this message translates to:
  /// **'Goals set for {saved} exercise(s) ({skipped} skipped)'**
  String bulkGoalResultMessageWithSkipped(int saved, int skipped);

  /// No description provided for @bulkGoalResultSkippedReason.
  ///
  /// In en, this message translates to:
  /// **'Skipped exercises have no best value matching their record type (weight, reps, time, etc.).'**
  String get bulkGoalResultSkippedReason;

  /// No description provided for @bulkGoalNoHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get bulkGoalNoHistoryTitle;

  /// No description provided for @bulkGoalNoHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'No training history yet. Record some workouts and try again.'**
  String get bulkGoalNoHistoryMessage;

  /// No description provided for @bulkGoalNoTargetsToSetMessage.
  ///
  /// In en, this message translates to:
  /// **'No exercises without a goal. Only exercises with training history and no goal set are shown here.'**
  String get bulkGoalNoTargetsToSetMessage;

  /// No description provided for @bulkGoalEditButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Bulk edit'**
  String get bulkGoalEditButtonLabel;

  /// No description provided for @bulkGoalEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk edit goals'**
  String get bulkGoalEditTitle;

  /// No description provided for @bulkGoalEditSelectGoals.
  ///
  /// In en, this message translates to:
  /// **'Select goals to edit or delete'**
  String get bulkGoalEditSelectGoals;

  /// No description provided for @bulkGoalDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected goals'**
  String get bulkGoalDeleteSelected;

  /// No description provided for @bulkGoalRecalcSelected.
  ///
  /// In en, this message translates to:
  /// **'Recalculate selected goals'**
  String get bulkGoalRecalcSelected;

  /// No description provided for @bulkGoalEditConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected goal(s)?'**
  String bulkGoalEditConfirmDelete(int count);

  /// No description provided for @bulkGoalEditConfirmRecalc.
  ///
  /// In en, this message translates to:
  /// **'Overwrite {count} selected goal(s) with current best × selected rate. Continue?'**
  String bulkGoalEditConfirmRecalc(int count);

  /// No description provided for @bulkGoalEditResultDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} goal(s) deleted'**
  String bulkGoalEditResultDeleted(int count);

  /// No description provided for @bulkGoalEditResultRecalculated.
  ///
  /// In en, this message translates to:
  /// **'{count} goal(s) recalculated'**
  String bulkGoalEditResultRecalculated(int count);

  /// No description provided for @bulkGoalEditResultRecalculatedWithSkipped.
  ///
  /// In en, this message translates to:
  /// **'{saved} recalculated ({skipped} skipped)'**
  String bulkGoalEditResultRecalculatedWithSkipped(int saved, int skipped);

  /// No description provided for @bulkGoalEditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No goals'**
  String get bulkGoalEditEmpty;

  /// No description provided for @routineTitle.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routineTitle;

  /// No description provided for @routineEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No routines yet.\nCreate one to quickly start workouts.'**
  String get routineEmptyHint;

  /// No description provided for @routineCreateNew.
  ///
  /// In en, this message translates to:
  /// **'New Routine'**
  String get routineCreateNew;

  /// No description provided for @routineNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Routine Name'**
  String get routineNameLabel;

  /// No description provided for @routineNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Chest Day'**
  String get routineNameHint;

  /// No description provided for @routineSave.
  ///
  /// In en, this message translates to:
  /// **'Save Routine'**
  String get routineSave;

  /// No description provided for @routineDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Routine'**
  String get routineDelete;

  /// No description provided for @routineDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String routineDeleteConfirm(String name);

  /// No description provided for @routineStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get routineStartWorkout;

  /// No description provided for @routineEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get routineEdit;

  /// No description provided for @routineExerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count} exercises'**
  String routineExerciseCount(int count);

  /// No description provided for @routineLoadIntoWorkout.
  ///
  /// In en, this message translates to:
  /// **'Load Routine'**
  String get routineLoadIntoWorkout;

  /// No description provided for @routineLoadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add exercises from this routine?'**
  String get routineLoadConfirm;

  /// No description provided for @routineAddToCurrentWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Routine to Workout'**
  String get routineAddToCurrentWorkoutTitle;

  /// No description provided for @routineAddToCurrentWorkoutMessage.
  ///
  /// In en, this message translates to:
  /// **'This routine will be added to your current workout. Your existing entries will be kept.'**
  String get routineAddToCurrentWorkoutMessage;

  /// No description provided for @routineSaveAsRoutine.
  ///
  /// In en, this message translates to:
  /// **'Save as Routine'**
  String get routineSaveAsRoutine;

  /// No description provided for @routineSaved.
  ///
  /// In en, this message translates to:
  /// **'Routine saved!'**
  String get routineSaved;

  /// No description provided for @routineManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get routineManage;

  /// No description provided for @routineNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a routine name'**
  String get routineNameRequired;

  /// No description provided for @routineExerciseRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one exercise'**
  String get routineExerciseRequired;

  /// No description provided for @listMenuRoutineDescription.
  ///
  /// In en, this message translates to:
  /// **'View and manage workout routines'**
  String get listMenuRoutineDescription;

  /// No description provided for @routineSetCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String routineSetCount(int count);
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
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
