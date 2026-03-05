# 広告による収益化 — 実装計画

## 1. 戦略の方針

### 1.1 原則

- **筋トレ記録フローを邪魔しない**  
  記録入力・タイマー・セット追加など、トレーニング中の操作が発生する画面では広告を表示しない。
- **設定・履歴確認など「振り返り」系の画面に限定**  
  ユーザーが記録に集中していない場面でのみ広告を表示する。
- **Pro ユーザーには広告を出さない**  
  課金ユーザーは広告非表示とする（既存の `entitlementProvider` で判定）。

### 1.2 広告を表示する画面（許可）

| 画面 | 配置イメージ | 優先度 |
|------|--------------|--------|
| **設定** (Settings) | 画面下部（保存ボタン上）、またはセクション間 | 高 |
| **履歴** (History) | カレンダー下・リスト上、または画面最下部 | 高 |
| **種目一覧** (Exercise List) | リスト下部 | 中 |
| **メモ検索** (Memo Search) | 検索結果エリアの下部 | 中 |
| **チュートリアル完了後** | 完了画面内の控えめな位置（任意） | 低 |

### 1.3 広告を表示しない画面（禁止）

| 画面 | 理由 |
|------|------|
| **ホーム** (Home) | 記録開始への導線が主役。広告で注意を奪わない。 |
| **トレーニング入力** (Workout Input) | 記録の核心。絶対に表示しない。 |
| **ワークアウト詳細** (Workout Detail) | その日の記録確認・編集に集中させる。 |
| **種目別グラフ** (Exercise Progress) | 成長の振り返り中は邪魔にしない。 |
| **初期設定** (Initial Setup) | 初回体験をスムーズに。 |
| **Paywall モーダル** | 課金導線を妨げない。 |

---

## 2. 広告ネットワーク・フォーマット選定

### 2.1 ネットワーク

- **Google AdMob** を採用する。
  - Flutter 公式プラグイン `google_mobile_ads` が利用可能。
  - iOS / Android 両対応。
  - テスト用広告ユニットIDが公式で提供されている。

### 2.2 フォーマット

| 種別 | 用途 | 本アプリでの使用 |
|------|------|------------------|
| **Banner（アンカード適応）** | 画面の上下に固定表示 | **メイン**。設定・履歴などで 1 本ずつ。 |
| **インライン Banner** | スクロール内に埋め込み | 設定の長いスクロール内などで検討可。 |
| **インタースティシャル** | 全画面の間質広告 | **原則使わない**。記録フローを分断するため。 |
| **ネイティブ** | デザインを組み込んだ広告 | 余裕があれば履歴・設定の「1セクション」として検討。 |

まずは **Banner（アンカード適応）** のみで実装し、配置と収益を見てからインラインやネイティブを検討するのが安全。

---

## 3. app-ads.txt について（アプリ登録前に必須）

### 3.1 エラー「app-ads.txt の問題を確認して修正してから」が出る理由

AdMob でアプリを追加すると、**アプリの確認を完了するために app-ads.txt の検証**が行われます。  
**「先にアプリ内で広告を実装してから AdMob に登録する」順序にしても、このエラーは解消しません。**  
app-ads.txt は「開発者サイトのドメインで、正当な広告販売者であることを示すファイル」であり、**アプリの実装有無とは別の要件**です。

### 3.2 やるべきこと（結論）

1. **開発者用の Web サイトを用意する**  
   - 自分でドメインを持っているサイト、または  
   - **Firebase Hosting** や **GitHub Pages** などで「1 ページ＋1 ファイル」だけでも可。
2. **そのサイトのルートに app-ads.txt を置く**  
   - URL が `https://あなたのドメイン.com/app-ads.txt` でアクセスできるようにする。
3. **ストアの「開発者ウェブサイト」をその URL に合わせる**  
   - Google Play: ストア掲載情報の「連絡先のウェブサイト」  
   - App Store: App 情報の「Marketing URL」など  
   → AdMob はこの URL のドメインをたどって app-ads.txt を取得します。
4. **AdMob で app-ads.txt の再確認をリクエスト**し、検証完了を待つ（数日かかることがあります）。

### 3.3 app-ads.txt の内容（形式）

