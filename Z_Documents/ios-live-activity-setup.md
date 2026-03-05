# iOS タイマー Live Activity セットアップ手順

タイマー起動中にロック画面に経過／残り時間を表示するには、Xcode で **Widget Extension** を追加する必要があります。

## 前提

- Xcode で `ios/Runner.xcworkspace` を開いていること
- iOS 16.1 以上が対象

## 手順

### 1. Widget Extension ターゲットを追加

1. Xcode で **File → New → Target...**
2. **Widget Extension** を選択し **Next**
3. Product Name: **TimerWidgetExtension**（任意。以下はこの名前で記載）
4. **Include Live Activity** にチェックを入れる
5. **Finish** → 「Activate」でスキームを追加

### 2. 共有する Attributes を Extension から参照する

Runner 側の `TimerLiveActivityAttributes.swift` を **Widget Extension ターゲットのメンバーにも追加**します。

1. 左のプロジェクトナビゲーターで **Runner/TimerLiveActivityAttributes.swift** を選択
2. 右の **File Inspector** で **Target Membership** の **TimerWidgetExtension** にチェックを入れる

これで Runner と TimerWidgetExtension の両方で同じ `TimerLiveActivityAttributes` が使えます。

### 3. Extension の Live Activity UI を差し替える

Xcode が自動作成した Live Activity 用の Swift ファイルを、リポジトリの **ios/TimerWidgetExtension/TimerLiveActivity.swift** の内容で置き換えるか、そのファイルを TimerWidgetExtension ターゲットに追加してください。

- Extension の `Info.plist` で Live Activity の NSSupportsLiveActivities が有効になっていることを確認
- Extension のエントリポイント（`@main` の WidgetBundle）に `TimerLiveActivity()` を登録する

例（WidgetBundle）:

```swift
@main
struct TimerWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivity()
    }
}
```

### 4. ビルドと動作確認

1. 実機（シミュレータでは Live Activity が制限される場合あり）でアプリを実行
2. アプリ内で休憩タイマーを開始
3. 端末をロックし、ロック画面にタイマーの残り時間が表示されることを確認
4. タイマー停止・一時停止・終了でロック画面の表示が消えることを確認

## 既に実装済みのもの（Flutter / Runner）

- **Flutter**: `lib/services/timer_live_activity_service.dart` が Method Channel で `start` / `end` を呼び出し
- **Runner**: `AppDelegate.swift` の `didInitializeImplicitFlutterEngine` で Method Channel を登録（エンジン初期化時なので確実に登録される）
- **Runner**: `TimerLiveActivityBridge` が `Activity.request` / `Activity.end` を実行
- **Runner**: `TimerLiveActivityAttributes.swift` で終了時刻を保持する Attributes を定義
- **Info.plist**: `NSSupportsLiveActivities = YES` を追加済み

Extension を追加すると、ロック画面に「Rest Timer」と残り時間が表示されます。

---

## トラブルシューティング（実機で表示されない場合）

1. **Widget Extension を追加したか**
   - ロック画面に表示されるには、**必ず Xcode で Widget Extension ターゲットを追加**し、上記の手順 2・3 のとおり Attributes の共有と `TimerLiveActivity.swift` の追加を行ってください。Extension がないと `Activity.request()` は呼ばれても、表示するウィジェットがアプリに含まれないため何も出ません。

2. **設定で Live Activities が有効か**
   - **設定 → 画面のロックとパスコード**（または **Face ID とパスコード**）で、該当アプリの Live Activities が許可されているか確認してください。  
   - **設定 → [アプリ名]** で Live Activities のオン/オフがある場合はオンにしてください。

3. **iOS のバージョン**
   - Live Activity は **iOS 16.2 以上**で動作します。16.1 以下では開始されません。
