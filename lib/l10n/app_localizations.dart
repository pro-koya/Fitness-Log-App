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

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Liftly'**
  String get appName;

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

  /// Label for recent workouts section
  ///
  /// In en, this message translates to:
  /// **'Recent Workouts'**
  String get recentWorkoutsLabel;

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

  /// Label for improvement stat
  ///
  /// In en, this message translates to:
  /// **'Improvement'**
  String get improvement;

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

  /// Paywall title for history unlock
  ///
  /// In en, this message translates to:
  /// **'View your full history'**
  String get paywallTitleHistory;

  /// Paywall title for chart access
  ///
  /// In en, this message translates to:
  /// **'See your progress in charts'**
  String get paywallTitleChart;

  /// Paywall title for theme customization
  ///
  /// In en, this message translates to:
  /// **'Personalize your theme'**
  String get paywallTitleTheme;

  /// Paywall title for stats access
  ///
  /// In en, this message translates to:
  /// **'View detailed stats'**
  String get paywallTitleStats;

  /// Paywall title for export feature
  ///
  /// In en, this message translates to:
  /// **'Export your data'**
  String get paywallTitleExport;

  /// Paywall body for history unlock
  ///
  /// In en, this message translates to:
  /// **'Free shows your latest 20 sessions. Go Pro to unlock full history, charts, and stats to see your progress.'**
  String get paywallBodyHistory;

  /// Paywall body for chart access
  ///
  /// In en, this message translates to:
  /// **'Track your growth with detailed charts and graphs. Available with Pro.'**
  String get paywallBodyChart;

  /// Paywall body for theme customization
  ///
  /// In en, this message translates to:
  /// **'Customize your app\'s look with your favorite colors. Available with Pro.'**
  String get paywallBodyTheme;

  /// Paywall body for stats access
  ///
  /// In en, this message translates to:
  /// **'Get detailed weekly and monthly statistics. Available with Pro.'**
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
  /// **'Last 20'**
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
  /// **'Free shows the latest 20 sessions. Go Pro to view everything.'**
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

  /// Paywall title for backup feature
  ///
  /// In en, this message translates to:
  /// **'Backup your data'**
  String get paywallTitleBackup;

  /// Paywall body for backup feature
  ///
  /// In en, this message translates to:
  /// **'Back up your data to transfer to a new device. Available with Pro.'**
  String get paywallBodyBackup;

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
  /// **'Import data from a backup file'**
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

  /// Trial period title
  ///
  /// In en, this message translates to:
  /// **'Start your 1-month free trial'**
  String get paywallTrialTitle;

  /// Trial period description
  ///
  /// In en, this message translates to:
  /// **'Try all Pro features free for 1 month. After the trial ends, your subscription will automatically begin.'**
  String get paywallTrialDescription;

  /// Notice about cancellation during trial
  ///
  /// In en, this message translates to:
  /// **'To avoid being charged, cancel anytime during the free trial period.'**
  String get paywallTrialNotice;

  /// CTA button text for starting trial
  ///
  /// In en, this message translates to:
  /// **'Start Free Trial'**
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

  /// Subscription disclaimer for paywall
  ///
  /// In en, this message translates to:
  /// **'Payment will be charged to your Apple ID account at the end of the free trial. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage and cancel your subscription in your Apple ID account settings.'**
  String get paywallSubscriptionDisclaimer;
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