- ファイル名は **`app-ads.txt`**（拡張子なし）。
- 1 行目に Google 用の行を書く（**Publisher ID は AdMob の「設定」で確認**）:

```
google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
```

- `pub-XXXXXXXXXXXXXXXX` を **あなたの AdMob パブリッシャー ID** に置き換える。
- パブリッシャー ID の確認: AdMob コンソール → **設定（歯車）** → **アカウント情報** などに表示されている `pub-` で始まる ID。
- 改行や余計な空白を入れず、上記 1 行だけでも可（他社広告を使う場合は追加行を記載）。

### 3.4 サイトがない場合の例（Firebase Hosting）

1. [Firebase Console](https://console.firebase.google.com/) でプロジェクトを作成。
2. **Hosting** を有効化し、`app-ads.txt` をプロジェクトの `public` フォルダに置く。
3. `firebase deploy` でデプロイ。
4. 表示される URL が `https://あなたのプロジェクト.web.app/app-ads.txt` になるよう、`public` 直下に配置。
5. Play / App Store の「開発者ウェブサイト」に `https://あなたのプロジェクト.web.app` を設定。
6. AdMob の「app-ads.txt」ページから「更新を確認」などで再クロールをリクエスト。

### 3.5 推奨する作業順序

| 順序 | 作業 |
|------|------|
| 1 | AdMob アカウント作成。パブリッシャー ID を控える。 |
| 2 | **開発者サイトを用意し、ルートに app-ads.txt を設置。** |
| 3 | Play Store / App Store の開発者ウェブサイトをそのドメインに設定（未公開アプリの場合は、公開前でも「予定のURL」で可）。 |
| 4 | AdMob で「アプリを追加」し、app-ads.txt の再確認をリクエスト → **アプリの確認が完了するまで待つ。** |
| 5 | 確認完了後、広告ユニットを作成し、アプリ内に広告実装 → テスト → リリース。 |

**まとめ**: アプリのバージョンアップや「先に広告実装」では app-ads.txt エラーは解消しません。**先に app-ads.txt を設置し、AdMob のアプリ確認を完了させてから**、アプリ内の広告実装に進むのが確実です。

### 3.6 App Store（App Store Connect）で開発者URLを設定する詳細手順

AdMob は、App Store に登録されているアプリについて、**そのアプリに紐づく「マーケティングURL」（Marketing URL）のドメイン**をたどって app-ads.txt を取得します。  
以下は、その **マーケティングURL（開発者・アプリ用ウェブサイトのURL）を App Store Connect で設定する手順**です。

#### 前提

- Apple Developer プログラムに登録済みであること。
- App Store Connect で対象のアプリが作成済みであること（まだ審査提出前でも可）。
- 設定するURLは、**app-ads.txt を置いたサイトのルート**（例: `https://yourname.github.io/your-repo` や `https://your-project.web.app`）。末尾に `/app-ads.txt` は付けない。

---

#### 手順 1: App Store Connect にログイン

1. ブラウザで [App Store Connect](https://appstoreconnect.apple.com/) を開く。
2. Apple ID でサインインする。

---

#### 手順 2: 対象アプリを開く

1. トップ画面で **「マイアプリ」**（英語: **My Apps**）をクリックする。
2. 一覧から **対象のアプリ**をクリックする。  
   （アプリがまだない場合は「＋」などから新規アプリを追加したうえで、そのアプリを選択する。）
3. アプリの詳細画面が開き、左サイドバーに **「配信」** や **「一般」** などが表示される。

---

#### 手順 3: アプリ情報（一般）を開く

1. 左サイドバーで **「一般」**（英語: **General**）をクリックする。
2. その中にある **「アプリ情報」**（英語: **App Information**）をクリックする。  
   ※ 画面上では「アプリ」セクション内の「一般」→「アプリ情報」という階層になっている場合があります。
3. 「アプリ情報」の編集画面が表示される。

---

#### 手順 4: マーケティングURL（Marketing URL）を入力

1. 「アプリ情報」画面内を下にスクロールし、**「マーケティングURL」**（英語: **Marketing URL**）の入力欄を探す。  
   - 同じあたりに **「サポートURL」**（Support URL）もある。サポートURLは審査で参照されることがあるため、あれば入力推奨（プライバシーポリシーや問い合わせページのURLなど）。
2. **マーケティングURL** の欄に、app-ads.txt を置いたサイトの**ルートURL**を入力する。  
   - 例（GitHub Pages で `docs` から公開している場合）:  
     `https://あなたのユーザー名.github.io/リポジトリ名`  
   - 例（Firebase Hosting）:  
     `https://あなたのプロジェクトID.web.app`  
   - **注意**: `https://` から始まる完全なURLにすること。末尾のスラッシュ（`/`）はあってもなくてもよい。
3. 入力後、画面右上または下部の **「保存」**（Save）をクリックする。

---

#### 手順 5: バージョンごとのストア掲載情報でも確認（任意）

- アプリの**特定バージョン**のストア掲載情報（「App Store」タブ内のバージョン情報）にも、**サポートURL** や **マーケティングURL** の入力欄がある場合があります。
- 画面の仕様により、「一般」→「アプリ情報」で設定した内容がバージョン情報と連動していることも、別々に持っていることもあります。
- **「一般」→「アプリ情報」でマーケティングURLを設定しておけば、AdMob が参照する「アプリに紐づくURL」として通常は利用されます。**  
  バージョン情報の方にも同じURLが表示されている場合は、そちらも同じ値にしておくとよいです。

---

#### 手順 6: 反映の確認

- App Store Connect 上での保存後、**最大24時間**ほどかけてストア側に反映されることがあります。
- AdMob の app-ads.txt 検証は、**App Store に公開されている（または提出情報として登録されている）アプリのマーケティングURL** をクロールするため、**保存してしばらく待ってから** AdMob で「app-ads.txt の更新を確認」を実行するとよいです。

---

#### まとめ（App Store 側でやること）

| 項目 | 内容 |
|------|------|
| 設定するURL | app-ads.txt を置いたサイトの**ルート**（例: `https://xxx.github.io/yyy`）。 |
| 設定場所 | App Store Connect → マイアプリ → [アプリ選択] → **一般** → **アプリ情報** → **マーケティングURL**。 |
| 入力形式 | `https://` から始まる完全なURL。 |
| 保存 | 「保存」をクリック。反映に時間がかかることがある。 |

このマーケティングURLのドメイン配下に `https://そのドメイン/app-ads.txt` が存在し、内容が正しければ、AdMob のアプリ確認が完了しやすくなります。

---

## 4. 広告の取得から表示までの流れ（全体）

```
[0] app-ads.txt を開発者サイトのルートに設置 → AdMob でアプリ確認を完了
        ↓
[1] AdMob アカウント作成
        ↓
[2] アプリ登録（Android / iOS それぞれ）※ app-ads.txt 検証済みであること
        ↓
[3] 広告ユニット作成（Banner 用の広告ユニットIDを取得）
        ↓
[4] アプリ側: google_mobile_ads 導入・ネイティブ設定
        ↓
[5] アプリ起動時に MobileAds.instance.initialize()
        ↓
[6] 各画面で AdWidget + BannerAd を配置（Free ユーザーのみ）
        ↓
[7] テスト用IDで動作確認 → 本番IDに差し替えてリリース
```

---

## 5. Flutter: google_mobile_ads パッケージで実装する手順（最小・最新）

以下は **google_mobile_ads** を使った、最もシンプルで効率の良い実装手順です。公式 Quick start および Banner ガイド（2025年時点）に沿っています。

### 5.1 パッケージの追加

```bash
flutter pub add google_mobile_ads
```

`pubspec.yaml` に `google_mobile_ads` が追加されます。`flutter pub get` を実行。

---

### 5.2 Android の設定

**ファイル**: `android/app/src/main/AndroidManifest.xml`

`<application>` タグの**中**に、次の `<meta-data>` を 1 つ追加する。  
`android:value` には AdMob で取得した**アプリ ID**（`ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` 形式）を入れる。  
開発中はテスト用アプリ ID を使うことも可能（本番公開前に本番 ID に差し替える）。

```xml
<manifest>
  <application>
    <!-- AdMob アプリ ID（本番: AdMob コンソールで取得した値に差し替え） -->
    <meta-data
        android:name="com.google.android.gms.ads.APPLICATION_ID"
        android:value="ca-app-pub-3940256099942544~3347511713"/>
    <!-- 既存の他の要素 -->
  </application>
</manifest>
```

- 上記 `ca-app-pub-3940256099942544~3347511713` は**テスト用アプリ ID**の例。本番では自分のアプリ ID に変更する。
- この値を入れ忘れると**起動時にクラッシュ**するため必須。

---

### 5.3 iOS の設定

**ファイル**: `ios/Runner/Info.plist`

`<dict>` の直下に、次のキーと文字列を 1 組追加する。  
値には AdMob で取得した**アプリ ID**（`ca-app-pub-################~##########` 形式）を入れる。

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

- 上記は**テスト用アプリ ID**の例。本番では自分のアプリ ID に変更する。

**iOS の追加要件**（必要な場合）:

- `ios/Podfile` で `platform :ios, '12.0'` 以上を指定していること。
- 変更後は `cd ios && pod install` を実行。

---

### 5.4 SDK の初期化（アプリ起動時）

広告を読み込む**前**に、必ず 1 回だけ `MobileAds.instance.initialize()` を呼ぶ。  
できるだけ早いタイミング（例: `main()` 内で `runApp` の前、または `MyApp` の `initState`）で実行する。

**例: main.dart の main() で行う場合**

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}
```

**例: MyApp の initState で行う場合**

```dart
@override
void initState() {
  super.initState();
  MobileAds.instance.initialize();
}
```

初期化は 30 秒でタイムアウトするため、広告表示までに多少遅れても問題ない場合は `await` なしで fire-and-forget でも可。

---

### 5.5 広告ユニット ID の管理（テスト / 本番の切替）

1 箇所で ID を管理すると本番リリース時の差し替えが楽。  
`kDebugMode` のときはテスト用 ID、それ以外は本番 ID にする例。

```dart
// lib/config/ad_config.dart（例）
import 'package:flutter/foundation.dart';

class AdConfig {
  static const String testAppIdAndroid = 'ca-app-pub-3940256099942544~3347511713';
  static const String testAppIdIOS = 'ca-app-pub-3940256099942544~1458002511';
  static const String testBannerUnitIdAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const String testBannerUnitIdIOS = 'ca-app-pub-3940256099942544/2435281174';

  /// 本番用（AdMob で取得した値に差し替え）
  static const String prodBannerUnitIdAndroid = 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
  static const String prodBannerUnitIdIOS = 'ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz';

  static String get bannerAdUnitIdAndroid =>
      kDebugMode ? testBannerUnitIdAndroid : prodBannerUnitIdAndroid;
  static String get bannerAdUnitIdIOS =>
      kDebugMode ? testBannerUnitIdIOS : prodBannerUnitIdIOS;
}
```

Android / iOS の判定は `defaultTargetPlatform` または `dart.io` の `Platform.isAndroid` 等で行う。

---

### 5.6 Banner 広告の表示（アンカード適応バナー）

手順の流れ:

1. **AdSize の取得**  
   `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width)` で、端末幅に合わせたサイズを取得（`width` は `MediaQuery.sizeOf(context).width.truncate()` など）。
2. **BannerAd の作成と load**  
   `BannerAd(adUnitId, request: AdRequest(), size, listener: BannerAdListener(...)).load()`。
3. **表示**  
   load が成功したら `AdWidget(ad: bannerAd)` を、`SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble())` でラップして配置。
4. **dispose**  
   ウィジェットがツリーから外れたとき、または `onAdFailedToLoad` 内で `ad.dispose()` を呼ぶ。

**最小コード例（StatefulWidget 内）**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:your_app/config/ad_config.dart';

BannerAd? _bannerAd;

Future<void> _loadBannerAd(BuildContext context) async {
  final width = MediaQuery.sizeOf(context).width.truncate();
  final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
  if (size == null || !mounted) return;

  final adUnitId = Platform.isAndroid
      ? AdConfig.testBannerUnitIdAndroid  // 本番: AdConfig.bannerAdUnitIdAndroid
      : AdConfig.testBannerUnitIdIOS;

  _bannerAd = BannerAd(
    adUnitId: adUnitId,
    request: const AdRequest(),
    size: size,
    listener: BannerAdListener(
      onAdLoaded: (ad) {
        if (mounted) setState(() {});
      },
      onAdFailedToLoad: (ad, err) {
        debugPrint('Banner failed to load: $err');
        ad.dispose();
      },
    ),
  )..load();
}

@override
void dispose() {
  _bannerAd?.dispose();
  super.dispose();
}

// build 内で表示
Widget build(BuildContext context) {
  return Column(
    children: [
      // 既存のコンテンツ
      if (_bannerAd != null)
        SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
    ],
  );
}
```

