# サウンドアセット

## タイマー終了アラーム音（現在はシステム音を使用）

タイマー終了時の「クラシックアラーム」「チャイム」「ビープ」は、**端末のシステム音**（iPhone の標準アラーム／Android のアラーム・通知音）で再生しています。  
アプリ内の WAV アセットは使用していません。

- **クラシックアラーム**: iOS `IosSounds.alarm` / Android `RingtoneManager.TYPE_ALARM`
- **チャイム**: iOS `IosSounds.chime` / Android デフォルト通知音
- **ビープ**: iOS `IosSounds.triTone` / Android デフォルト通知音

## 過去のアセット（参考）

`alarm.wav` / `chime.wav` / `beep.wav` は、以前のプリセット用でした。現在のタイマー再生では参照されていません。削除しても動作に影響はありません。
