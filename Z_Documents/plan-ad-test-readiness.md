# 広告テスト可能状態の実装計画

審査通過後は **ID の差し替えだけ**で本番広告に切り替えられるように、**今のうちにテスト広告が表示できる状態**まで実装するための計画です。

---

## 1. ゴール

| 状態 | 内容 |
|------|------|
| **いま作る状態** | テスト用アプリID・広告ユニットIDのみで、設定・履歴画面にBannerテスト広告が表示される。Proユーザーでは非表示。 |
| **審査通過後にやること** | AdMobで取得した**本番アプリID**と**本番Banner広告ユニットID**を、3箇所（ad_config + AndroidManifest + Info.plist）に差し替えるだけ。 |

**今は AdMob にアプリを追加していなくても、公式のテスト用IDを使えば広告表示の動作確認ができます。**

---

## 2. 使用するID（すべてテスト用・公式）

審査通過前は次の**テスト用IDのみ**を使用します。本番IDは一切不要です。

| 用途 | Android | iOS |
|------|---------|-----|
| アプリ ID | `ca-app-pub-3940256099942544~3347511713` | `ca-app-pub-3940256099942544~1458002511` |
| Banner 広告ユニット ID | `ca-app-pub-3940256099942544/9214589741` | `ca-app-pub-3940256099942544/2435281174` |

---

## 3. 実装タスク一覧（テスト可能状態まで）

### Phase A: パッケージとネイティブ設定（テストIDでOK）

| # | タスク | ファイル | 内容 |
|---|--------|----------|------|
| A1 | google_mobile_ads 追加 | `pubspec.yaml` | `flutter pub add google_mobile_ads` |
| A2 | Android にアプリID | `android/app/src/main/AndroidManifest.xml` | `<application>` 内に `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/>` を追加（テスト用） |
| A3 | iOS にアプリID | `ios/Runner/Info.plist` | `<dict>` 内に `<key>GADApplicationIdentifier</key>` と `<string>ca-app-pub-3940256099942544~1458002511</string>` を追加（テスト用） |
| A4 | iOS pod | `ios/` | 必要に応じて `platform :ios, '12.0'` 確認後 `pod install` |

### Phase B: 初期化と共通コード

| # | タスク | ファイル | 内容 |
|---|--------|----------|------|
| B1 | SDK 初期化 | `lib/main.dart` | `WidgetsFlutterBinding.ensureInitialized()` と `await MobileAds.instance.initialize()` を `main()` 内で実行（`runApp` の前） |
| B2 | 広告ID管理 | `lib/config/ad_config.dart`（新規） | テスト用IDを定数で定義。本番用はプレースホルダ（`pub-xxx/yyy`）のまま。`bannerAdUnitIdAndroid` / `bannerAdUnitIdIOS` の getter で、**いまは常にテストIDを返す**（または `kDebugMode` のときテストID）。本番化時はここを本番IDに差し替え。 |
| B3 | Banner ウィジェット | `lib/features/ads/widgets/banner_ad_widget.dart`（新規） | Free のときだけ Banner を load → `AdWidget` で表示。Pro のときは `SizedBox.shrink()`。`entitlementProvider` を watch。dispose を忘れずに。 |

### Phase C: 画面への配置

| # | タスク | ファイル | 内容 |
|---|--------|----------|------|
| C1 | 設定画面にBanner | `lib/features/settings/settings_screen.dart` | 保存ボタンの上（`Expanded` の下、`Container` の前）に `BannerAdWidget()` を 1 つ追加。Column の子として。 |
| C2 | 履歴画面にBanner | `lib/features/history/history_screen.dart` | 画面下部（カレンダー・リストの下、または固定で下）に `BannerAdWidget()` を 1 つ追加。 |

---

## 4. 実装の順序（推奨）

1. **A1** → `flutter pub get`
2. **A2, A3, A4** → ネイティブ設定（すべてテストIDでよい）
3. **B1** → 起動してクラッシュしないことを確認
4. **B2** → `ad_config.dart` 作成（テストIDのみ使用する実装）
5. **B3** → `BannerAdWidget` 作成（Pro のとき非表示）
6. **C1** → 設定画面でテスト広告表示を確認
7. **C2** → 履歴画面でテスト広告表示を確認