- **Pro ユーザーには表示しない**: `ref.watch(entitlementProvider).isPro == true` のときは `_loadBannerAd` を呼ばず、Banner 用ウィジェットを `SizedBox.shrink()` にする。
- **テスト用広告ユニット ID**（Banner）:  
  - Android: `ca-app-pub-3940256099942544/9214589741`  
  - iOS: `ca-app-pub-3940256099942544/2435281174`  
  本番では AdMob で作成した Banner の広告ユニット ID に差し替える。

---

### 5.7 公式テスト用 ID 一覧（開発時のみ使用）

| 用途 | Android | iOS |
|------|---------|-----|
| アプリ ID | `ca-app-pub-3940256099942544~3347511713` | `ca-app-pub-3940256099942544~1458002511` |
| Banner 広告ユニット ID | `ca-app-pub-3940256099942544/9214589741` | `ca-app-pub-3940256099942544/2435281174` |

- 本番公開前に、必ず本番のアプリ ID・広告ユニット ID に差し替える。  
- 本番 ID で自分でクリックしたり過度に表示テストすると、AdMob ポリシー違反になる可能性がある。

---

### 5.8 手順のまとめ（チェックリスト）

1. `flutter pub add google_mobile_ads` を実行
2. **Android**: `AndroidManifest.xml` の `<application>` 内に `APPLICATION_ID` の `<meta-data>` を追加
3. **iOS**: `Info.plist` に `GADApplicationIdentifier` を追加 → 必要なら `pod install`
4. `main.dart`（または MyApp）で `MobileAds.instance.initialize()` を 1 回実行
5. `ad_config.dart` などで広告ユニット ID を管理（テスト/本番切替）
6. 表示したい画面で Banner を load → `AdWidget` で表示、dispose を忘れずに
7. Pro ユーザーでは広告を load しない・表示しない

