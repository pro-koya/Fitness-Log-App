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
  String get paywallTitleHistory => '過去の記録をすべて見返す';

  @override
  String get paywallTitleChart => '成長をグラフで確認';

  @override
  String get paywallTitleTheme => '自分だけのテーマに';

  @override
  String get paywallTitleStats => '詳しい統計を見る';

  @override
  String get paywallTitleExport => 'データをエクスポート';

  @override
  String get paywallBodyHistory =>
      '無料版は直近20回まで表示できます。Proなら全履歴・グラフ・統計で成長がもっと見えるようになります。';

  @override
  String get paywallBodyChart => '詳細なグラフで成長を追跡できます。Proで利用可能。';

  @override
  String get paywallBodyTheme => '好きな色でアプリの見た目をカスタマイズ。Proで利用可能。';

  @override
  String get paywallBodyStats => '週間・月間の詳細な統計を確認できます。Proで利用可能。';

  @override
  String get paywallBodyExport => 'ワークアウトデータをCSVでエクスポート。Proで利用可能。';

  @override
  String get paywallCtaTryPro => 'Proを試す';

  @override
  String get paywallCtaNotNow => '今はしない';

  @override
  String get paywallCompareHistory => '履歴';

  @override
  String get paywallCompareLast20 => '直近20件';

  @override
  String get paywallCompareUnlimited => '無制限';

  @override
  String get paywallCompareCharts => 'グラフ';

  @override
  String get paywallCompareTheme => 'テーマ';

  @override
  String get paywallCompareDefault => 'デフォルト';

  @override
  String get paywallCompareCustom => 'カスタム';

  @override
  String get lockedSessionHint => 'Proで全履歴を表示';

  @override
  String get lockedSessionSubHint => '無料版は直近20回まで。過去の成長を全部見返すにはProへ';

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
  String get paywallTitleBackup => 'データをバックアップ';

  @override
  String get paywallBodyBackup => 'データをバックアップして新しい端末に移行できます。Proで利用可能。';

  @override
  String get backupLabel => 'バックアップ';

  @override
  String get backupTitle => 'バックアップ / 復元';

  @override
  String get backupSectionTitle => 'バックアップを作成';

  @override
  String get backupSectionDescription => 'トレーニングデータをファイルに保存します';

  @override
  String get createBackupButton => 'バックアップを作成';

  @override
  String get restoreSectionTitle => 'バックアップから復元';

  @override
  String get restoreSectionDescription => '保存したファイルからデータを復元します';

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
  String get paywallTrialTitle => '1ヶ月間無料でお試し';

  @override
  String get paywallTrialDescription =>
      'Proの全機能を1ヶ月間無料でお試しいただけます。無料期間終了後は自動的に課金が開始されます。';

  @override
  String get paywallTrialNotice => '課金を避けるには、無料期間中にいつでも解約できます。';

  @override
  String get paywallCtaStartTrial => '無料で始める';

  @override
  String get settingsManageSubscription => 'サブスクリプションを管理';

  @override
  String get settingsManageSubscriptionHint => '解約やプラン変更はこちら';

  @override
  String get paywallSubscriptionDisclaimer =>
      '無料トライアル終了後、Apple IDアカウントに課金されます。サブスクリプションは現在の期間終了の24時間前までに解約しない限り自動更新されます。サブスクリプションの管理・解約はApple IDのアカウント設定から行えます。';
}