---

## 5. 本番化時チェックリスト（審査通過後・ID差し替えのみ）

以下は **AdMob でアプリが確認済みになり、本番のアプリID・Banner広告ユニットIDを取得したあと** に実施します。

| # | 作業 | 場所 |
|---|------|------|
| 1 | 本番アプリID（Android）に差し替え | `android/app/src/main/AndroidManifest.xml` の `meta-data` の `android:value`（`ca-app-pub-xxx~yyy`） |
| 2 | 本番アプリID（iOS）に差し替え | `ios/Runner/Info.plist` の `GADApplicationIdentifier` の `<string>` の中身 |
| 3 | 本番Banner広告ユニットIDに差し替え | `lib/config/ad_config.dart` の `prodAppIdAndroid` / `prodAppIdIOS`（任意。ネイティブと揃えるならコメント用）と **`prodBannerUnitIdAndroid`** / **`prodBannerUnitIdIOS`** の値を AdMob で取得したIDに変更 |

**注意**: 本番IDで実機テストするとき、自分で広告を何度もクリックしないこと（ポリシー違反のリスクがあります）。

---

## 実装済みファイル一覧

- `pubspec.yaml` … `google_mobile_ads` 追加
- `android/app/src/main/AndroidManifest.xml` … テスト用アプリIDを記載（本番化時に差し替え）
- `ios/Runner/Info.plist` … テスト用アプリIDを記載（本番化時に差し替え）
- `lib/main.dart` … `MobileAds.instance.initialize()` を呼び出し
- `lib/config/ad_config.dart` … テスト/本番の広告ユニットID（本番化時に `prod*` を差し替え）
- `lib/features/ads/widgets/banner_ad_widget.dart` … Free 時のみ Banner 表示
- `lib/features/settings/settings_screen.dart` … 保存ボタン上に `BannerAdWidget` を配置
- `lib/features/history/history_screen.dart` … 画面下部に `BannerAdWidget` を配置

---

## 6. ad_config の設計方針（テスト可能状態）

- **今**: `bannerAdUnitIdAndroid` / `bannerAdUnitIdIOS` は **常にテスト用IDを返す**（`kDebugMode` でなくてもテストIDでよい。審査通過前は本番IDがないため）。
- **審査通過後**: `prodBannerUnitIdAndroid` / `prodBannerUnitIdIOS` に本番IDを書き、`kDebugMode ? テストID : 本番ID` のように切り替える。または、リリースビルド用のフラグで本番IDに切り替える。

これにより「今はテストIDだけでテスト表示」「あとからIDだけ差し替えて本番」がスムーズになります。

---

## 7. ファイル構成（新規作成するもの）

```
lib/
├── config/
│   └── ad_config.dart          # 広告ユニットID・アプリIDはここで参照（本番化時はここを編集）
└── features/
    └── ads/
        └── widgets/
            └── banner_ad_widget.dart   # Free 時のみ表示する Banner
```

- **ad_config.dart**: テスト用Banner広告ユニットIDを返す。本番用はプレースホルダで定義しておき、審査通過後に値を入れる。
- **banner_ad_widget.dart**: `entitlementProvider` を watch し、Pro なら何も表示しない。Free なら `BannerAd` を load して `AdWidget` で表示。Platform で Android/iOS を判定して `AdConfig` から適切な広告ユニットIDを取得。

---

## 8. 動作確認のポイント（テスト可能状態）

- [ ] アプリ起動時にクラッシュしない（Android / iOS 両方）
- [ ] 設定画面を開くと、画面下部（保存ボタン上）にテストBannerが表示される（Free ユーザー時）
- [ ] 履歴画面を開くと、テストBannerが表示される（Free ユーザー時）
- [ ] 開発者オプションで Pro に切り替えた場合は、上記画面でBannerが表示されない
- [ ] テスト広告である旨のラベルが公式テスト広告で表示される（「Test ad」など）

ここまでできていれば、**審査通過後は ID 指定の差し替えだけで本番広告に切り替え可能**です。
