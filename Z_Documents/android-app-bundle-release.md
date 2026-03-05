# Android App Bundle（AAB）リリース用手順

Google Play に提出する **App Bundle（.aab）** を用意するための手順です。

---

## 前提

- Flutter がインストール済み（`flutter doctor` で Android が問題ないこと）
- プロジェクトの `android/app/build.gradle.kts` には、すでに **key.properties を読む署名設定** が入っています
- **key.properties** は Git に含めません（`.gitignore` 済み）

---

## Step 1: アップロード用キーストアの作成（初回のみ）

まだ `upload-keystore.jks` を作っていない場合のみ実行してください。

### 1.1 コマンド実行

ターミナルで次を実行します（パスは任意で構いません。ここではホーム直下の例です）。

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 1.2 入力内容

プロンプトに従って入力します。

| 項目 | 例 |
|------|-----|
| キーストアのパスワード | 任意の強力なパスワード（2回入力） |
| 名前と姓 | 自分の名前やアプリ名 |
| 組織単位 | 空欄 Enter でも可 |
| 組織名 | 空欄 Enter でも可 |
| 市区町村 | 空欄 Enter でも可 |
| 都道府県 | 空欄 Enter でも可 |
| 国コード | JP |
| エイリアス `upload` のパスワード | キーストアと同じでよい（「同じ」と入力） |

### 1.3 重要

- **`upload-keystore.jks`** と **パスワード・エイリアス名** をなくすと、同じキーで署名した更新ができなくなります。
- 必ずバックアップ（安全な場所にコピー＋パスワードの管理）を取ってください。

---

## Step 2: key.properties の作成

### 2.1 配置場所

**`android/key.properties`** に置きます（プロジェクトの `android` フォルダ直下）。

### 2.2 作成方法

```bash
cd /Users/koya1104/Desktop/Fitness-Log-App/android
cp key.properties.example key.properties
```

エディタで `key.properties` を開き、次の4行を実際の値に書き換えます。

```properties
storePassword=ここにキーストアのパスワード
keyPassword=ここにエイリアス(upload)のパスワード
keyAlias=upload
storeFile=/Users/koya1104/upload-keystore.jks
```

- **storeFile**: `upload-keystore.jks` の**絶対パス**を指定します。  
  例: ホーム直下なら `/Users/koya1104/upload-keystore.jks`
- **key.properties は絶対に Git にコミットしないでください**（すでに .gitignore に含まれています）。

---

## Step 3: バージョンの確認

`pubspec.yaml` の先頭付近を確認します。

```yaml
version: 1.0.1+2
```

- **1.0.1** → `versionName`（ストアに表示されるバージョン）
- **2** → `versionCode`（整数。リリースごとに増やす）

Google Play にアップロードするたびに、**同じ versionCode は使えません**。次回リリース時は例: `1.0.2+3` のように増やします。

---

## Step 4: App Bundle のビルド

### 4.1 クリーンビルド（推奨）

```bash
cd /Users/koya1104/Desktop/Fitness-Log-App
flutter clean
flutter pub get
```

### 4.2 リリース用 AAB の作成

```bash
flutter build appbundle --release
```

### 4.3 成功時

次のファイルが生成されます。

```
build/app/outputs/bundle/release/app-release.aab
```

この **app-release.aab** を Google Play Console の「本番環境」のリリースでアップロードします。

---

## Step 5: トラブルシュート

### key.properties がない / 署名エラー

- **「key.properties がありません」**  
  → Step 2 のとおり `android/key.properties` を作成し、`storeFile` を絶対パスで正しく指定しているか確認してください。
- **「storeFile が見つかりません」**  
  → `storeFile` に書いたパスに、本当に `upload-keystore.jks` があるか確認してください（`ls -la /Users/koya1104/upload-keystore.jks` など）。

### ビルドは通るが「debug で署名されている」と言われる

- `android/key.properties` が存在し、4項目とも正しく設定されているか確認してください。
- `flutter clean` のあと、もう一度 `flutter build appbundle --release` を実行してください。

### versionCode の重複

- Google Play に同じ versionCode の AAB は再アップロードできません。  
  → `pubspec.yaml` の `version: x.y.z+N` の **N** を一度上げてからビルドし直してください。

---

## チェックリスト（ビルド前）

- [ ] `upload-keystore.jks` を作成済み（初回のみ）
- [ ] `android/key.properties` を作成し、4項目を正しく記入
- [ ] `storeFile` は絶対パスで、実際の .jks の場所を指している
- [ ] `pubspec.yaml` の version / versionCode を確認済み
- [ ] `flutter build appbundle --release` で `app-release.aab` が出力された

---

## 参考

- [Flutter: Android のリリースビルド](https://docs.flutter.dev/deployment/android)
- [Google Play: アプリに署名する](https://support.google.com/googleplay/android-developer/answer/9842756)
