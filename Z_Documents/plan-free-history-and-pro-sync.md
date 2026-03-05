# 計画：Free 履歴全面開放 & Pro サーバー同期

## 概要

1. **セッション数制限の廃止** — Free でも全履歴を閲覧可能にする。
2. **Pro 機能としてサーバー同期を追加** — デバイスを跨いだオンラインでのデータ保存（DB・ユーザー管理が必要）。

---

## 現状の Free / Pro の違い

| 項目 | Free | Pro |
|------|------|-----|
| 広告 | 表示 | 非表示 |
| 履歴閲覧 | 直近 30 セッションまで | 無制限 |

※ グラフ・テーマ・統計・バックアップは現状 Free/Pro 共通で利用可能。

---

# Phase 1: セッション数制限の廃止

## 1.1 方針

- Free でも**全履歴を閲覧可能**とする。
- 広告の表示/非表示は現状のまま（Free = 表示、Pro = 非表示）。
- 履歴に関する Paywall（「直近30件より古い履歴は Pro で」）を廃止する。

## 1.2 変更箇所一覧

| レイヤー | ファイル | 変更内容 |
|----------|---------|----------|
| 機能ゲート | `lib/utils/feature_gate.dart` | `freeHistoryLimit` を廃止。`canAccessFullHistory` を常に `true`。`isSessionLocked` を常に `false`。`getLockedCount` は常に 0、`getAccessibleCount` は `totalSessions` をそのまま返す。必要なら `isSessionLockedProvider` は削除または常に false を返すようにする。 |
| プロバイダー | `lib/providers/workout_session_provider.dart` | `recentWorkoutItemsProvider`: 取得件数はホーム表示用に 30 のままでも可。`isLocked` を常に `false` にする（またはロック分を表示しないなら全件取得に変更しても可）。 |
| 履歴画面 | `lib/features/history/history_screen.dart` | `_loadSessionIndexMap` を削除または空実装。`_isSessionLocked` を削除し、ロック判定をしない。ロック時 Paywall 表示を削除。日付タップ時は常に詳細表示。複数セッション選択時のロック表示・Paywall を削除。 |
| ホーム | `lib/features/home/home_screen.dart` | `recentWorkoutItemsProvider` の `item.isLocked` 分岐を削除。全件を通常の `_buildWorkoutHistoryCard` で表示（ロックタイルを出さない）。 |
| UI コンポーネント | `lib/features/home/widgets/locked_session_tile.dart` | 使用箇所がなくなるため削除するか、将来用に残す場合はコメントで「履歴制限廃止により未使用」と明記。 |
| Paywall | `lib/features/paywall/models/paywall_reason.dart` | `historyLocked` は削除するか、分析用に残す場合は Paywall 表示トリガーからは外す。 |
| Paywall UI | `lib/features/paywall/widgets/paywall_modal.dart` | `PaywallReason.historyLocked` の case を削除または「未使用」に。 |

## 1.3 多言語・文言

- 設定や Paywall の「Free = 直近30件 / Pro = 無制限」の比較表・文言を修正する。
- `paywallCompareLast20` / `paywallCompareUnlimited` / `lockedSessionHint` / `lockedSessionSubHint` など、履歴制限に紐づく文言は、履歴行を比較表から外すか、「Free も無制限」に合わせて更新する。
- 例: 比較表では「履歴」行を削除し、Pro のメリットは「広告非表示」「サーバー同期（Phase 2 以降）」に集約する。

## 1.4 実装順序（Phase 1）

1. `FeatureGate` の履歴制限関連を廃止（常に全履歴アクセス可・ロックなし）。
2. `recentWorkoutItemsProvider` の `isLocked` を常に false（またはロック表示をやめる）。
3. 履歴画面からロック判定・Paywall 表示を削除。
4. ホームから `LockedSessionTile` 使用を削除。
5. Paywall の `historyLocked` を廃止し、比較表・文言を更新。
6. 未使用になった `LockedSessionTile` と関連 l10n の整理。

---

# Phase 2: Pro サーバー同期

## 2.1 目標

- **Pro 限定**: サーバーとデータを同期し、複数デバイスで同じユーザーのデータを参照・編集できるようにする。
- **前提**: 無料で使える DB をまず用意し、ユーザー識別のための認証（ユーザー情報）を導入する。

## 2.2 必要な要素

| 要素 | 内容 |
|------|------|
| **バックエンド DB** | クラウド上の DB（例: Supabase PostgreSQL、Firebase Firestore、または VPS 上の PostgreSQL など）。最初は無料枠で運用。 |
| **ユーザー管理** | 「どのデータが誰のものか」を識別するため、ユーザー ID（および認証）が必要。 |
| **認証** | メール/パスワード、Apple Sign-In、Google Sign-In のいずれか（または複数）を検討。 |
| **同期対象データ** | 現行ローカル DB と同等: `workout_sessions`, `workout_exercises`, `set_records`, `exercise_master`, `body_weight_records`。設定（テーマ・言語など）は必要に応じて同期対象に含める。 |
| **同期方式** | 初回: ログイン後にサーバーから一括取得 or ローカルをアップロード。以降: 差分同期（last_updated_at ベース）または定期的フル比較のいずれか。 |
| **競合方針** | 同一レコードの複数デバイス編集は、last-write-wins や `updated_at` の新しい方を採用するなど、方針を 1 つに固定する。 |