---

## 6. 実装計画（手順）

### Phase 0: 事前準備（app-ads.txt と AdMob コンソール）

| ステップ | 作業内容 | 成果物 |
|----------|----------|--------|
| **0-0** | **開発者サイトのルートに app-ads.txt を設置。Play/App Store の開発者URLをそのドメインに設定。AdMob で「アプリを追加」し、app-ads.txt の更新確認をリクエストしてアプリ確認を完了させる。** | **アプリの確認完了**（app-ads.txt エラー解消） |
| 0-1 | [AdMob](https://admob.google.com/) に Google アカウントでログイン | AdMob アカウント |
| 0-2 | 「アプリ」→「アプリを追加」で Android / iOS を登録（パッケージ名・Bundle ID を入力）。※ 0-0 完了後でないと確認完了できない場合あり | アプリごとの **アプリ ID**（例: `ca-app-pub-xxxxxxxx~yyyyyyyyyy`） |
| 0-3 | 各プラットフォームで「広告ユニット」→「Banner」を追加 | **広告ユニット ID**（例: `ca-app-pub-xxxxxxxx/zzzzzzzzzz`） |
| 0-4 | （任意）設定用・履歴用など「配置ごと」にユニットを分けるとレポートが見やすい | 複数の Banner 広告ユニット ID |

**注意**: 審査通過までは「テスト用広告」で表示確認。本番用 ID は審査通過後に有効化される想定。

---

### Phase 1: プロジェクト設定

**※ 具体的なコマンド・XML/plist の記述例は「§5 Flutter: google_mobile_ads パッケージで実装する手順」を参照。**

| ステップ | 作業内容 | ファイル |
|----------|----------|----------|
| 1-1 | `flutter pub add google_mobile_ads` でパッケージ追加 | `pubspec.yaml` |
| 1-2 | Android: `<application>` 内に `APPLICATION_ID` の `<meta-data>` を追加 | `android/app/src/main/AndroidManifest.xml` |
| 1-3 | iOS: `GADApplicationIdentifier` を追加 | `ios/Runner/Info.plist` |
| 1-4 | iOS: `Podfile` で最低バージョン確認（例: 12.0）。`pod install` 実行 | `ios/Podfile` |

**参考**:  
- [Google Mobile Ads Flutter - Quick start](https://developers.google.com/admob/flutter/quick-start)  
- テスト用アプリ ID: 公式ドキュメントの「Test ads」の ID を一時利用可能。

---

### Phase 2: アプリ内での初期化と共通基盤

**※ 初期化のコード例・Banner の load/表示/dispose の流れは「§5.4 〜 §5.6」を参照。**

| ステップ | 作業内容 | ファイル |
|----------|----------|----------|
| 2-1 | 起動時に `MobileAds.instance.initialize()` を一度だけ実行 | `main.dart` の `main()` 内、または `MyApp` の `initState` / 最初の `build` 前 |
| 2-2 | 広告ユニット ID を一箇所で管理（本番/テスト切替可能にする） | 例: `lib/services/ad_config.dart` または `lib/config/ad_ids.dart` |
| 2-3 | Free ユーザーかどうかを判定するプロバイダを利用 | 既存の `entitlementProvider`（`ref.watch(entitlementProvider).isPro` の逆） |
| 2-4 | Banner 用の共通ウィジェットを作成（ロード・表示・エラー時は非表示） | 例: `lib/features/ads/widgets/banner_ad_widget.dart` |

**共通ウィジェットの責務（案）**:

- `BannerAd` の作成・load・dispose。
- `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width)` でサイズ取得。
- `AdWidget(ad: bannerAd)` を返す。未ロード・Free でない場合は `SizedBox.shrink()`。
- Pro ユーザーなら最初から何も表示しない。

---

### Phase 3: 各画面への配置

| ステップ | 画面 | 配置位置 | 実装イメージ |
|----------|------|----------|--------------|
| 3-1 | **設定** | 保存ボタンの上（Column の最後の Expanded の直下） | `Column` の子として `BannerAdWidget()` を 1 つ追加。スクロール外で固定表示。 |
| 3-2 | **履歴** | カレンダーとリストの間、または画面最下部 | `Column` や `CustomScrollView` の適切な位置に 1 本。スクロールで隠れないようにするか、下部固定のいずれか。 |
| 3-3 | （任意）種目一覧 | リストの下 | `ListView` の後ろに `BannerAdWidget()`。 |
| 3-4 | （任意）メモ検索 | 結果リストの下 | 同様に 1 本。 |

**配置時の共通ルール**:

- すべて `entitlementProvider` を watch し、**Pro のときは `BannerAdWidget` を配置しない**（またはウィジェット内で false を返して `SizedBox.shrink()`）。
- 同じ画面に Banner は **1 本まで** にし、重くならないようにする。

---

### Phase 4: テストと本番切替

| ステップ | 作業内容 |
|----------|----------|
| 4-1 | 開発中は **テスト用広告ユニット ID** を使用（AdMob のポリシー推奨）。 |
| 4-2 | テスト用 ID 例（公式）:  
  - Android Banner: `ca-app-pub-3940256099942544/9214589741`  
  - iOS Banner: `ca-app-pub-3940256099942544/2435281174` |
| 4-3 | 本番リリース時に、`ad_config.dart`（または同様の設定）の ID を本番用に差し替え。 |
| 4-4 | 本番用アプリ ID も `AndroidManifest.xml` / `Info.plist` を本番用に更新。 |

---

## 7. ファイル構成（案）

```
lib/
├── config/
│   └── ad_config.dart          # 広告ユニットID・本番/テスト切替
├── services/
│   └── ad_service.dart         # （任意）初期化ラップ・広告プリロード等
└── features/
    └── ads/
        ├── widgets/
        │   └── banner_ad_widget.dart   # Free 時のみ表示する Banner ウィジェット
        └── providers/
            └── ad_visibility_provider.dart  # （任意）Pro なら false
```

- **ad_config.dart**:  
  - `kAdMobAppIdAndroid` / `kAdMobAppIdIOS`  
  - `kBannerAdUnitIdAndroid` / `kBannerAdUnitIdIOS`  
  - `kDebugMode` のときはテスト ID を返すようにしてもよい。

- **banner_ad_widget.dart**:  
  - `ref.watch(entitlementProvider).isPro == true` なら `SizedBox.shrink()`。  
  - そうでなければ `BannerAd` を load → `AdWidget` を表示。  
  - Stateful で load/dispose を管理。

---

## 8. 実装チェックリスト（作業用）

### Phase 0: 事前準備（app-ads.txt を最優先）

- [ ] AdMob アカウント作成し、パブリッシャー ID（pub-XXXXXXXX）を控える
- [ ] 開発者サイトを用意（自前ドメイン or Firebase Hosting / GitHub Pages 等）
- [ ] サイトルートに `app-ads.txt` を設置（内容: `google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0`）
- [ ] Play Store の「連絡先のウェブサイト」/ App Store の「Marketing URL」をそのドメインに設定
- [ ] AdMob で「アプリを追加」し、app-ads.txt の「更新を確認」をリクエスト → **アプリの確認が完了するまで待つ**
- [ ] Android アプリ登録・アプリ ID 取得
- [ ] iOS アプリ登録・アプリ ID 取得
- [ ] Banner 広告ユニット作成（Android / iOS 各1以上）
- [ ] 本番審査用にアプリを提出（必要に応じて）

### Phase 1: プロジェクト設定

- [ ] `pubspec.yaml` に `google_mobile_ads` 追加
- [ ] `AndroidManifest.xml` に AdMob アプリ ID を meta-data で追加
- [ ] `Info.plist` に `GADApplicationIdentifier` 追加
- [ ] `flutter pub get` / iOS の場合は `pod install` 実行

### Phase 2: 初期化・共通基盤

- [ ] `main.dart` で `MobileAds.instance.initialize()` を呼ぶ
- [ ] 広告 ID 管理用の `ad_config.dart`（または同様）を作成
- [ ] `BannerAdWidget` を実装（Pro のとき非表示・load/dispose・AdWidget）
- [ ] （任意）`AdService` で初期化をラップ

### Phase 3: 配置

- [ ] 設定画面に Banner を 1 本配置（Free のみ）
- [ ] 履歴画面に Banner を 1 本配置（Free のみ）
- [ ] （任意）種目一覧・メモ検索に配置

### Phase 4: テスト・リリース

- [ ] テスト用 ID で Android / iOS の両方で表示確認
- [ ] Pro ユーザーでは広告が表示されないことを確認
- [ ] 本番用 ID に差し替え手順をドキュメント化
- [ ] リリース前に本番 ID で一度表示確認（可能であれば）

---

## 9. 注意事項・運用

- **AdMob ポリシー**: クリック誘導や不正表示は禁止。テスト時は必ずテスト用 ID を使用する。
- **GDPR / プライバシー**: 欧州などで配信する場合は、ユーザー同意フローと UMP SDK（User Messaging Platform）の導入を検討する。
- **収益の見直し**: 最初は Banner のみで運用し、配置と収益を確認してからインラインやネイティブを検討する。
- **記録フローの最優先**: 新規画面を追加する場合も、「記録を邪魔しない」配置ルールを維持する。

---

## 10. 参考リンク

- [app-ads.txt の設定（AdMob ヘルプ）](https://support.google.com/admob/answer/9363762)
- [Authorized Sellers for Apps - Android](https://developers.google.com/admob/android/app-ads)
- [Google AdMob Flutter - Quick start](https://developers.google.com/admob/flutter/quick-start)
- [Banner ads - Flutter](https://developers.google.com/admob/flutter/banner)
- [Test ads - AdMob](https://developers.google.com/admob/android/test-ads#sample_ad_units)
- [google_mobile_ads | pub.dev](https://pub.dev/packages/google_mobile_ads)
