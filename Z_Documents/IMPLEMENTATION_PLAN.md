# Free/Pro収益化モデル 実装計画書

## 目次
1. [要件定義](#1-要件定義)
2. [実装設計](#2-実装設計)
3. [実装タスクリスト](#3-実装タスクリスト)
4. [コードスケルトン](#4-コードスケルトン)

---

# 1. 要件定義

## 1.1 Free/Pro境界の定義

### 保存ポリシー（全ユーザー共通）
| 項目 | Free | Pro |
|------|------|-----|
| ワークアウト記録保存 | **無制限** | **無制限** |
| データ自動削除 | なし | なし |

> **重要方針**: ユーザー資産（記録データ）は絶対に奪わない。差別化は「閲覧・分析・カスタマイズ」のみ。

### 閲覧制限の定義

#### 「直近20セッション」の厳密定義
```
対象: status = 'completed' のワークアウトセッション
並び順: completed_at DESC（新しい順）
カウント: 上位20件が「詳細閲覧可能」
21件目以降: サマリのみ表示、詳細はロック
```

| 条件 | 動作 |
|------|------|
| セッション削除時 | 削除後に再カウント（21件目が20件目に昇格） |
| 進行中セッション | カウント対象外（status = 'in_progress'） |
| 同日複数セッション | 各セッションを個別カウント |

#### セッション表示の分類
| 範囲 | 表示内容 | 詳細タップ |
|------|----------|-----------|
| 直近20件 | フル表示（日付・種目・セット数・メモ等） | 詳細画面へ遷移 |
| 21件目以降 | サマリのみ（日付・種目数・ロックアイコン） | Paywall表示 |

### 機能制限マトリクス

| 機能 | Free | Pro | 課金トリガー |
|------|------|-----|-------------|
| ワークアウト記録 | ✅ | ✅ | - |
| 前回記録表示 | ✅ | ✅ | - |
| 前回値コピー/再現 | ✅ | ✅ | - |
| タイマー | ✅ | ✅ | - |
| 単位切替（kg/lb） | ✅ | ✅ | - |
| 言語切替（en/ja） | ✅ | ✅ | - |
| 履歴詳細（直近20件） | ✅ | ✅ | - |
| 履歴詳細（21件目以降） | ❌ロック | ✅ | 古い履歴タップ時 |
| 種目別成長グラフ | ❌ | ✅ | グラフ画面アクセス時 |
| 種目検索・フィルタ | 制限付き | ✅ | 高度検索使用時 |
| 月/週統計 | 簡易のみ | フル | 統計詳細アクセス時 |
| テーマカスタマイズ | ❌ | ✅ | テーマ変更試行時 |
| バックアップ/復元 | ❌ | ✅ | バックアップ試行時 |

---

## 1.2 Pro誘導UX仕様

### 誘導トリガーポイント
| トリガー | 発火条件 | Paywall reason |
|----------|----------|----------------|
| 履歴ロック | 21件目以降のセッションをタップ | `history_locked` |
| グラフアクセス | ExerciseProgressScreen へ遷移試行 | `chart` |
| テーマ変更 | テーマ設定UIを操作 | `theme` |
| 高度統計 | 月/週統計の詳細を開く | `stats` |
| バックアップ | バックアップボタンタップ | `backup` |

### 絶対に誘導しない場所
- `WorkoutInputScreen`（記録入力中）
- タイマー操作中
- 基本設定変更（言語・単位）

### ロック行表示仕様（履歴一覧）

**日本語:**
```
[ロックアイコン] 2024/01/15 - 3種目
「Proで全履歴を表示」
```

**英語:**
```
[Lock Icon] Jan 15, 2024 - 3 exercises
"Unlock full history with Pro"
```

### Paywall画面仕様

#### 構成要素
```
┌─────────────────────────────────────┐
│            [クローズボタン]           │
├─────────────────────────────────────┤
│                                     │
│    [アイコン/イラスト]                │
│                                     │
│    タイトル（reason別）               │
│    本文（1-2行）                      │
│                                     │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │  Free        Pro            │   │
│  ├─────────────────────────────┤   │
│  │  直近20件    全履歴          │   │
│  │  グラフなし   成長グラフ      │   │
│  │  デフォルト   テーマ自由      │   │
│  └─────────────────────────────┘   │
│                                     │
│    ¥250/月  または  ¥2,500/年       │
│                                     │
│  [====== Proを試す ======]          │
│         今はしない                   │
│                                     │
└─────────────────────────────────────┘
```

#### reason別テキスト

| reason | タイトル(ja) | タイトル(en) |
|--------|-------------|-------------|
| `history_locked` | 過去の記録をすべて見返す | View your full history |
| `chart` | 成長をグラフで確認 | See your progress in charts |
| `theme` | 自分だけのテーマに | Personalize your theme |
| `stats` | 詳しい統計を見る | View detailed stats |
| `backup` | データをバックアップ | Backup your data |

---

## 1.3 テーマカスタマイズ仕様

### 変更可能項目
| 項目 | 説明 | ColorScheme対応 |
|------|------|-----------------|
| Primary Color | メインカラー | `primary` |
| Secondary Color | サブカラー（アクセント） | `secondary` |
| On Primary | Primary上のテキスト色 | `onPrimary` |
| Background | 背景色（任意） | `surface` |

### プリセットテーマ
```dart
enum PresetTheme {
  defaultBlue,    // 現在のデフォルト
  forestGreen,    // 緑系
  sunsetOrange,   // オレンジ系
  midnightPurple, // 紫系
  crimsonRed,     // 赤系
  oceanTeal,      // ティール系
}
```

### カスタムカラー入力
- 形式: `#RRGGBB` または `#AARRGGBB`
- バリデーション: 正規表現 `^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$`
- 不正値: エラー表示、適用不可

### コントラストガード
```dart
// 最小コントラスト比（WCAG AA準拠目安）
const double minContrastRatio = 4.5;

// 判定ロジック
bool hasAdequateContrast(Color foreground, Color background) {
  final ratio = calculateContrastRatio(foreground, background);
  return ratio >= minContrastRatio;
}

// コントラスト不足時
- 警告メッセージ表示
- 適用は許可（ユーザー責任）
```

### 永続化
- 保存先: `settings` テーブル（新規カラム追加）
- 形式: JSON文字列
```json
{
  "preset": "custom",
  "primary": "#1976D2",
  "secondary": "#FF9800",
  "onPrimary": "#FFFFFF",
  "background": null
}
```

---

## 1.4 バックアップ/復元機能仕様

### 概要
端末移動時にデータを移行できるよう、全ワークアウトデータをJSON形式でエクスポート/インポートする機能。

### バックアップファイル形式
```json
{
  "version": "1.0",
  "createdAt": "2024-01-15T10:30:00Z",
  "appVersion": "1.2.0",
  "data": {
    "exercises": [...],
    "workoutSessions": [...],
    "workoutExercises": [...],
    "workoutSets": [...],
    "exerciseMemos": [...],
    "settings": {...}
  }
}
```

### ファイル命名規則
```
fitness_log_backup_YYYYMMDD_HHMMSS.json
例: fitness_log_backup_20240115_103000.json
```

### バックアップ対象データ
| テーブル | 説明 | 含める |
|----------|------|--------|
| `exercises` | 種目マスタ | ✅ |
| `workout_sessions` | セッション | ✅ |
| `workout_exercises` | セッション内種目 | ✅ |
| `workout_sets` | セット記録 | ✅ |
| `exercise_memos` | 種目メモ | ✅ |
| `settings` | 設定（テーマ含む） | ✅ |

### 復元時の動作
| 項目 | 動作 |
|------|------|
| 既存データ | **完全上書き**（確認ダイアログで警告） |
| 重複チェック | IDベースでマージ（同一IDは上書き） |
| 設定 | バックアップの設定で上書き |
| テーマ | バックアップのテーマ設定を復元 |

### 復元確認ダイアログ
```
┌─────────────────────────────────────┐
│        ⚠️ データを復元しますか？        │
├─────────────────────────────────────┤
│                                     │
│  バックアップ日時: 2024/01/15 10:30   │
│  セッション数: 150件                  │
│  種目数: 25種目                       │
│                                     │
│  ⚠️ 現在のデータは上書きされます        │
│                                     │
│  [キャンセル]        [復元する]       │
│                                     │
└─────────────────────────────────────┘
```

### エラーハンドリング
| エラー | 対応 |
|--------|------|
| ファイル形式エラー | 「無効なバックアップファイルです」表示 |
| バージョン非互換 | 「このバージョンには対応していません」表示 |
| データ破損 | 復元中止、元データ維持 |
| ストレージ不足 | 「ストレージ容量が不足しています」表示 |

### ファイル共有方法
- iOS: Share Sheet（AirDrop, iCloud Drive, Files等）
- Android: Share Intent（Google Drive, Files等）
- バックアップ完了後、自動で共有ダイアログ表示

---

# 2. 実装設計

## 2.1 ドメインモデル

### Entitlement（課金状態）
```dart
enum Entitlement {
  free,
  pro,
}

class EntitlementState {
  final Entitlement entitlement;
  final DateTime? expiresAt;      // Pro有効期限（null = 永久 or Free）
  final String? subscriptionType; // 'monthly' | 'yearly' | null

  bool get isPro => entitlement == Entitlement.pro;
  bool get isFree => entitlement == Entitlement.free;
}
```

### ThemeSettings
```dart
class ThemeSettings {
  final PresetTheme? preset;      // プリセット使用時
  final String? primaryHex;       // カスタム Primary
  final String? secondaryHex;     // カスタム Secondary
  final String? onPrimaryHex;     // カスタム OnPrimary
  final String? backgroundHex;    // カスタム Background

  bool get isCustom => preset == null || preset == PresetTheme.custom;
}
```

## 2.2 アーキテクチャ設計

### レイヤー構成
```
┌─────────────────────────────────────────────────┐
│                    UI Layer                      │
│  (Screens, Widgets, Paywall)                     │
├─────────────────────────────────────────────────┤
│                Provider Layer                    │
│  ┌────────────┐ ┌──────────────┐ ┌────────────┐│
│  │Entitlement │ │FeatureGate  │ │ThemeSettings││
│  │Provider    │ │Provider     │ │Provider     ││
│  └────────────┘ └──────────────┘ └────────────┘│
├─────────────────────────────────────────────────┤
│               Data/Repository                    │
│  ┌────────────┐ ┌──────────────┐ ┌────────────┐│
│  │IAP Service │ │Settings DAO │ │Theme DAO   ││
│  │(Stub→Real)│ │             │ │             ││
│  └────────────┘ └──────────────┘ └────────────┘│
└─────────────────────────────────────────────────┘
```

### プロバイダー設計

```dart
// 課金状態プロバイダー（スタブ→IAP差し替え可能）
final entitlementProvider = StateNotifierProvider<EntitlementNotifier, EntitlementState>(...);

// 機能ゲートプロバイダー
final featureGateProvider = Provider<FeatureGate>((ref) {
  final entitlement = ref.watch(entitlementProvider);
  return FeatureGate(entitlement);
});

// テーマ設定プロバイダー
final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(...);

// 動的テーマデータプロバイダー
final appThemeDataProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return ThemeGenerator.generate(settings);
});
```

## 2.3 UI上のゲート方法

### 履歴閲覧制限
```dart
// HistoryScreen での実装
final sessions = await workoutSessionDao.getAllCompleted();
final freeLimit = 20;
final isPro = ref.read(entitlementProvider).isPro;

for (var i = 0; i < sessions.length; i++) {
  final isLocked = !isPro && i >= freeLimit;
  yield HistoryItem(
    session: sessions[i],
    isLocked: isLocked,
  );
}

// タップ時
onTap: () {
  if (item.isLocked) {
    showPaywall(context, reason: PaywallReason.historyLocked);
  } else {
    Navigator.push(...);  // 詳細画面へ
  }
}
```

### 機能ゲート（FeatureGate）
```dart
class FeatureGate {
  final EntitlementState entitlement;

  bool get canAccessFullHistory => entitlement.isPro;
  bool get canAccessCharts => entitlement.isPro;
  bool get canCustomizeTheme => entitlement.isPro;
  bool get canAccessDetailedStats => entitlement.isPro;
  bool get canBackup => entitlement.isPro;

  // 履歴のロック判定
  bool isSessionLocked(int sessionIndex) {
    if (entitlement.isPro) return false;
    return sessionIndex >= 20;
  }
}
```

### 画面遷移ガード
```dart
// ExerciseProgressScreen へのナビゲーション
void navigateToProgress(BuildContext context, WidgetRef ref, Exercise exercise) {
  final gate = ref.read(featureGateProvider);

  if (!gate.canAccessCharts) {
    showPaywall(context, reason: PaywallReason.chart);
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExerciseProgressScreen(exercise: exercise),
    ),
  );
}
```

## 2.4 Paywall設計

### 共通コンポーネント
```dart
class PaywallModal extends ConsumerWidget {
  final PaywallReason reason;

  // reason に応じたテキスト取得
  String _getTitle(AppLocalizations l10n) {
    switch (reason) {
      case PaywallReason.historyLocked:
        return l10n.paywallTitleHistory;
      case PaywallReason.chart:
        return l10n.paywallTitleChart;
      case PaywallReason.theme:
        return l10n.paywallTitleTheme;
      // ...
    }
  }
}
```

### 表示関数
```dart
Future<bool> showPaywall(
  BuildContext context, {
  required PaywallReason reason,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PaywallModal(reason: reason),
  );
  return result ?? false;
}
```

## 2.5 テーマ管理設計

### ThemeData生成
```dart
class ThemeGenerator {
  static ThemeData generate(ThemeSettings settings) {
    final colorScheme = _buildColorScheme(settings);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      // 既存のスタイルを維持
    );
  }

  static ColorScheme _buildColorScheme(ThemeSettings settings) {
    if (settings.preset != null && settings.preset != PresetTheme.custom) {
      return _getPresetColorScheme(settings.preset!);
    }

    return ColorScheme.fromSeed(
      seedColor: HexColor.parse(settings.primaryHex ?? '#1976D2'),
      primary: HexColor.parse(settings.primaryHex ?? '#1976D2'),
      secondary: settings.secondaryHex != null
          ? HexColor.parse(settings.secondaryHex!)
          : null,
      onPrimary: settings.onPrimaryHex != null
          ? HexColor.parse(settings.onPrimaryHex!)
          : null,
      surface: settings.backgroundHex != null
          ? HexColor.parse(settings.backgroundHex!)
          : null,
    );
  }
}
```

### Hex Parser & Validation
```dart
class HexColor {
  static final _hexPattern = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$');

  static bool isValid(String hex) => _hexPattern.hasMatch(hex);

  static Color parse(String hex) {
    if (!isValid(hex)) {
      throw FormatException('Invalid hex color: $hex');
    }

    String hexValue = hex.replaceFirst('#', '');
    if (hexValue.length == 6) {
      hexValue = 'FF$hexValue';  // Add alpha
    }
    return Color(int.parse(hexValue, radix: 16));
  }

  static String toHex(Color color, {bool includeAlpha = false}) {
    if (includeAlpha) {
      return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    }
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
```

### コントラストガード
```dart
class ContrastChecker {
  static const double minContrastRatio = 4.5;

  static double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = max(fgLuminance, bgLuminance);
    final darker = min(fgLuminance, bgLuminance);

    return (lighter + 0.05) / (darker + 0.05);
  }

  static bool hasAdequateContrast(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= minContrastRatio;
  }

  static ContrastResult check(ThemeSettings settings) {
    final primary = HexColor.parse(settings.primaryHex ?? '#1976D2');
    final onPrimary = HexColor.parse(settings.onPrimaryHex ?? '#FFFFFF');

    final ratio = calculateContrastRatio(onPrimary, primary);
    final isAdequate = ratio >= minContrastRatio;

    return ContrastResult(
      ratio: ratio,
      isAdequate: isAdequate,
      message: isAdequate
          ? null
          : 'Low contrast may affect readability',
    );
  }
}
```

## 2.6 DBスキーマ変更

### settings テーブル拡張
```sql
ALTER TABLE settings ADD COLUMN entitlement TEXT DEFAULT 'free';
ALTER TABLE settings ADD COLUMN theme_settings TEXT DEFAULT NULL;
```

### 新規カラム
| カラム | 型 | 説明 |
|--------|------|------|
| `entitlement` | TEXT | 'free' \| 'pro' |
| `theme_settings` | TEXT | JSON形式のテーマ設定 |

---

# 3. 実装タスクリスト

## Phase 1: 基盤整備（課金状態管理）

| # | タスク | ファイル | 優先度 |
|---|--------|----------|--------|
| 1.1 | Entitlement モデル作成 | `lib/data/models/entitlement.dart` | P0 |
| 1.2 | EntitlementProvider 作成（スタブ） | `lib/providers/entitlement_provider.dart` | P0 |
| 1.3 | FeatureGate ヘルパー作成 | `lib/utils/feature_gate.dart` | P0 |
| 1.4 | DBマイグレーション（v5→v6） | `lib/data/database/database_helper.dart` | P0 |
| 1.5 | 開発用: Pro/Free切替スイッチ | `lib/features/settings/` | P0 |

## Phase 2: 履歴閲覧制限

| # | タスク | ファイル | 優先度 |
|---|--------|----------|--------|
| 2.1 | HistoryItem モデル拡張（isLocked追加） | `lib/features/history/models/` | P0 |
| 2.2 | 履歴一覧のロック判定ロジック | `lib/features/history/providers/` | P0 |
| 2.3 | ロック行UIコンポーネント | `lib/features/history/widgets/locked_session_tile.dart` | P0 |
| 2.4 | 詳細画面遷移ガード | `lib/features/history/screens/history_screen.dart` | P0 |

## Phase 3: Paywall

| # | タスク | ファイル | 優先度 |
|---|--------|----------|--------|
| 3.1 | PaywallReason enum作成 | `lib/features/paywall/models/` | P0 |
| 3.2 | Paywall多言語テキスト追加 | `lib/l10n/` | P0 |
| 3.3 | PaywallModal ウィジェット | `lib/features/paywall/widgets/paywall_modal.dart` | P0 |
| 3.4 | showPaywall 関数 | `lib/features/paywall/paywall_service.dart` | P0 |
| 3.5 | 比較表コンポーネント | `lib/features/paywall/widgets/comparison_table.dart` | P0 |

## Phase 4: グラフ/統計ゲート

| # | タスク | ファイル | 優先度 |
|---|--------|----------|--------|
| 4.1 | ExerciseProgressScreen ゲート追加 | `lib/features/exercise_progress/` | P1 |
| 4.2 | 統計画面の制限実装 | `lib/features/home/` | P1 |
| 4.3 | グラフアクセス時Paywall表示 | 各画面 | P1 |

## Phase 5: テーマカスタマイズ

| # | タスク | ファイル | 優先度 |
|---|--------|----------|--------|
| 5.1 | ThemeSettings モデル | `lib/data/models/theme_settings.dart` | P1 |
| 5.2 | PresetTheme enum & 定義 | `lib/data/models/preset_theme.dart` | P1 |
| 5.3 | HexColor ユーティリティ | `lib/utils/hex_color.dart` | P1 |
| 5.4 | ContrastChecker | `lib/utils/contrast_checker.dart` | P1 |
| 5.5 | ThemeGenerator | `lib/utils/theme_generator.dart` | P1 |
| 5.6 | ThemeSettingsProvider | `lib/providers/theme_settings_provider.dart` | P1 |
| 5.7 | テーマ設定画面 | `lib/features/settings/screens/theme_settings_screen.dart` | P1 |
| 5.8 | プレビューコンポーネント | `lib/features/settings/widgets/theme_preview.dart` | P1 |
| 5.9 | カラーピッカー入力 | `lib/features/settings/widgets/color_input.dart` | P1 |
| 5.10 | main.dart テーマ適用 | `lib/main.dart` | P1 |
| 5.11 | テーマ設定永続化 | `lib/data/dao/settings_dao.dart` | P1 |

## Phase 6: バックアップ/復元機能（端末移動対応）

| # | タスク | ファイル | 優先度 |
|---|--------|----------|--------|
| 6.1 | BackupData モデル作成 | `lib/data/models/backup_data.dart` | P1 |
| 6.2 | BackupService 実装（JSON形式） | `lib/services/backup_service.dart` | P1 |
| 6.3 | バックアップ画面 UI | `lib/features/settings/screens/backup_screen.dart` | P1 |
| 6.4 | バックアップボタン + ゲート | `lib/features/settings/settings_screen.dart` | P1 |
| 6.5 | ファイル共有/保存機能 | `lib/services/file_sharing_service.dart` | P1 |
| 6.6 | 復元機能（ファイル選択 + インポート） | `lib/services/backup_service.dart` | P1 |
| 6.7 | 復元確認ダイアログ | `lib/features/settings/widgets/restore_confirm_dialog.dart` | P1 |
| 6.8 | Paywall l10n追加（backup関連） | `lib/l10n/` | P1 |

## Phase 7: IAP統合（最後）

| # | タスク | ファイル | 優先度 |
|---|--------|----------|--------|
| 7.1 | in_app_purchase パッケージ追加 | `pubspec.yaml` | P1 |
| 7.2 | IAPService 実装 | `lib/services/iap_service.dart` | P1 |
| 7.3 | EntitlementProvider をIAP接続 | `lib/providers/entitlement_provider.dart` | P1 |
| 7.4 | 購入フロー実装 | Paywall内 | P1 |
| 7.5 | 復元機能 | Settings内 | P1 |

---

# 4. コードスケルトン

## 4.1 Entitlement Provider（スタブ）

```dart
// lib/data/models/entitlement.dart
enum Entitlement {
  free,
  pro,
}

class EntitlementState {
  final Entitlement entitlement;
  final DateTime? expiresAt;
  final String? subscriptionType;

  const EntitlementState({
    this.entitlement = Entitlement.free,
    this.expiresAt,
    this.subscriptionType,
  });

  bool get isPro => entitlement == Entitlement.pro;
  bool get isFree => entitlement == Entitlement.free;

  EntitlementState copyWith({
    Entitlement? entitlement,
    DateTime? expiresAt,
    String? subscriptionType,
  }) {
    return EntitlementState(
      entitlement: entitlement ?? this.entitlement,
      expiresAt: expiresAt ?? this.expiresAt,
      subscriptionType: subscriptionType ?? this.subscriptionType,
    );
  }
}
```

```dart
// lib/providers/entitlement_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/entitlement.dart';

class EntitlementNotifier extends StateNotifier<EntitlementState> {
  EntitlementNotifier() : super(const EntitlementState());

  // スタブ: 開発用切り替え
  void togglePro() {
    state = state.copyWith(
      entitlement: state.isPro ? Entitlement.free : Entitlement.pro,
    );
  }

  // 後でIAP接続時に実装
  Future<void> checkEntitlement() async {
    // TODO: IAP購入状態を確認
  }

  Future<void> purchaseMonthly() async {
    // TODO: 月額購入フロー
  }

  Future<void> purchaseYearly() async {
    // TODO: 年額購入フロー
  }

  Future<void> restorePurchases() async {
    // TODO: 購入復元
  }
}

final entitlementProvider = StateNotifierProvider<EntitlementNotifier, EntitlementState>(
  (ref) => EntitlementNotifier(),
);
```

## 4.2 Feature Gate Helper

```dart
// lib/utils/feature_gate.dart
import '../data/models/entitlement.dart';

class FeatureGate {
  final EntitlementState entitlement;

  const FeatureGate(this.entitlement);

  static const int freeHistoryLimit = 20;

  bool get canAccessFullHistory => entitlement.isPro;
  bool get canAccessCharts => entitlement.isPro;
  bool get canCustomizeTheme => entitlement.isPro;
  bool get canAccessDetailedStats => entitlement.isPro;
  bool get canBackup => entitlement.isPro;

  /// セッションがロックされているか判定
  /// [sessionIndex] は 0-indexed（新しい順）
  bool isSessionLocked(int sessionIndex) {
    if (entitlement.isPro) return false;
    return sessionIndex >= freeHistoryLimit;
  }

  /// ロック対象のセッション数を計算
  int getLockedCount(int totalSessions) {
    if (entitlement.isPro) return 0;
    return (totalSessions - freeHistoryLimit).clamp(0, totalSessions);
  }
}

// Provider
final featureGateProvider = Provider<FeatureGate>((ref) {
  final entitlement = ref.watch(entitlementProvider);
  return FeatureGate(entitlement);
});
```

## 4.3 History Lock判定ロジック

```dart
// lib/features/history/models/history_item.dart
import '../../../data/entities/workout_session_entity.dart';

class HistoryItem {
  final WorkoutSessionEntity session;
  final int index;  // 0-indexed, 新しい順
  final bool isLocked;
  final int exerciseCount;

  const HistoryItem({
    required this.session,
    required this.index,
    required this.isLocked,
    required this.exerciseCount,
  });
}
```

```dart
// lib/features/history/providers/history_provider.dart
final historyItemsProvider = FutureProvider<List<HistoryItem>>((ref) async {
  final sessionDao = ref.read(workoutSessionDaoProvider);
  final exerciseDao = ref.read(workoutExerciseDaoProvider);
  final gate = ref.read(featureGateProvider);

  final sessions = await sessionDao.getCompletedSessions();
  // sessions は completed_at DESC で並んでいる想定

  final items = <HistoryItem>[];
  for (var i = 0; i < sessions.length; i++) {
    final exerciseCount = await exerciseDao.getCountBySessionId(sessions[i].id!);
    items.add(HistoryItem(
      session: sessions[i],
      index: i,
      isLocked: gate.isSessionLocked(i),
      exerciseCount: exerciseCount,
    ));
  }

  return items;
});
```

## 4.4 Theme Settings Model & Provider

```dart
// lib/data/models/preset_theme.dart
import 'package:flutter/material.dart';

enum PresetTheme {
  defaultBlue,
  forestGreen,
  sunsetOrange,
  midnightPurple,
  crimsonRed,
  oceanTeal,
  custom,
}

extension PresetThemeExtension on PresetTheme {
  String get displayName {
    switch (this) {
      case PresetTheme.defaultBlue:
        return 'Default Blue';
      case PresetTheme.forestGreen:
        return 'Forest Green';
      case PresetTheme.sunsetOrange:
        return 'Sunset Orange';
      case PresetTheme.midnightPurple:
        return 'Midnight Purple';
      case PresetTheme.crimsonRed:
        return 'Crimson Red';
      case PresetTheme.oceanTeal:
        return 'Ocean Teal';
      case PresetTheme.custom:
        return 'Custom';
    }
  }

  Color get primaryColor {
    switch (this) {
      case PresetTheme.defaultBlue:
        return const Color(0xFF1976D2);
      case PresetTheme.forestGreen:
        return const Color(0xFF2E7D32);
      case PresetTheme.sunsetOrange:
        return const Color(0xFFE65100);
      case PresetTheme.midnightPurple:
        return const Color(0xFF6A1B9A);
      case PresetTheme.crimsonRed:
        return const Color(0xFFC62828);
      case PresetTheme.oceanTeal:
        return const Color(0xFF00796B);
      case PresetTheme.custom:
        return const Color(0xFF1976D2);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case PresetTheme.defaultBlue:
        return const Color(0xFF42A5F5);
      case PresetTheme.forestGreen:
        return const Color(0xFF81C784);
      case PresetTheme.sunsetOrange:
        return const Color(0xFFFFB74D);
      case PresetTheme.midnightPurple:
        return const Color(0xFFBA68C8);
      case PresetTheme.crimsonRed:
        return const Color(0xFFEF5350);
      case PresetTheme.oceanTeal:
        return const Color(0xFF4DB6AC);
      case PresetTheme.custom:
        return const Color(0xFF42A5F5);
    }
  }
}
```

```dart
// lib/data/models/theme_settings.dart
import 'dart:convert';
import 'preset_theme.dart';

class ThemeSettings {
  final PresetTheme preset;
  final String? primaryHex;
  final String? secondaryHex;
  final String? onPrimaryHex;
  final String? backgroundHex;

  const ThemeSettings({
    this.preset = PresetTheme.defaultBlue,
    this.primaryHex,
    this.secondaryHex,
    this.onPrimaryHex,
    this.backgroundHex,
  });

  bool get isCustom => preset == PresetTheme.custom;

  ThemeSettings copyWith({
    PresetTheme? preset,
    String? primaryHex,
    String? secondaryHex,
    String? onPrimaryHex,
    String? backgroundHex,
  }) {
    return ThemeSettings(
      preset: preset ?? this.preset,
      primaryHex: primaryHex ?? this.primaryHex,
      secondaryHex: secondaryHex ?? this.secondaryHex,
      onPrimaryHex: onPrimaryHex ?? this.onPrimaryHex,
      backgroundHex: backgroundHex ?? this.backgroundHex,
    );
  }

  String toJson() {
    return jsonEncode({
      'preset': preset.name,
      'primaryHex': primaryHex,
      'secondaryHex': secondaryHex,
      'onPrimaryHex': onPrimaryHex,
      'backgroundHex': backgroundHex,
    });
  }

  factory ThemeSettings.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return ThemeSettings(
      preset: PresetTheme.values.firstWhere(
        (e) => e.name == map['preset'],
        orElse: () => PresetTheme.defaultBlue,
      ),
      primaryHex: map['primaryHex'] as String?,
      secondaryHex: map['secondaryHex'] as String?,
      onPrimaryHex: map['onPrimaryHex'] as String?,
      backgroundHex: map['backgroundHex'] as String?,
    );
  }

  static const ThemeSettings defaultSettings = ThemeSettings();
}
```

## 4.5 Hex Parser & Validation

```dart
// lib/utils/hex_color.dart
import 'package:flutter/material.dart';

class HexColor {
  static final _hexPattern = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$');

  /// Hexカラーコードが有効かチェック
  static bool isValid(String? hex) {
    if (hex == null) return false;
    return _hexPattern.hasMatch(hex);
  }

  /// Hexカラーコードを Color に変換
  /// 無効な場合は FormatException をスロー
  static Color parse(String hex) {
    if (!isValid(hex)) {
      throw FormatException('Invalid hex color: $hex');
    }

    String hexValue = hex.replaceFirst('#', '');
    if (hexValue.length == 6) {
      hexValue = 'FF$hexValue';
    }
    return Color(int.parse(hexValue, radix: 16));
  }

  /// Hexカラーコードを Color に変換（失敗時はデフォルト値）
  static Color tryParse(String? hex, {Color defaultColor = Colors.blue}) {
    if (hex == null || !isValid(hex)) {
      return defaultColor;
    }
    return parse(hex);
  }

  /// Color を Hexカラーコードに変換
  static String toHex(Color color, {bool includeAlpha = false}) {
    if (includeAlpha) {
      return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    }
    return '#${(color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
```

## 4.6 Contrast Guard

```dart
// lib/utils/contrast_checker.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ContrastResult {
  final double ratio;
  final bool isAdequate;
  final String? warningMessage;

  const ContrastResult({
    required this.ratio,
    required this.isAdequate,
    this.warningMessage,
  });
}

class ContrastChecker {
  /// WCAG AA準拠の最小コントラスト比
  static const double minContrastRatio = 4.5;

  /// 2色間のコントラスト比を計算
  static double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = max(fgLuminance, bgLuminance);
    final darker = min(fgLuminance, bgLuminance);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// コントラストが十分かチェック
  static bool hasAdequateContrast(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= minContrastRatio;
  }

  /// Primary と onPrimary のコントラストをチェック
  static ContrastResult checkPrimaryContrast(Color primary, Color onPrimary) {
    final ratio = calculateContrastRatio(onPrimary, primary);
    final isAdequate = ratio >= minContrastRatio;

    return ContrastResult(
      ratio: ratio,
      isAdequate: isAdequate,
      warningMessage: isAdequate
          ? null
          : 'Low contrast (${ratio.toStringAsFixed(1)}:1) may affect readability. Recommended: ${minContrastRatio}:1 or higher.',
    );
  }
}
```

## 4.7 ThemeData生成関数

```dart
// lib/utils/theme_generator.dart
import 'package:flutter/material.dart';
import '../data/models/theme_settings.dart';
import '../data/models/preset_theme.dart';
import 'hex_color.dart';

class ThemeGenerator {
  /// ThemeSettings から ThemeData を生成
  static ThemeData generate(ThemeSettings settings) {
    final colorScheme = _buildColorScheme(settings);

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      // 既存のスタイリングを維持
    );
  }

  static ColorScheme _buildColorScheme(ThemeSettings settings) {
    if (!settings.isCustom) {
      // プリセットテーマの場合
      return ColorScheme.fromSeed(
        seedColor: settings.preset.primaryColor,
        primary: settings.preset.primaryColor,
        secondary: settings.preset.secondaryColor,
      );
    }

    // カスタムテーマの場合
    final primary = HexColor.tryParse(
      settings.primaryHex,
      defaultColor: PresetTheme.defaultBlue.primaryColor,
    );

    final secondary = HexColor.tryParse(
      settings.secondaryHex,
      defaultColor: PresetTheme.defaultBlue.secondaryColor,
    );

    final onPrimary = settings.onPrimaryHex != null
        ? HexColor.tryParse(settings.onPrimaryHex!)
        : null;

    final surface = settings.backgroundHex != null
        ? HexColor.tryParse(settings.backgroundHex!)
        : null;

    // fromSeed でベースを作り、必要な部分を上書き
    var scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
    );

    if (onPrimary != null) {
      scheme = scheme.copyWith(onPrimary: onPrimary);
    }

    if (surface != null) {
      scheme = scheme.copyWith(surface: surface);
    }

    return scheme;
  }
}
```

## 4.8 Theme Settings Provider

```dart
// lib/providers/theme_settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/theme_settings.dart';
import '../data/models/preset_theme.dart';
import '../data/dao/settings_dao.dart';

class ThemeSettingsNotifier extends StateNotifier<ThemeSettings> {
  final SettingsDao _settingsDao;

  ThemeSettingsNotifier(this._settingsDao) : super(ThemeSettings.defaultSettings) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final json = await _settingsDao.getThemeSettings();
    if (json != null) {
      state = ThemeSettings.fromJson(json);
    }
  }

  Future<void> _saveToStorage() async {
    await _settingsDao.saveThemeSettings(state.toJson());
  }

  void setPreset(PresetTheme preset) {
    state = state.copyWith(preset: preset);
    _saveToStorage();
  }

  void setPrimaryColor(String hex) {
    state = state.copyWith(
      preset: PresetTheme.custom,
      primaryHex: hex,
    );
    _saveToStorage();
  }

  void setSecondaryColor(String hex) {
    state = state.copyWith(
      preset: PresetTheme.custom,
      secondaryHex: hex,
    );
    _saveToStorage();
  }

  void setOnPrimaryColor(String hex) {
    state = state.copyWith(
      preset: PresetTheme.custom,
      onPrimaryHex: hex,
    );
    _saveToStorage();
  }

  void setBackgroundColor(String? hex) {
    state = state.copyWith(
      preset: PresetTheme.custom,
      backgroundHex: hex,
    );
    _saveToStorage();
  }

  void reset() {
    state = ThemeSettings.defaultSettings;
    _saveToStorage();
  }
}

final themeSettingsProvider = StateNotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  (ref) {
    final settingsDao = ref.read(settingsDaoProvider);
    return ThemeSettingsNotifier(settingsDao);
  },
);

// 動的テーマデータ
final appThemeDataProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeSettingsProvider);
  return ThemeGenerator.generate(settings);
});
```

## 4.9 Paywall（共通コンポーネント）

```dart
// lib/features/paywall/models/paywall_reason.dart
enum PaywallReason {
  historyLocked,
  chart,
  theme,
  stats,
  export,
}
```

```dart
// lib/features/paywall/widgets/paywall_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/entitlement_provider.dart';
import '../models/paywall_reason.dart';
import 'comparison_table.dart';

class PaywallModal extends ConsumerWidget {
  final PaywallReason reason;

  const PaywallModal({super.key, required this.reason});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entitlement = ref.read(entitlementProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // クローズボタン
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),

            // アイコン
            Icon(
              _getIcon(),
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),

            // タイトル
            Text(
              _getTitle(l10n),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // 本文
            Text(
              _getBody(l10n),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 比較表
            const ComparisonTable(),
            const SizedBox(height: 24),

            // 価格
            Text(
              '¥250/月  または  ¥2,500/年',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // CTAボタン
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  // TODO: 購入フロー
                  await entitlement.purchaseMonthly();
                  Navigator.pop(context, true);
                },
                child: Text(l10n.paywallCtaTryPro),
              ),
            ),
            const SizedBox(height: 8),

            // サブCTA
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.paywallCtaNotNow),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (reason) {
      case PaywallReason.historyLocked:
        return Icons.history;
      case PaywallReason.chart:
        return Icons.show_chart;
      case PaywallReason.theme:
        return Icons.palette;
      case PaywallReason.stats:
        return Icons.analytics;
      case PaywallReason.export:
        return Icons.download;
    }
  }

  String _getTitle(AppLocalizations l10n) {
    switch (reason) {
      case PaywallReason.historyLocked:
        return l10n.paywallTitleHistory;
      case PaywallReason.chart:
        return l10n.paywallTitleChart;
      case PaywallReason.theme:
        return l10n.paywallTitleTheme;
      case PaywallReason.stats:
        return l10n.paywallTitleStats;
      case PaywallReason.export:
        return l10n.paywallTitleExport;
    }
  }

  String _getBody(AppLocalizations l10n) {
    switch (reason) {
      case PaywallReason.historyLocked:
        return l10n.paywallBodyHistory;
      case PaywallReason.chart:
        return l10n.paywallBodyChart;
      case PaywallReason.theme:
        return l10n.paywallBodyTheme;
      case PaywallReason.stats:
        return l10n.paywallBodyStats;
      case PaywallReason.export:
        return l10n.paywallBodyExport;
    }
  }
}
```

```dart
// lib/features/paywall/widgets/comparison_table.dart
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Table(
      border: TableBorder.all(
        color: colorScheme.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      children: [
        // ヘッダー
        TableRow(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
          ),
          children: [
            _cell('', isHeader: true),
            _cell('Free', isHeader: true),
            _cell('Pro', isHeader: true, isPro: true),
          ],
        ),
        // 行1: 履歴
        TableRow(
          children: [
            _cell(l10n.paywallCompareHistory),
            _cell(l10n.paywallCompareLast20),
            _cell(l10n.paywallCompareUnlimited, isPro: true),
          ],
        ),
        // 行2: グラフ
        TableRow(
          children: [
            _cell(l10n.paywallCompareCharts),
            _cell('−'),
            _cell('✓', isPro: true),
          ],
        ),
        // 行3: テーマ
        TableRow(
          children: [
            _cell(l10n.paywallCompareTheme),
            _cell(l10n.paywallCompareDefault),
            _cell(l10n.paywallCompareCustom, isPro: true),
          ],
        ),
      ],
    );
  }

  Widget _cell(String text, {bool isHeader = false, bool isPro = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isPro ? Colors.blue : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
```

```dart
// lib/features/paywall/paywall_service.dart
import 'package:flutter/material.dart';
import 'models/paywall_reason.dart';
import 'widgets/paywall_modal.dart';

/// Paywallを表示し、購入結果を返す
Future<bool> showPaywall(
  BuildContext context, {
  required PaywallReason reason,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaywallModal(reason: reason),
  );
  return result ?? false;
}
```

## 4.10 Backup Model & Service

```dart
// lib/data/models/backup_data.dart
import 'dart:convert';

class BackupData {
  final String version;
  final DateTime createdAt;
  final String appVersion;
  final BackupContent data;

  const BackupData({
    required this.version,
    required this.createdAt,
    required this.appVersion,
    required this.data,
  });

  static const String currentVersion = '1.0';

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'appVersion': appVersion,
    'data': data.toJson(),
  };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      appVersion: json['appVersion'] as String,
      data: BackupContent.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory BackupData.fromJsonString(String jsonString) {
    return BackupData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

class BackupContent {
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> workoutSessions;
  final List<Map<String, dynamic>> workoutExercises;
  final List<Map<String, dynamic>> workoutSets;
  final List<Map<String, dynamic>> exerciseMemos;
  final Map<String, dynamic>? settings;

  const BackupContent({
    required this.exercises,
    required this.workoutSessions,
    required this.workoutExercises,
    required this.workoutSets,
    required this.exerciseMemos,
    this.settings,
  });

  Map<String, dynamic> toJson() => {
    'exercises': exercises,
    'workoutSessions': workoutSessions,
    'workoutExercises': workoutExercises,
    'workoutSets': workoutSets,
    'exerciseMemos': exerciseMemos,
    'settings': settings,
  };

  factory BackupContent.fromJson(Map<String, dynamic> json) {
    return BackupContent(
      exercises: (json['exercises'] as List).cast<Map<String, dynamic>>(),
      workoutSessions: (json['workoutSessions'] as List).cast<Map<String, dynamic>>(),
      workoutExercises: (json['workoutExercises'] as List).cast<Map<String, dynamic>>(),
      workoutSets: (json['workoutSets'] as List).cast<Map<String, dynamic>>(),
      exerciseMemos: (json['exerciseMemos'] as List).cast<Map<String, dynamic>>(),
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }

  int get sessionCount => workoutSessions.length;
  int get exerciseCount => exercises.length;
}
```

```dart
// lib/services/backup_service.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../data/models/backup_data.dart';
import '../data/database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper;

  BackupService(this._dbHelper);

  /// バックアップファイル名を生成
  String _generateFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    return 'fitness_log_backup_${formatter.format(now)}.json';
  }

  /// 全データをバックアップ
  Future<BackupData> createBackup() async {
    final db = await _dbHelper.database;

    // 各テーブルからデータ取得
    final exercises = await db.query('exercises');
    final sessions = await db.query('workout_sessions');
    final workoutExercises = await db.query('workout_exercises');
    final sets = await db.query('workout_sets');
    final memos = await db.query('exercise_memos');
    final settingsList = await db.query('settings');
    final settings = settingsList.isNotEmpty ? settingsList.first : null;

    return BackupData(
      version: BackupData.currentVersion,
      createdAt: DateTime.now(),
      appVersion: '1.0.0', // TODO: パッケージ情報から取得
      data: BackupContent(
        exercises: exercises,
        workoutSessions: sessions,
        workoutExercises: workoutExercises,
        workoutSets: sets,
        exerciseMemos: memos,
        settings: settings,
      ),
    );
  }

  /// バックアップをファイルに保存して共有
  Future<void> exportAndShare() async {
    final backup = await createBackup();
    final jsonString = backup.toJsonString();

    // 一時ファイルに保存
    final tempDir = await getTemporaryDirectory();
    final fileName = _generateFileName();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonString);

    // 共有ダイアログ表示
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Fitness Log Backup',
    );
  }

  /// ファイルを選択してバックアップを読み込む
  Future<BackupData?> pickAndParseBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = File(result.files.first.path!);
    final jsonString = await file.readAsString();

    try {
      return BackupData.fromJsonString(jsonString);
    } catch (e) {
      throw BackupParseException('Invalid backup file format');
    }
  }

  /// バックアップからデータを復元
  Future<void> restore(BackupData backup) async {
    final db = await _dbHelper.database;

    // トランザクションで一括復元
    await db.transaction((txn) async {
      // 既存データを削除（settings以外）
      await txn.delete('workout_sets');
      await txn.delete('workout_exercises');
      await txn.delete('workout_sessions');
      await txn.delete('exercise_memos');
      await txn.delete('exercises');

      // 新データを挿入
      for (final exercise in backup.data.exercises) {
        await txn.insert('exercises', exercise);
      }
      for (final session in backup.data.workoutSessions) {
        await txn.insert('workout_sessions', session);
      }
      for (final we in backup.data.workoutExercises) {
        await txn.insert('workout_exercises', we);
      }
      for (final set in backup.data.workoutSets) {
        await txn.insert('workout_sets', set);
      }
      for (final memo in backup.data.exerciseMemos) {
        await txn.insert('exercise_memos', memo);
      }

      // 設定を更新
      if (backup.data.settings != null) {
        await txn.delete('settings');
        await txn.insert('settings', backup.data.settings!);
      }
    });
  }
}

class BackupParseException implements Exception {
  final String message;
  BackupParseException(this.message);

  @override
  String toString() => message;
}

// Provider
final backupServiceProvider = Provider<BackupService>((ref) {
  final dbHelper = ref.read(databaseHelperProvider);
  return BackupService(dbHelper);
});
```

```dart
// lib/features/settings/screens/backup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/backup_service.dart';
import '../widgets/restore_confirm_dialog.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // バックアップセクション
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.backup, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.backupSectionTitle,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      l10n.backupSectionDescription,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _createBackup,
                              icon: const Icon(Icons.upload),
                              label: Text(l10n.createBackupButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 復元セクション
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.restore, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.restoreSectionTitle,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      l10n.restoreSectionDescription,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _restoreBackup,
                              icon: const Icon(Icons.download),
                              label: Text(l10n.restoreBackupButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 注意事項
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.backupWarning,
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.exportAndShare();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.backupCreated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    final backupService = ref.read(backupServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    try {
      final backup = await backupService.pickAndParseBackup();
      if (backup == null) {
        setState(() => _isLoading = false);
        return; // ユーザーがキャンセル
      }

      setState(() => _isLoading = false);

      // 確認ダイアログ表示
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => RestoreConfirmDialog(backup: backup),
      );

      if (confirmed == true && mounted) {
        setState(() => _isLoading = true);
        await backupService.restore(backup);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.restoreCompleted)),
          );
          // 設定画面に戻る
          Navigator.pop(context, true);
        }
      }
    } on BackupParseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidBackupFile)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
```

```dart
// lib/features/settings/widgets/restore_confirm_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/backup_data.dart';
import '../../../l10n/app_localizations.dart';

class RestoreConfirmDialog extends StatelessWidget {
  final BackupData backup;

  const RestoreConfirmDialog({
    super.key,
    required this.backup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormatter = DateFormat.yMd().add_Hm();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text(l10n.restoreConfirmTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.restoreConfirmBackupDate(
              dateFormatter.format(backup.createdAt),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.restoreConfirmSessionCount(backup.data.sessionCount),
          ),
          Text(
            l10n.restoreConfirmExerciseCount(backup.data.exerciseCount),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.restoreConfirmWarning,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: Text(l10n.restoreButton),
        ),
      ],
    );
  }
}
```

## 4.11 Settings画面に「Theme」セクション（Proゲート＋プレビュー）

```dart
// lib/features/settings/widgets/theme_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/entitlement_provider.dart';
import '../../../providers/theme_settings_provider.dart';
import '../../../utils/feature_gate.dart';
import '../../paywall/paywall_service.dart';
import '../../paywall/models/paywall_reason.dart';
import '../screens/theme_settings_screen.dart';

class ThemeSection extends ConsumerWidget {
  const ThemeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(featureGateProvider);
    final themeSettings = ref.watch(themeSettingsProvider);

    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Theme'),
      subtitle: Text(themeSettings.preset.displayName),
      trailing: gate.canCustomizeTheme
          ? const Icon(Icons.chevron_right)
          : const Icon(Icons.lock, size: 18),
      onTap: () async {
        if (!gate.canCustomizeTheme) {
          await showPaywall(context, reason: PaywallReason.theme);
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ThemeSettingsScreen(),
          ),
        );
      },
    );
  }
}
```

---

# 補足：多言語対応で追加が必要なキー

```dart
// lib/l10n/app_en.arb に追加
{
  "paywallTitleHistory": "View your full history",
  "paywallTitleChart": "See your progress in charts",
  "paywallTitleTheme": "Personalize your theme",
  "paywallTitleStats": "View detailed stats",
  "paywallTitleBackup": "Backup your data",

  "paywallBodyHistory": "Free shows your latest 20 sessions. Go Pro to unlock full history, charts, and stats to see your progress.",
  "paywallBodyChart": "Track your growth with detailed charts and graphs. Available with Pro.",
  "paywallBodyTheme": "Customize your app's look with your favorite colors. Available with Pro.",
  "paywallBodyStats": "Get detailed weekly and monthly statistics. Available with Pro.",
  "paywallBodyBackup": "Back up your data to transfer to a new device. Available with Pro.",

  "paywallCtaTryPro": "Try Pro",
  "paywallCtaNotNow": "Not now",

  "paywallCompareHistory": "History",
  "paywallCompareLast20": "Last 20",
  "paywallCompareUnlimited": "Unlimited",
  "paywallCompareCharts": "Charts",
  "paywallCompareTheme": "Theme",
  "paywallCompareDefault": "Default",
  "paywallCompareCustom": "Custom",

  "lockedSessionHint": "Unlock full history with Pro",
  "lockedSessionSubHint": "Free shows the latest 20 sessions. Go Pro to view everything.",

  "backupTitle": "Backup & Restore",
  "backupSectionTitle": "Create Backup",
  "backupSectionDescription": "Export all your workout data to a file",
  "createBackupButton": "Create Backup",
  "restoreSectionTitle": "Restore from Backup",
  "restoreSectionDescription": "Import data from a backup file",
  "restoreBackupButton": "Select Backup File",
  "backupWarning": "Restoring will overwrite all current data. Make sure to backup current data first if needed.",
  "backupCreated": "Backup created successfully",
  "restoreCompleted": "Data restored successfully",
  "invalidBackupFile": "Invalid backup file format",
  "restoreConfirmTitle": "Restore Data?",
  "restoreConfirmBackupDate": "Backup date: {date}",
  "restoreConfirmSessionCount": "Sessions: {count}",
  "restoreConfirmExerciseCount": "Exercises: {count}",
  "restoreConfirmWarning": "Current data will be overwritten",
  "restoreButton": "Restore"
}
```

```dart
// lib/l10n/app_ja.arb に追加
{
  "paywallTitleHistory": "過去の記録をすべて見返す",
  "paywallTitleChart": "成長をグラフで確認",
  "paywallTitleTheme": "自分だけのテーマに",
  "paywallTitleStats": "詳しい統計を見る",
  "paywallTitleBackup": "データをバックアップ",

  "paywallBodyHistory": "無料版は直近20回まで表示できます。Proなら全履歴・グラフ・統計で成長がもっと見えるようになります。",
  "paywallBodyChart": "詳細なグラフで成長を追跡できます。Proで利用可能。",
  "paywallBodyTheme": "好きな色でアプリの見た目をカスタマイズ。Proで利用可能。",
  "paywallBodyStats": "週間・月間の詳細な統計を確認できます。Proで利用可能。",
  "paywallBodyBackup": "データをバックアップして新しい端末に移行できます。Proで利用可能。",

  "paywallCtaTryPro": "Proを試す",
  "paywallCtaNotNow": "今はしない",

  "paywallCompareHistory": "履歴",
  "paywallCompareLast20": "直近20件",
  "paywallCompareUnlimited": "無制限",
  "paywallCompareCharts": "グラフ",
  "paywallCompareTheme": "テーマ",
  "paywallCompareDefault": "デフォルト",
  "paywallCompareCustom": "カスタム",

  "lockedSessionHint": "Proで全履歴を表示",
  "lockedSessionSubHint": "無料版は直近20回まで。過去の成長を全部見返すにはProへ",

  "backupTitle": "バックアップ / 復元",
  "backupSectionTitle": "バックアップを作成",
  "backupSectionDescription": "全ワークアウトデータをファイルに保存",
  "createBackupButton": "バックアップを作成",
  "restoreSectionTitle": "バックアップから復元",
  "restoreSectionDescription": "バックアップファイルからデータを読み込む",
  "restoreBackupButton": "バックアップファイルを選択",
  "backupWarning": "復元すると現在のデータは上書きされます。必要に応じて先にバックアップを取ってください。",
  "backupCreated": "バックアップを作成しました",
  "restoreCompleted": "データを復元しました",
  "invalidBackupFile": "無効なバックアップファイルです",
  "restoreConfirmTitle": "データを復元しますか？",
  "restoreConfirmBackupDate": "バックアップ日時: {date}",
  "restoreConfirmSessionCount": "セッション数: {count}件",
  "restoreConfirmExerciseCount": "種目数: {count}種目",
  "restoreConfirmWarning": "現在のデータは上書きされます",
  "restoreButton": "復元する"
}
```

---

# 実装順序サマリー

```
Phase 1 (基盤) ──→ Phase 2 (履歴制限) ──→ Phase 3 (Paywall)
     │                    │                      │
     └────────────────────┴──────────────────────┘
                         ↓
              Phase 4 (グラフ/統計ゲート)
                         ↓
              Phase 5 (テーマカスタマイズ)
                         ↓
              Phase 6 (バックアップ/復元)
                         ↓
              Phase 7 (IAP統合) ※最後
```

**重要ポイント:**
- Phase 1-3 までで「スタブPro切り替え + 履歴制限 + Paywall」が動作可能
- Phase 7 まではスタブでPro状態を切り替えてテスト可能
- 各Phaseはテスト可能な単位でコミット可能
