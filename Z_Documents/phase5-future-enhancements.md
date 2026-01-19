# Phase 5: 将来的な機能拡張・改善案

Phase 2の実装を進める中で発見した、将来的に実装すべき機能や改善点をまとめます。

---

## 目次

1. [UX改善](#1-ux改善)
2. [機能拡張](#2-機能拡張)
3. [パフォーマンス最適化](#3-パフォーマンス最適化)
4. [データ管理](#4-データ管理)
5. [開発者体験の向上](#5-開発者体験の向上)

---

## 1. UX改善

### 1.1 種目削除機能

**現状**: ExerciseCardWidgetにTODOコメントが残っている（exercise_card_widget.dart:55）

**提案**:
- 種目カードに削除ボタンを追加
- 削除前に確認ダイアログを表示
- 誤削除を防ぐためのUX設計

**実装箇所**: `lib/features/workout_input/widgets/exercise_card_widget.dart`

**優先度**: Medium

---

### 1.2 種目の並び替え機能

**現状**: 種目を追加した順序でしか表示できない

**提案**:
- ドラッグ&ドロップで種目の順序を変更可能にする
- ReorderableListViewを使用
- トレーニングルーティンに応じて種目順を調整できる

**実装箇所**: `lib/features/workout_input/workout_input_screen.dart`

**優先度**: Medium

---

### 1.3 セット間の自動タイマー起動

**現状**: ユーザーが手動でタイマーを起動する必要がある

**提案**:
- セット記録完了時に自動的にタイマーを起動
- 設定で自動起動のON/OFF切替を可能にする
- デフォルトのインターバル時間を設定可能にする

**実装箇所**:
- `lib/features/workout_input/widgets/set_row_widget.dart`
- `lib/providers/timer_provider.dart`

**優先度**: High（ユーザー体験の大幅な向上）

---

### 1.4 種目選択のお気に入り機能

**現状**: 種目選択時、全種目から毎回検索する必要がある

**提案**:
- よく使う種目を「お気に入り」として登録
- 種目選択モーダルの上部にお気に入りセクションを表示
- 素早いアクセスを実現

**実装箇所**:
- `lib/features/workout_input/widgets/exercise_selector_modal.dart`
- `lib/data/entities/exercise_master_entity.dart`（`is_favorite`フラグ追加）

**優先度**: High

---

### 1.5 スワイプジェスチャーでのセット削除

**現状**: 削除ボタンをタップしてからダイアログで確認

**提案**:
- セット行を左スワイプで削除
- スワイプ時に削除アイコンが表示される
- より直感的な操作

**実装箇所**: `lib/features/workout_input/widgets/set_row_widget.dart`

**優先度**: Medium

---

## 2. 機能拡張

### 2.1 部位別フィルタリング

**現状**: 種目検索は名前の部分一致のみ

**提案**:
- 種目選択モーダルに部位別タブを追加
- 胸、背中、脚などのカテゴリでフィルタリング
- 検索とフィルタの組み合わせも可能

**実装箇所**: `lib/features/workout_input/widgets/exercise_selector_modal.dart`

**優先度**: Medium

---

### 2.2 メモ機能

**現状**: 数値データのみ記録可能

**提案**:
- セッション単位でメモを記録
- 種目単位でメモを記録（フォームの注意点など）
- セット単位でメモを記録（体調、感覚など）

**データベース変更**:
```sql
-- workout_sessionsにmemoカラム追加
ALTER TABLE workout_sessions ADD COLUMN memo TEXT;

-- workout_exercisesにmemoカラム追加
ALTER TABLE workout_exercises ADD COLUMN memo TEXT;

-- set_recordsにmemoカラム追加
ALTER TABLE set_records ADD COLUMN memo TEXT;
```

**実装箇所**:
- `lib/features/workout_input/widgets/exercise_card_widget.dart`
- `lib/features/workout_detail/workout_detail_screen.dart`

**優先度**: Medium

---

### 2.3 スーパーセット・ドロップセット対応

**現状**: 通常のセットのみ記録可能

**提案**:
- スーパーセット（2種目を交互に実施）の記録
- ドロップセット（重量を落としながら連続実施）の記録
- セットタイプの選択肢を追加（通常 / スーパー / ドロップ）

**データベース変更**:
```sql
ALTER TABLE set_records ADD COLUMN set_type TEXT DEFAULT 'normal';
-- 'normal', 'superset', 'dropset'
```

**実装箇所**:
- `lib/features/workout_input/widgets/set_row_widget.dart`
- `lib/data/entities/set_record_entity.dart`

**優先度**: Low（アドバンスドユーザー向け）

---

### 2.4 1RM推定値の表示

**現状**: トップ重量のみ表示

**提案**:
- Epley式やBrzycki式で1RM（1 Rep Max）を推定
- 種目グラフに1RM推定値の推移を表示
- 成長実感をより明確にする

**実装箇所**: `lib/features/exercise_progress/exercise_progress_screen.dart`

**計算式**:
```dart
// Epley式: 1RM = weight * (1 + reps / 30)
double calculateOneRepMax(double weight, int reps) {
  if (reps == 1) return weight;
  return weight * (1 + reps / 30);
}
```

**優先度**: Medium

---

### 2.5 RPE（主観的運動強度）記録

**現状**: 重量と回数のみ記録

**提案**:
- RPE（Rate of Perceived Exertion）をセット毎に記録
- 1-10のスケールで主観的な強度を入力
- トレーニング強度の管理に活用

**データベース変更**:
```sql
ALTER TABLE set_records ADD COLUMN rpe INTEGER CHECK(rpe BETWEEN 1 AND 10);
```

**実装箇所**: `lib/features/workout_input/widgets/set_row_widget.dart`

**優先度**: Low（アドバンスドユーザー向け）

---

## 3. パフォーマンス最適化

### 3.1 画像・動画による種目ガイド

**現状**: 種目名のみ表示

**提案**:
- 種目マスタにサムネイル画像URLを追加
- 種目選択時にサムネイルを表示
- 詳細画面で動画ガイドを表示（YouTube埋め込み等）

**データベース変更**:
```sql
ALTER TABLE exercise_master ADD COLUMN thumbnail_url TEXT;
ALTER TABLE exercise_master ADD COLUMN video_url TEXT;
```

**実装箇所**:
- `lib/features/workout_input/widgets/exercise_selector_modal.dart`
- 新規：`lib/features/exercise_guide/exercise_guide_screen.dart`

**優先度**: Medium

---

### 3.2 オフライン対応の強化

**現状**: 基本的にオフライン動作するが、画像等は非対応

**提案**:
- 種目画像のローカルキャッシュ
- オフライン状態の明示的な表示
- オンライン復帰時の同期処理（将来的なクラウド対応のため）

**実装箇所**:
- `lib/services/cache_service.dart`（新規）
- `lib/widgets/offline_indicator.dart`（新規）

**優先度**: Low

---

## 4. データ管理

### 4.1 データエクスポート機能

**現状**: データをアプリ内でのみ保持

**提案**:
- CSV形式でのエクスポート
- JSON形式でのエクスポート
- 他のアプリへのデータ移行を可能にする

**実装箇所**:
- 新規：`lib/features/settings/data_export_screen.dart`
- `lib/services/export_service.dart`（新規）

**優先度**: High（ユーザーのデータ主権）

**エクスポート形式例（CSV）**:
```csv
Date,Exercise,Set,Weight,Reps,Unit
2025-01-15,Bench Press,1,60,10,kg
2025-01-15,Bench Press,2,60,10,kg
```

---

### 4.2 データバックアップ・リストア

**現状**: データ損失のリスクあり

**提案**:
- ローカルストレージへのバックアップ
- クラウドストレージへのバックアップ（Google Drive / iCloud）
- バックアップからの復元機能

**実装箇所**:
- 新規：`lib/features/settings/backup_restore_screen.dart`
- `lib/services/backup_service.dart`（新規）

**優先度**: High（データ保護）

---

### 4.3 データクリーンアップ

**現状**: 古いデータが蓄積し続ける

**提案**:
- 一定期間以前のデータを自動アーカイブ
- 不要なデータの一括削除機能
- ストレージ使用量の表示

**実装箇所**:
- 新規：`lib/features/settings/data_management_screen.dart`
- `lib/services/data_cleanup_service.dart`（新規）

**優先度**: Low

---

## 5. 開発者体験の向上

### 5.1 未使用importの自動削除

**現状**: 多数の未使用import警告が存在

**提案**:
- CIパイプラインで自動削除
- または開発時にlintルールで警告を強化

**実装箇所**: `.github/workflows/` または `analysis_options.yaml`

**優先度**: Low

---

### 5.2 ユニットテストの充実

**現状**: テストが不足している

**提案**:
- DAOのテストを追加
- Providerのテストを追加
- カバレッジ80%以上を目標

**実装箇所**: `test/` ディレクトリ全体

**優先度**: High（品質保証）

---

### 5.3 E2Eテストの導入

**現状**: 手動テストのみ

**提案**:
- integration_testを使用したE2Eテスト
- 主要フローのテスト自動化
  - 初回起動 → 種目追加 → セット記録 → 完了

**実装箇所**: `integration_test/` ディレクトリ

**優先度**: Medium

---

### 5.4 デザインシステムの統一

**現状**: カラー、フォントサイズ、余白がハードコード

**提案**:
- テーマシステムの統一
- カラーパレットの定義
- タイポグラフィの標準化
- スペーシングシステムの導入

**実装箇所**: `lib/theme/app_theme.dart`（新規）

**例**:
```dart
class AppTheme {
  static const primaryColor = Colors.blue;
  static const secondaryColor = Colors.orange;

  static const h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static const body = TextStyle(fontSize: 16);

  static const spacing4 = 4.0;
  static const spacing8 = 8.0;
  static const spacing16 = 16.0;
}
```

**優先度**: Medium

---

## 6. アクセシビリティ

### 6.1 音声フィードバック

**現状**: 視覚情報のみ

**提案**:
- タイマー終了時の音声通知
- セット完了時の効果音
- 設定でON/OFFを切替可能

**実装箇所**: `lib/services/audio_service.dart`（新規）

**優先度**: Medium

---

### 6.2 画面読み上げ対応

**現状**: スクリーンリーダー未対応

**提案**:
- Semanticsウィジェットの追加
- アクセシビリティラベルの設定
- VoiceOver / TalkBack対応

**実装箇所**: 全画面ウィジェット

**優先度**: Low

---

## 7. 将来的なビジネス機能

### 7.1 ソーシャル機能

**提案**:
- トレーニング記録のSNS共有
- 友達とのトレーニング比較
- コミュニティ機能

**優先度**: P2以降

---

### 7.2 AIによるアドバイス

**提案**:
- 過去のデータから最適な重量を推奨
- オーバートレーニングの警告
- プログレッション提案

**優先度**: P2以降

---

### 7.3 プレミアム機能

**提案**:
- 高度なグラフ分析
- カスタムプログラム作成
- パーソナルトレーナー連携

**優先度**: P2以降（マネタイズ後）

---

## まとめ

### 優先度別まとめ

#### High（早期実装推奨）
1. セット間の自動タイマー起動
2. 種目選択のお気に入り機能
3. データエクスポート機能
4. データバックアップ・リストア
5. ユニットテストの充実

#### Medium（価値あり）
1. 種目削除機能
2. 種目の並び替え機能
3. スワイプジェスチャーでのセット削除
4. 部位別フィルタリング
5. メモ機能
6. 1RM推定値の表示
7. 画像・動画による種目ガイド
8. E2Eテストの導入
9. デザインシステムの統一
10. 音声フィードバック

#### Low（余裕があれば）
1. スーパーセット・ドロップセット対応
2. RPE記録
3. オフライン対応の強化
4. データクリーンアップ
5. 未使用importの自動削除
6. 画面読み上げ対応

---

## 次のステップ

Phase 2完了後、以下の順序で進めることを推奨：

1. **Phase 3**: 振り返り体験の充実（カレンダー履歴）
2. **Phase 4**: 改善基盤の構築（Analytics）
3. **Phase 5-High**: 上記High優先度の機能から実装
4. **Phase 5-Medium**: 上記Medium優先度の機能から選択的に実装

ユーザーフィードバックを受けながら、優先度を調整していくことが重要です。
