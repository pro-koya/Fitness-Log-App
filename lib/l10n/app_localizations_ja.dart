// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get welcomeMessage => 'Liftlyへようこそ';

  @override
  String get languageLabel => '言語';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get unitLabel => '単位';

  @override
  String get unitKg => 'kg';

  @override
  String get unitLb => 'lb';

  @override
  String get startButton => '始める';

  @override
  String get initialSetupWeightLabel => '重さ';

  @override
  String get initialSetupDistanceLabel => '距離';

  @override
  String get appName => 'Liftly';

  @override
  String get startWorkoutButton => 'トレーニング開始';

  @override
  String get resumeWorkoutButton => '記録中の続き';

  @override
  String get newWorkoutButton => '新しく開始';

  @override
  String workoutInProgressSummary(int exerciseCount, int setCount) {
    return '$exerciseCount種目、$setCountセット記録済み';
  }

  @override
  String get settingsButton => '設定';

  @override
  String get addExerciseButton => '種目を追加';

  @override
  String get completeButton => '完了';

  @override
  String get tutorialCompletionTitle => '準備完了です！';

  @override
  String get tutorialCompletionMessage =>
      'さあ、トレーニング記録を始めましょう。記録が終わったら「記録完了」をタップしてください。';

  @override
  String previousRecord(String records) {
    return '前回：$records';
  }

  @override
  String get previousRecordNone => '前回：—';

  @override
  String get reproduceButton => '前回を再現';

  @override
  String get addSetButton => 'セット追加';

  @override
  String setLabel(int number) {
    return 'セット$number';
  }

  @override
  String get weightLabel => '重量';

  @override
  String get repsLabel => '回数';

  @override
  String get copyButton => 'コピー';

  @override
  String get deleteButton => '削除';

  @override
  String get timerLabel => 'タイマー';

  @override
  String get timerStart => '開始';

  @override
  String get timerPause => '一時停止';

  @override
  String get timerReset => 'リセット';

  @override
  String get timerClose => '閉じる';

  @override
  String get settingsTitle => '設定';

  @override
  String get backButton => '戻る';

  @override
  String get workoutDetailTitle => '記録詳細';

  @override
  String get workoutInputTitle => 'トレーニング';

  @override
  String sessionTime(String startTime, String endTime) {
    return '$startTime - $endTime';
  }

  @override
  String get emptyStateMessage => 'この日は記録がありません';

  @override
  String get exerciseProgressTitle => '種目別グラフ';

  @override
  String get topWeightLabel => 'トップ重量';

  @override
  String get totalVolumeLabel => '総ボリューム';

  @override
  String get emptyProgressMessage => '記録が少なくてグラフを表示できません。もう少しトレーニングを記録してみましょう';

  @override
  String get deleteSetConfirmTitle => 'このセットを削除しますか？';

  @override
  String deleteSetConfirmMessage(
    int number,
    double weight,
    String unit,
    int reps,
  ) {
    return 'セット$number：$weight$unit/$reps回';
  }

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get confirmButton => 'OK';

  @override
  String errorMessage(String error) {
    return 'エラー：$error';
  }

  @override
  String get recentWorkoutsLabel => '最近の記録';

  @override
  String get errorLoadingWorkouts => '記録の読み込みに失敗しました';

  @override
  String get noWorkoutHistory => 'まだトレーニング履歴がありません';

  @override
  String get unknownDate => '不明な日付';

  @override
  String durationLabel(String duration) {
    return '時間：$duration';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get workoutInProgress => '記録中';

  @override
  String get startNewWorkoutButton => '新しく開始';

  @override
  String get editWorkoutButton => '編集';

  @override
  String get deleteWorkoutButton => '削除';

  @override
  String setsCountLabel(int count) {
    return '$countセット';
  }

  @override
  String get noSetsRecorded => 'セットの記録がありません';

  @override
  String get deleteWorkoutDialogTitle => '記録を削除';

  @override
  String get deleteWorkoutDialogMessage =>
      'このトレーニング記録を削除してもよろしいですか？この操作は取り消せません。';

  @override
  String errorDeletingWorkout(String error) {
    return '記録の削除に失敗しました：$error';
  }

  @override
  String get saveButton => '保存';

  @override
  String get settingsSaved => '設定を保存しました';

  @override
  String monthlyWorkoutCount(int count) {
    return '$count回';
  }

  @override
  String get thisMonthLabel => '今月';

  @override
  String get streakLabel => '継続';

  @override
  String streakDays(int count) {
    return '$count日';
  }

  @override
  String get averageWeightLabel => '月平均体重';

  @override
  String get selectMonthYear => '年月を選択';

  @override
  String get lastMonthShort => '先月';

  @override
  String get thisMonthShort => '今月';

  @override
  String get nextMonthShort => '来月';

  @override
  String get allRecordsTitle => '全ての記録';

  @override
  String totalWorkoutsCount(int count) {
    return '全$count回のトレーニング';
  }

  @override
  String moreExercisesHint(int count) {
    return '他$count種目…';
  }

  @override
  String get tapForDetailHint => 'タップで詳細を見る';

  @override
  String get exerciseAlreadyAdded => 'すでに登録されています';

  @override
  String get searchExercisePlaceholder => '種目を検索...';

  @override
  String get selectExerciseTitle => '種目を選択';

  @override
  String get addCustomExerciseButton => 'カスタム種目を追加';

  @override
  String get customExerciseDialogTitle => 'カスタム種目を追加';

  @override
  String get exerciseNameLabel => '種目名';

  @override
  String get addButton => '追加';

  @override
  String get historyTitle => '履歴';

  @override
  String get viewDetailsButton => '詳細を見る';

  @override
  String exerciseCount(int count) {
    return '$count種目';
  }

  @override
  String setCount(int count) {
    return '$countセット';
  }

  @override
  String workoutSummaryTitle(String date) {
    return '$dateのワークアウト';
  }

  @override
  String get noWorkoutsThisMonth => '今月はワークアウトがありません';

  @override
  String get deleteExerciseDialogTitle => '種目を削除しますか？';

  @override
  String deleteExerciseDialogMessage(String exerciseName) {
    return '「$exerciseName」を削除してもよろしいですか？この種目のすべてのセットが削除されます。';
  }

  @override
  String get deleteCustomExerciseDialogTitle => 'カスタム種目を削除しますか？';

  @override
  String deleteCustomExerciseDialogMessage(String exerciseName) {
    return '「$exerciseName」を削除してもよろしいですか？この操作は取り消せません。';
  }

  @override
  String exerciseDeleted(String exerciseName) {
    return '「$exerciseName」を削除しました';
  }

  @override
  String get exerciseHistoryTitle => '種目履歴';

  @override
  String get noHistoryAvailable => '履歴がありません';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String weeksAgo(int count) {
    return '$count週間前';
  }

  @override
  String monthsAgo(int count) {
    return '$countヶ月前';
  }

  @override
  String yearsAgo(int count) {
    return '$count年前';
  }

  @override
  String get monthlySummary => '月間サマリー';

  @override
  String get totalDuration => '総トレーニング時間';

  @override
  String get totalSets => '総セット数';

  @override
  String get totalVolume => '総ボリューム';

  @override
  String get totalTime => '総時間';

  @override
  String get setsUnit => 'セット';

  @override
  String get topExercises => 'よく行う種目';

  @override
  String get timesUnit => '回';

  @override
  String get weeklyTrend => '週間トレンド';

  @override
  String get memoLabel => 'メモ';

  @override
  String get memoHistory => 'メモ履歴';

  @override
  String get noMemoRecorded => 'メモなし';

  @override
  String get memoSearch => 'メモ検索';

  @override
  String get memoSearchPlaceholder => 'キーワードで検索...';

  @override
  String get memoSearchNoResults => 'メモが見つかりませんでした';

  @override
  String get memoSearchHint => 'キーワードを入力してメモを検索';

  @override
  String get previousLabel => '前回：';

  @override
  String get historyButton => '履歴';

  @override
  String get reproducePreviousButton => '前回を再現';

  @override
  String get memoPlaceholder => 'メモを追加（フォーム、感想など...）';

  @override
  String get showLess => '閉じる';

  @override
  String showMoreSets(int count) {
    return '+$count件';
  }

  @override
  String get deleteExerciseTooltip => '種目を削除';

  @override
  String get weightTab => '重量';

  @override
  String get repsTab => '回数';

  @override
  String get volumeTab => 'ボリューム';

  @override
  String get noDataForExercise => 'この種目の記録がまだありません。';

  @override
  String get summaryLabel => 'サマリー';

  @override
  String get totalWorkouts => 'トレーニング回数';

  @override
  String get latestTopWeight => '最新のトップ重量';

  @override
  String get latestBestTime => '最新のベストタイム';

  @override
  String get latestTopReps => '最新のトップ回数';

  @override
  String get latestTopVolume => '最新のトップボリューム';

  @override
  String get startingWeight => '初回の重量';

  @override
  String get startingBestTime => '初回のベストタイム';

  @override
  String get startingTopReps => '初回のトップ回数';

  @override
  String get startingTopVolume => '初回のトップボリューム';

  @override
  String get improvement => '成長';

  @override
  String get repsUnit => '回';

  @override
  String noBodyPartWorkoutsThisMonth(String bodyPart) {
    return '今月は「$bodyPart」のトレーニングが行われていません。';
  }

  @override
  String get distanceUnitLabel => '距離単位';

  @override
  String get distanceUnitKm => 'km';

  @override
  String get distanceUnitMile => 'マイル';

  @override
  String get timeTab => '時間';

  @override
  String get distanceTab => '距離';

  @override
  String get paceTab => 'ペース';

  @override
  String get latestBestDistance => '最新のベスト距離';

  @override
  String get startingBestDistance => '初回のベスト距離';

  @override
  String get paywallTitleHistory => 'これまでの記録を、すべて残そう';

  @override
  String get paywallTitleChart => '成長の流れを、見てみませんか';

  @override
  String get paywallTitleTheme => 'このアプリを、自分らしく';

  @override
  String get paywallTitleStats => '続いていることを、確かめる';

  @override
  String get paywallTitleExport => 'データをエクスポート';

  @override
  String get paywallBodyHistory =>
      'ここまで積み重ねてきたトレーニングは、もう十分に価値のある記録です。Proなら、すべての履歴をいつでも振り返れます。';

  @override
  String get paywallBodyChart =>
      '数字の変化は、続けてきた証拠です。Proなら、トレーニングの成長をグラフで振り返ることができます。';

  @override
  String get paywallBodyTheme =>
      '毎日使うものだから、しっくりくる見た目で続けたい。Proなら、テーマを自由にカスタマイズできます。';

  @override
  String get paywallBodyStats =>
      '振り返ることで、習慣は続きます。Proなら、週間・月間の統計からトレーニング全体を把握できます。';

  @override
  String get paywallBodyExport => 'ワークアウトデータをCSVでエクスポート。Proで利用可能。';

  @override
  String get paywallCtaTryPro => 'Proを試す';

  @override
  String get paywallCtaNotNow => '今はしない';

  @override
  String get paywallCompareHistory => '履歴';

  @override
  String get paywallCompareLast20 => '直近30件';

  @override
  String get paywallCompareUnlimited => '無制限';

  @override
  String get paywallCompareCharts => 'グラフ';

  @override
  String get paywallCompareTheme => 'テーマ';

  @override
  String get paywallCompareChartsTheme => 'グラフ・テーマ';

  @override
  String get paywallCompareAds => '広告';

  @override
  String get paywallCompareAdsShow => '表示';

  @override
  String get paywallCompareAdsHide => '非表示';

  @override
  String get paywallCompareDefault => 'デフォルト';

  @override
  String get paywallCompareCustom => 'カスタム';

  @override
  String get lockedSessionHint => 'Proで全履歴を表示';

  @override
  String get lockedSessionSubHint => '無料版は直近30回まで。過去の成長を全部見返すにはProへ';

  @override
  String get proLabel => 'Pro';

  @override
  String get freeLabel => 'Free';

  @override
  String get paywallPriceMonthly => '¥150/月';

  @override
  String get paywallPriceYearly => '¥1,500/年';

  @override
  String get paywallPriceOr => 'または';

  @override
  String get shareWorkoutButton => 'SNS共有';

  @override
  String get shareWorkoutDialogTitle => 'ワークアウトを共有';

  @override
  String get copyToClipboard => 'クリップボードにコピー';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get themeSettingsTitle => 'テーマ設定';

  @override
  String get presetThemesLabel => 'プリセットテーマ';

  @override
  String get customColorsLabel => 'カスタムカラー';

  @override
  String get primaryColorLabel => 'プライマリカラー';

  @override
  String get secondaryColorLabel => 'セカンダリカラー';

  @override
  String get previewLabel => 'プレビュー';

  @override
  String get resetToDefaultLabel => 'デフォルトに戻す';

  @override
  String get resetThemeConfirmMessage => 'テーマ設定をデフォルトに戻しますか？';

  @override
  String get contrastWarning => 'コントラストが低いため読みにくくなる可能性があります';

  @override
  String get themeLabel => 'テーマ';

  @override
  String get invalidHexColor => '無効なカラーコードです';

  @override
  String get hexColorHint => '例: #1976D2';

  @override
  String get selectColor => 'カラーを選択';

  @override
  String get colorPalette => 'カラーパレット';

  @override
  String get colorCategoryBasic => '基本';

  @override
  String get colorCategoryRed => 'レッド';

  @override
  String get colorCategoryPink => 'ピンク';

  @override
  String get colorCategoryPurple => 'パープル';

  @override
  String get colorCategoryBlue => 'ブルー';

  @override
  String get colorCategoryGreen => 'グリーン';

  @override
  String get colorCategoryOrange => 'オレンジ';

  @override
  String get colorCategoryBrown => 'ブラウン';

  @override
  String get paywallTitleBackup => '大切な記録を、安心して残す';

  @override
  String get paywallBodyBackup =>
      'これまでのトレーニングは、簡単に失っていいものではありません。Proなら、データをバックアップできます。';

  @override
  String get paywallTitleAds => '広告を非表示にして、集中して使う';

  @override
  String get paywallBodyAds => 'Proなら広告が消え、記録やテーマなどすべての機能が使えます。';

  @override
  String get settingsPlanSection => 'プラン';

  @override
  String get settingsUpgradeToPro => 'Proにアップグレード';

  @override
  String get settingsProPlanDescription => '広告非表示・全履歴・テーマ・バックアップなど';

  @override
  String get adHideWithProCta => '広告を非表示にしますか？';

  @override
  String get backupLabel => 'バックアップ';

  @override
  String get backupTitle => 'バックアップ / 復元';

  @override
  String get backupSectionTitle => 'バックアップを作成';

  @override
  String get backupSectionDescription => 'トレーニングデータをファイルに保存します';

  @override
  String get backupFormatLabel => 'バックアップ形式';

  @override
  String get backupFormatJson => 'JSON（アプリで復元可能）';

  @override
  String get backupFormatCsv => 'CSV（分析・表計算用）';

  @override
  String get createBackupButton => 'バックアップを作成';

  @override
  String get restoreSectionTitle => 'バックアップから復元';

  @override
  String get restoreSectionDescription => '保存したJSONまたはCSVファイルからデータを復元します';

  @override
  String get restoreBackupButton => 'ファイルを選択して復元';

  @override
  String get backupWarning =>
      '復元すると現在のデータは上書きされます。復元前に現在のデータをバックアップすることをお勧めします。';

  @override
  String get creatingBackup => 'バックアップを作成中...';

  @override
  String get backupCreated => 'バックアップを作成しました';

  @override
  String get backupCompleteTitle => 'バックアップ完了';

  @override
  String get backupCompleteMessage => '選択した場所にバックアップファイルが保存されました。';

  @override
  String get loadingBackup => 'バックアップを読み込み中...';

  @override
  String get restoringData => 'データを復元中...';

  @override
  String get restoreCompleted => '復元が完了しました';

  @override
  String get invalidBackupFile => '無効なバックアップファイルです';

  @override
  String get incompatibleBackupVersion => 'このバックアップはサポートされていないバージョンです';

  @override
  String get restoreConfirmTitle => 'データを復元しますか？';

  @override
  String restoreConfirmBackupDate(String date) {
    return 'バックアップ日時：$date';
  }

  @override
  String restoreConfirmSessionCount(int count) {
    return 'セッション数：$count件';
  }

  @override
  String restoreConfirmExerciseCount(int count) {
    return '種目数：$count件';
  }

  @override
  String get restoreConfirmWarning => '現在のデータは全て上書きされます。この操作は取り消せません。';

  @override
  String get restoreButton => '復元する';

  @override
  String get paywallSubscriptionMonthly => '月額';

  @override
  String get paywallSubscriptionYearly => '年額';

  @override
  String get paywallSubscriptionYearlySave => '17%お得';

  @override
  String get paywallSubscriptionPurchasing => '処理中...';

  @override
  String get paywallSubscriptionError => '購入に失敗しました。もう一度お試しください。';

  @override
  String get paywallRestorePurchases => '購入を復元';

  @override
  String get paywallRestoreSuccess => '購入を復元しました';

  @override
  String get paywallRestoreNoSubscription => '有効なサブスクリプションが見つかりません';

  @override
  String get paywallRestoring => '復元中...';

  @override
  String get paywallTermsOfService => '利用規約';

  @override
  String get paywallPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get paywallTrialTitle => 'この習慣を、\nもう少し続けてみませんか';

  @override
  String get paywallTrialDescription =>
      'Proでは、これまでの記録をすべて残し、成長を振り返りながらトレーニングを続けられます。';

  @override
  String get paywallTrialNotice => '無料期間中はいつでも解約できます。';

  @override
  String get paywallCtaStartTrial => '無料で続ける';

  @override
  String get settingsManageSubscription => 'サブスクリプションを管理';

  @override
  String get settingsManageSubscriptionHint => '解約やプラン変更はこちら';

  @override
  String get paywallSubscriptionDisclaimer =>
      '無料トライアル終了後、Apple IDアカウントに課金されます。サブスクリプションは現在の期間終了の24時間前までに解約しない限り自動更新されます。サブスクリプションの管理・解約はApple IDのアカウント設定から行えます。';

  @override
  String get sortLabel => '並べ替え';

  @override
  String get sortByDateDesc => '日付（新しい順）';

  @override
  String get sortByDateAsc => '日付（古い順）';

  @override
  String get sortByWeightDesc => '重量（重い順）';

  @override
  String get sortByWeightAsc => '重量（軽い順）';

  @override
  String get sortByRepsDesc => '回数（多い順）';

  @override
  String get sortByRepsAsc => '回数（少ない順）';

  @override
  String get sortByTimeDesc => '時間（長い順）';

  @override
  String get sortByTimeAsc => '時間（短い順）';

  @override
  String get sortByDistanceDesc => '距離（長い順）';

  @override
  String get sortByDistanceAsc => '距離（短い順）';

  @override
  String get bodyWeightTitle => '体重';

  @override
  String get bodyWeightLabel => '体重';

  @override
  String get bodyWeightMemoHint => 'メモ（任意、例：朝食前）';

  @override
  String get bodyWeightSaved => '体重を記録しました';

  @override
  String get bodyWeightUpdated => '体重を更新しました';

  @override
  String get bodyWeightDeleted => '記録を削除しました';

  @override
  String get bodyWeightNoData => 'まだ体重の記録がありません。記録を始めましょう！';

  @override
  String get bodyWeightDeleteConfirm => 'この記録を削除しますか？';

  @override
  String get bodyWeightSummary => 'サマリー';

  @override
  String get bodyWeightCurrentWeight => '現在';

  @override
  String get bodyWeightStartingWeight => '開始時';

  @override
  String get bodyWeightTotalChange => '変化';

  @override
  String get bodyWeightMinWeight => '最小';

  @override
  String get bodyWeightMaxWeight => '最大';

  @override
  String get bodyWeightTotalRecords => '記録数';

  @override
  String get bodyWeightInsightTitle => '月間インサイト';

  @override
  String bodyWeightInsightMessage(int workoutCount, String weightChange) {
    return '今月は$workoutCount回トレーニングし、体重は$weightChange変化しました。';
  }

  @override
  String bodyWeightInsightNoData(int workoutCount) {
    return '今月は$workoutCount回トレーニングしました。体重を記録してトレンドを確認しましょう！';
  }

  @override
  String get bodyWeightHistory => '履歴';

  @override
  String get importDataMigrationSection => 'データ移行';

  @override
  String get importKintoreMemoTitle => '筋トレMemoから取り込み';

  @override
  String get importKintoreMemoDescription =>
      'iMazing等で取得した default.realm をインポート';

  @override
  String get importSelectFile => 'ファイルを選択';

  @override
  String get importAnalyzing => '解析中...';

  @override
  String get importPreviewTitle => 'プレビュー';

  @override
  String importPreviewWorkoutCount(Object count) {
    return '種目数：$count件';
  }

  @override
  String importPreviewTotalSets(Object count) {
    return 'セット数：$count件';
  }

  @override
  String importPreviewDateRange(Object end, Object start) {
    return '日付範囲：$start ～ $end';
  }

  @override
  String importPreviewSampleExercises(Object exercises) {
    return '代表種目：$exercises';
  }

  @override
  String get importExecute => 'インポートする';

  @override
  String importSuccess(Object session, Object set) {
    return 'インポートが完了しました（セッション$session件、セット$set件）';
  }

  @override
  String get importErrorEncrypted =>
      'このRealmファイルは暗号化されています。暗号化されていないファイルを選択してください。';

  @override
  String get importErrorSchemaMismatch =>
      'ファイル形式が異なります。筋トレMemoの default.realm を選択してください。';

  @override
  String get importErrorInvalidFile => '無効なファイルです。.realm ファイルを選択してください。';

  @override
  String importErrorUnknown(Object error) {
    return 'インポートに失敗しました：$error';
  }

  @override
  String get importGuideTitle => 'Realmファイルの取得方法';

  @override
  String get importGuideStep1Title => 'PCに接続';

  @override
  String get importGuideStep1Desc =>
      'iPhoneをPC/Macに接続し、iMazingや3uToolsなどのファイル管理ツールを開きます。';

  @override
  String get importGuideStep2Title => 'ファイルを探す';

  @override
  String get importGuideStep2Desc =>
      '筋トレMemoのアプリフォルダを開き、Documentsフォルダ内の「default.realm」を見つけます。';

  @override
  String get importGuideStep3Title => 'デバイスに転送';

  @override
  String get importGuideStep3Desc =>
      'ファイルをエクスポートし、AirDrop・iCloud Drive・メールなどでiPhoneの「ファイル」アプリに保存します。';

  @override
  String get importGuideTip =>
      '転送後、下の「ファイルを選択」ボタンから「ファイル」アプリ内の.realmファイルを選択してください。';

  @override
  String get importReimportTitle => 'インポート済み';

  @override
  String get importReimportMessage =>
      'このデータは既にインポートされています。前回のインポートをクリアして再インポートしますか？';

  @override
  String get importReimportCancel => 'キャンセル';

  @override
  String get importReimportConfirm => '再インポート';

  @override
  String get importCsvTitle => 'CSVから取り込み';

  @override
  String get importCsvDescription =>
      'LiftlyでエクスポートしたCSVまたはJSONファイルからデータを取り込みます。既存のデータは上書きされます。';

  @override
  String get importCsvTileDescription => 'LiftlyでエクスポートしたCSV/JSONから取り込み';

  @override
  String get importCsvSelectFile => 'ファイルを選択';

  @override
  String get importCsvFormatHint =>
      'Liftlyのバックアップ機能でエクスポートしたCSV/JSON形式のファイルを選択してください。';

  @override
  String get workoutCompletionTitle => 'トレーニング記録完了';

  @override
  String workoutCompletionSummary(
    int exerciseCount,
    int setCount,
    String volume,
    String unit,
  ) {
    return '$exerciseCount種目・$setCountセット・総ボリューム $volume$unit';
  }

  @override
  String workoutCompletionExerciseLine(
    String name,
    int setCount,
    String weight,
    String unit,
  ) {
    return '$name $setCountセット 最高重量$weight$unit';
  }

  @override
  String workoutCompletionExerciseLineTime(
    String name,
    int setCount,
    String duration,
  ) {
    return '$name $setCountセット 最長$duration';
  }

  @override
  String get syncSectionTitle => 'クラウド同期';

  @override
  String get syncSectionDescription => 'データをクラウドに保存して複数端末で利用';

  @override
  String get syncSignUp => '新規登録';

  @override
  String get syncLogin => 'ログイン';

  @override
  String get syncSignInWithGoogle => 'Google でログイン';

  @override
  String get syncSigningIn => 'ログイン中...';

  @override
  String get syncSignOut => 'サインアウト';

  @override
  String get syncSignUpSuccess => 'アカウントを作成しました。';

  @override
  String get syncSignUpConfirmEmail =>
      'メール確認が有効な場合は、送信されたリンクから確認してからログインしてください。';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String get syncSyncSuccess => '同期が完了しました';

  @override
  String get syncSyncFailed => '同期に失敗しました';

  @override
  String syncSyncFailedWithReason(String reason) {
    return '同期に失敗しました: $reason';
  }

  @override
  String get syncRegisterButton => '登録する';

  @override
  String get syncSignUpEmailAlreadyRegistered => 'このメールアドレスは既に登録されています。';

  @override
  String get syncForgotPassword => 'パスワードを忘れた';

  @override
  String get syncResetEmailPrompt => '登録済みのメールアドレスを入力してください。リセット用のリンクを送信します。';

  @override
  String get syncSendResetLink => 'リセット用メールを送信';

  @override
  String get syncResetEmailSent => 'パスワードリセット用のメールを送信しました。メール内のリンクから再設定してください。';

  @override
  String get syncResetEmailLimitExceeded =>
      'メール送信回数の制限に達しました。約1時間後に再度お試しください。本番運用時は Supabase ダッシュボードでカスタム SMTP の設定を推奨します。';

  @override
  String get syncInProgress => '同期中...';

  @override
  String get syncManualHint => '同期は手動で行います。「クラウドへ反映」または「クラウドから取得」で同期してください。';

  @override
  String get syncPushToServer => 'クラウドへデータを反映';

  @override
  String get syncPullFromServer => 'クラウドからデータを取得';

  @override
  String get syncPushShort => '反映';

  @override
  String get syncPullShort => '取得';

  @override
  String get syncConfirmTitle => '確認';

  @override
  String get syncConfirmPushMessage => 'デバイスのデータにより、クラウドのデータがすべて書き換えられます。';

  @override
  String get syncConfirmPullMessage => 'クラウドのデータにより、デバイスのデータがすべて書き換えられます。';

  @override
  String get syncConfirmExecute => '実行する';

  @override
  String syncLastSynced(String time) {
    return '最終同期: $time';
  }

  @override
  String get syncNotSignedIn => '未サインイン';

  @override
  String get syncNotConfigured => 'Supabase 未設定';

  @override
  String get paywallCompareSync => '同期';

  @override
  String get csvGuideOpenButton => 'CSVの形式を見る';

  @override
  String get csvGuideTitle => '取り込み用CSVの形式';

  @override
  String get csvGuideIntro =>
      '復元で読み込めるCSVは、1行目がヘッダー・2行目以降がデータです。列の順番と名前は以下と一致させてください。';

  @override
  String get csvGuideRequired => '必須';

  @override
  String get csvGuideOptional => '任意';

  @override
  String get csvGuideSampleTitle => 'サンプル（先頭2行のイメージ）';

  @override
  String get csvGuideNotesTitle => '注意';

  @override
  String get csvGuideNoteEncoding =>
      '文字コードはUTF-8で保存してください（Excelなら「UTF-8 CSV」で保存）。';

  @override
  String get csvGuideNoteDate =>
      '日付は YYYY-MM-DD（例: 2024-01-15）または YYYY/MM/DD。開始時刻は ISO8601（例: 2024-01-15T19:30:00.000）が使えます。';

  @override
  String get csvGuideNoteQuotes => 'セル内にカンマや改行を含む場合は、セル全体をダブルクォートで囲んでください。';

  @override
  String get csvGuideColSessionDate => 'トレーニング日（YYYY-MM-DD など）';

  @override
  String get csvGuideColSessionStartedAt => 'セッション開始時刻（ISO8601 または空欄可）';

  @override
  String get csvGuideColExerciseName => '種目名';

  @override
  String get csvGuideColBodyPart => '部位（胸・背中など、空欄可）';

  @override
  String get csvGuideColSetNumber => 'セット番号（1, 2, 3…）';

  @override
  String get csvGuideColWeightKg => '重量（kg）';

  @override
  String get csvGuideColWeightLb => '重量（lb）';

  @override
  String get csvGuideColReps => '回数（時間系種目は空欄）';

  @override
  String get csvGuideColDurationSeconds => '持続時間（秒、空欄可）';

  @override
  String get csvGuideColDistanceMeters => '距離（m、空欄可）';

  @override
  String get csvGuideColMemo => 'メモ（空欄可）';
}
