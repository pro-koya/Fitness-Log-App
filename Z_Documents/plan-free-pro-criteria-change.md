# Free / Pro プラン基準変更 — 実装計画

## 1. 変更概要

| 項目 | 現状 | 修正後 |
|------|------|--------|
| グラフ（種目別成長） | Pro のみ | **Free** |
| セッション履歴数 | Free: 直近 **20** 件 / Pro: 無制限 | Free: 直近 **30** 件 / Pro: 無制限 |
| テーマカラー変更 | Pro のみ | **Free** |
| バックアップ/復元 | Pro のみ | **Free** |
| 詳細統計 | Pro のみ（定義のみ、未使用） | **Free** |
| 高度な種目検索 | Pro のみ（定義のみ、未使用） | **Free** |

**Pro の残す価値**: **セッション履歴の無制限閲覧のみ**（直近30件を超える過去履歴の閲覧・詳細表示）

---

## 2. 影響箇所一覧

### 2.1 コア定義（必ず修正）

| ファイル | 変更内容 |
|----------|----------|
| `lib/utils/feature_gate.dart` | ① `freeHistoryLimit`: `20` → `30`<br>② `canAccessCharts`: 常に `true`（`entitlement.isPro` をやめる）<br>③ `canCustomizeTheme`: 常に `true`<br>④ `canAccessDetailedStats`: 常に `true`<br>⑤ `canBackup`: 常に `true`<br>⑥ `canUseAdvancedSearch`: 常に `true`<br>⑦ コメント「直近20件」→「直近30件」 |

**注意**: `canAccessFullHistory` と `isSessionLocked` / `getLockedCount` / `getAccessibleCount` は **変更しない**（Pro のみのまま。履歴件数制限は `freeHistoryLimit` のみで表現）。

---

### 2.2 UI の「ロック／Paywall」解除（ゲート変更で自動的に解除される箇所）

以下の箇所は **FeatureGate の戻り値を変えるだけで**、Free でもロックせず・Paywall を出さずに利用可能になる。

| ファイル | 使用しているゲート | 変更後の挙動 |
|----------|--------------------|--------------|
| `lib/features/settings/settings_screen.dart` | `canCustomizeTheme` | テーマ設定を Free で利用可能に（Paywall 表示なし） |
| `lib/features/settings/settings_screen.dart` | `canBackup` | バックアップを Free で利用可能に |
| `lib/features/workout_detail/workout_detail_screen.dart` | `canAccessCharts` | 種目タップ→グラフへ Free で遷移可能に |
| `lib/features/exercise_list/exercise_list_screen.dart` | `canAccessCharts` | グラフ関連操作を Free で可能に |
| `lib/features/memo_search/memo_search_screen.dart` | `canAccessCharts` | 同上 |

**追加作業**: 上記画面では **コード削除は不要**。ゲートが `true` になるため、既存の `if (!gate.canXxx)` の分岐には入らなくなる。必要に応じて、後から「Pro 専用」のラベルやロックアイコン表示を削除するリファクタは可能。

---

### 2.3 履歴「30件」に合わせる文言・定数の更新

| ファイル | 変更内容 |
|----------|----------|
| `lib/features/paywall/models/paywall_reason.dart` | コメント「直近20件より古い」→「直近30件より古い」 |
| `lib/features/home/widgets/locked_session_tile.dart` | クラス/ファイルコメント「直近20件」→「直近30件」 |
| `lib/features/home/models/recent_workout_item.dart` | コメント「20件目以降」→「30件目以降」 |
| `lib/l10n/app_en.arb` | `paywallCompareLast20`: キーはそのままでも可。値 "Last 20" → **"Last 30"**（または新キー `paywallCompareLast30` を追加して差し替え） |
| `lib/l10n/app_ja.arb` | `paywallCompareLast20`: 値 "直近20件" → **"直近30件"**（同上） |
| `lib/l10n/app_localizations.dart` | `paywallCompareLast20` の doc コメントを "Last 30" / 直近30件 に合わせて更新 |
| `lib/l10n/app_localizations_en.dart` | `paywallCompareLast20` の return を **"Last 30"** に変更（または新 getter に移行） |
| `lib/l10n/app_localizations_ja.dart` | `paywallCompareLast20` → **"直近30件"**、`lockedSessionSubHint` の「直近20回」→**「直近30回」** |
| `lib/features/paywall/widgets/comparison_table.dart` | 表示文言は l10n の `paywallCompareLast20` を参照しているため、上記 l10n 変更で「直近30件」表示になる。必要なら「Free = 直近30件」である旨のコメントを追加 |

**オプション**: 「Last 20」という名前のまま中身を 30 にするか、`paywallCompareLast30` のようなキーにリネームするかはプロジェクト方針に合わせる。実装量を抑えるなら **値だけ 30 に変更** で十分。

---

### 2.4 Paywall モーダル・比較表のメッセージ調整（任意だが推奨）

- **比較表**（`lib/features/paywall/widgets/comparison_table.dart`）  
  - 現状: Free = 「直近20件」、Pro = 「無制限」／グラフ・テーマは Free「−」、Pro「✓」。  
  - 変更後: Free = 「直近30件」、Pro = 「無制限」。**グラフ・テーマは Free も「✓」** にすると、Pro の差別化が「履歴無制限」だけであることが伝わる。
- **Paywall モーダル**（`lib/features/paywall/widgets/paywall_modal.dart`）  
  - `PaywallReason.historyLocked` のときの説明文を「直近30件を超える過去の履歴は Pro で」のように揃える（l10n で対応可）。

---