## 2.3 アーキテクチャ案（レイヤー分離）

| レイヤー | 役割 | 例（ファイル・モジュール） |
|----------|------|----------------------------|
| **認証** | ログイン・ログアウト・トークン保持・ユーザー ID 取得 | `AuthService`, `AuthRepository`（または Supabase Auth 等の SDK をラップ） |
| **同期 API クライント** | サーバーとの HTTP/API 通信（データ取得・送信） | `SyncApiClient` または BaaS の REST/SDK 利用 |
| **同期サービス** | 同期トリガー・差分検出・競合解決・ローカル DB との読み書き | `SyncService`（Repository を利用） |
| **ローカル Repository** | 既存 DAO を利用したローカル DB の読み書き | 既存の DAO / Repository |
| **リモート用モデル** | サーバーとのやり取り用 DTO（必要なら） | `lib/data/models/sync/` など |
| **機能ゲート** | Pro のみ同期可能にする | `FeatureGate.canSync => isPro` を追加 |

## 2.4 データ設計のポイント

- **ユーザーとデータの紐付け**: サーバー側の各テーブルに `user_id`（または `account_id`）を必須で持たせる。
- **ID の扱い**: ローカルは SQLite の AUTOINCREMENT、サーバーは UUID や ULID を推奨。同期時は「ローカル ID ↔ サーバー ID」のマッピングテーブルを用意するか、サーバー側を正とするなど方針を決める。
- **初回同期**: 既存ローカルデータを Pro ユーザーが初めてログインしたときにアップロードするか、サーバーを正として空から始めるか、を決める。
- **オフライン**: オフライン中はローカルのみ更新し、オンライン復帰時にサーバーへ push / サーバーから pull する方針を決める。

## 2.5 技術選定の候補（最初は無料で）

| 選択肢 | DB・バックエンド | 認証 | 備考 |
|--------|------------------|------|------|
| **Supabase** | PostgreSQL（無料枠あり） | 組み込み Auth（メール、Apple、Google 等） | Flutter 用 SDK あり。REST/Realtime で同期実装可能。 |
| **Firebase** | Firestore（無料枠あり） | Firebase Auth | Flutter と相性が良い。ドキュメント指向。SQL ではないため既存スキーマをそのまま移す場合は設計の書き換えが必要。 |
| **自前バックエンド** | VPS 上の PostgreSQL 等 | 自前 or Auth0/Clerk 等 | 柔軟だが構築・運用コストが大きい。 |

推奨: **Supabase** を第一候補とする（PostgreSQL でスキーマをローカルに近づけやすく、認証も含めて無料枠で始めやすいため）。

## 2.6 実装順序（Phase 2）

1. **設計の確定**  
   - 同期対象テーブル・カラム一覧  
   - サーバー側スキーマ（`user_id` 付き）  
   - 初回同期フロー（新規ログイン vs 既存データアップロード）  
   - 競合方針（last-write-wins 等）

2. **認証の組み込み**  
   - 認証プロバイダー（Supabase Auth 等）の導入  
   - ログイン/ログアウト画面  
   - トークン・ユーザー ID の保持（セキュアストレージ）

3. **バックエンドの準備**  
   - Supabase プロジェクト作成  
   - テーブル作成（`user_id` 付き）  
   - RLS（Row Level Security）で `user_id` によるアクセス制限

4. **同期レイヤーの実装**  
   - Sync API クライント（取得・送信）  
   - SyncService: ローカル DB との突き合わせ・差分適用・競合処理  
   - ローカルに「最終同期日時」「サーバー ID マッピング」を保存するテーブル or カラムの追加

5. **UI の接続**  
   - 設定に「Pro: 同期をオンにする」とアカウント表示を追加  
   - 同期状態表示（最終同期時刻、エラー時メッセージ）  
   - FeatureGate: `canSync => isPro` を追加し、Pro のみ同期可能に

6. **テスト・段階リリース**  
   - 単一デバイスでの同期 → 複数デバイスでの同期  
   - オフライン → オンライン復帰時の挙動確認

---

## 2.7 拡張・スケーラビリティ

- **TODO**: 同期キュー（オフライン時の変更をキューに積み、オンライン時に送信）。  
- **TODO**: サーバー側の論理削除（soft delete）とクライアント側の削除反映。  
- **TODO**: 無料枠を超えた場合の DB 移行・課金プラン検討。

---

## まとめ

| Phase | 内容 | 主な成果 |
|-------|------|----------|
| **1** | セッション数制限の廃止 | Free でも全履歴閲覧可能。履歴ロック・Paywall を削除。 |
| **2** | Pro サーバー同期 | ユーザー認証 + クラウド DB でデバイスを跨いだデータ利用が可能。 |

Phase 1 は既存の FeatureGate・履歴/ホーム/Paywall の修正のみで完結する。Phase 2 は新規の認証・バックエンド・同期ロジックの追加となるため、まず Phase 1 を実装し、その後に Phase 2 の詳細設計（スキーマ・API・フロー）を固めてから実装することを推奨する。