## 3. 実装順序（推奨）

1. **feature_gate.dart**  
   - `freeHistoryLimit = 30` に変更。  
   - `canAccessCharts`, `canCustomizeTheme`, `canAccessDetailedStats`, `canBackup`, `canUseAdvancedSearch` をすべて「常に `true`」に変更。  
   - コメントを「直近30件」に更新。

2. **l10n（en/ja + arb + app_localizations.dart）**  
   - 「直近20件」「Last 20」「直近20回」を「直近30件」「Last 30」「直近30回」に統一。  
   - `lockedSessionSubHint` を 30 件前提の文言に変更。

3. **コメント・ドキュメント**  
   - `paywall_reason.dart`, `locked_session_tile.dart`, `recent_workout_item.dart` の「20」表記を「30」に変更。

4. **比較表・Paywall 文言（任意）**  
   - Free でグラフ・テーマを「✓」にする場合、比較表の Free 列の該当セルを「✓」に変更。  
   - 履歴ロック用 Paywall の説明を「30件」に合わせて調整。

5. **動作確認**  
   - Free のまま: テーマ変更・バックアップ・種目別グラフ・履歴一覧（直近30件）が問題なく使えること。  
   - 31件目以降の履歴タップで Paywall（historyLocked）が表示されること。  
   - Pro にすると全履歴が表示されること。

---

## 4. 変更しないもの（Pro 専用のまま）

- **履歴の「見える範囲」**  
  - `canAccessFullHistory`: Pro のみ `true`（変更なし）。  
  - `isSessionLocked(sessionIndex)`: `sessionIndex >= freeHistoryLimit`（定数だけ 30 に変更）。  
- **PaywallReason**  
  - `historyLocked` はそのまま使用。表示メッセージだけ 30 件に合わせる。  
- **entitlement_provider / IAP**  
  - Pro 購入・復元・ストレージの仕組みは変更しない。  
- **ホームの `recentWorkoutItemsProvider`**  
  - 既に `getCompletedSessions(limit: 30)` を使用しているため、`freeHistoryLimit` を 30 にすれば整合する。変更不要。

---

## 5. 実装チェックリスト（作業用）

実装時に実施した項目を記録するためのチェックリスト。

### 5.1 コア定義

- [x] `lib/utils/feature_gate.dart`: `freeHistoryLimit` を 20 → 30 に変更
- [x] `lib/utils/feature_gate.dart`: `canAccessCharts` を常に `true` に変更
- [x] `lib/utils/feature_gate.dart`: `canCustomizeTheme` を常に `true` に変更
- [x] `lib/utils/feature_gate.dart`: `canAccessDetailedStats` を常に `true` に変更
- [x] `lib/utils/feature_gate.dart`: `canBackup` を常に `true` に変更
- [x] `lib/utils/feature_gate.dart`: `canUseAdvancedSearch` を常に `true` に変更
- [x] `lib/utils/feature_gate.dart`: コメント「直近20件」→「直近30件」に更新

### 5.2 文言・l10n

- [x] `lib/l10n/app_en.arb`: `paywallCompareLast20` を "Last 30" に変更
- [x] `lib/l10n/app_en.arb`: `lockedSessionSubHint` を "latest 30 sessions" に変更
- [x] `lib/l10n/app_ja.arb`: `paywallCompareLast20` を「直近30件」に変更
- [x] `lib/l10n/app_ja.arb`: `lockedSessionSubHint` を「直近30回」に変更
- [x] `lib/l10n/app_localizations.dart`: doc コメントを 30 件に更新
- [x] `lib/l10n/app_localizations_en.dart`: `paywallCompareLast20` / `lockedSessionSubHint` を 30 に更新
- [x] `lib/l10n/app_localizations_ja.dart`: 同上

### 5.3 コメント・ドキュメント

- [x] `lib/features/paywall/models/paywall_reason.dart`: コメント「直近20件」→「直近30件」
- [x] `lib/features/home/widgets/locked_session_tile.dart`: コメント「直近20件」→「直近30件」
- [x] `lib/features/home/models/recent_workout_item.dart`: コメント「20件目」→「30件目」

### 5.4 比較表

- [x] `lib/features/paywall/widgets/comparison_table.dart`: Free 列のグラフを「−」→「✓」に変更
- [x] `lib/features/paywall/widgets/comparison_table.dart`: Free 列のテーマを「デフォルト」→「✓」に変更

---

## 6. チェックリスト（実装後・動作確認用）

以下は実機またはシミュレータで確認する項目。

- [ ] `FeatureGate.freeHistoryLimit` が 30 である（コード確認済みの場合はチェック可）
- [ ] Free のままテーマ設定・バックアップ・種目別グラフが利用可能である（Paywall が出ない）
- [ ] Free のまま履歴は直近 30 件まで表示・詳細表示できる
- [ ] 31 件目以降の履歴タップで Paywall（historyLocked）が表示される
- [ ] 設定・履歴・ホームの表示文言が「直近30」になっている
- [ ] Paywall 比較表で Free のグラフ・テーマが「✓」、履歴が「直近30件」になっている

---

## 7. 今後の広告配置について（参考）

本文の修正範囲外だが、収益化のため以下は「筋トレ記録の邪魔にならない箇所」の候補である。

- 設定画面（スクロール下部やセクション間）
- フラグ確認ページ（存在する場合）
- 履歴画面の下部
- Paywall を閉じた後や、履歴ロックタイル周辺（過度に目立たない位置）

広告実装時は、本計画で「Free で解放した機能」の利用フローを遮らないよう配置することが望ましい。
