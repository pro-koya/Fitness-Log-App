# バンドル購入の検証と配布（2026-11-10）

購入端末のストア権利と、ログイン中の本人に属するアプリ間共有を分ける。自己申告の取引ID/期限を送る旧 `record_bundle_purchase` RPC と、端末から加入状態を書き換える経路は使わない。

- 新規バンドル購入はログイン後に開始し、Supabase UUIDをAppleのappAccountTokenへ渡す。
- `verify-bundle-purchase` Edgeへ、利用者のBearer sessionと `{bundleId, signedTransaction}` だけを送る。JWS/トークン/利用者ID/サーバー生エラーをログへ出さない。
- サーバー共有はProductionの購入だけが対象。署名・アプリ/商品・購入者・appAccountToken一致・Apple最新状態をサーバーで照合する。Sandbox/StoreKit Testは端末のローカル権利だけで検証する。
- tokenがない旧購入、別アカウント、家族共有は自動で紐付けない。端末の有効な購入は維持する。旧購入の共有には所有者を確認する別の移行手続きが必要で、復元だけではappAccountTokenが遡って付かない。取引IDだけで移管しない。
- サーバー共有は本人・有限期限付き。サーバーの期限はApple期限と再検証lease（最大30分）の短い方。アカウント変更/ログアウトで共有状態を破棄し、期限でも失効する。GET/POST共通の送信前世代により古い応答を破棄する。
- Flutterの実効Proは現在の端末IAP（単独または端末bundle）OR現在のサーバー共有。共有状態を端末proへ永続化しない。旧永続proは由来が曖昧なので、起動直後はストアの復元を待つ。明示操作の開発用overrideは別フラグで、本番では無効。
- iOSはStoreKit 2の商品とJWSが必須。新規Android bundle購入は検証経路が用意されるまで開始しない。既存端末の購入と単独プランの経路は保持する。
- IAP 3.3.1 / StoreKit 0.4.17を固定し、Dart >=3.11.0を必要とする。pubspec.lockで解決した依存を固定する。

## 検証済み

- Flutter 3.44.2 / Dart 3.12.2で購入サービス、共有サービス、Pro判定、HTTP認証/遅延応答の試験35件。
- 変更したサービス/Pro provider/HTTP試験の静的解析。
- HTTP偽装の試験で、本人session・JWSだけの送信、409、アカウント変更、期限失効、共有権利の永続混入防止、旧端末bundle保全、遅着activeの拒否を確認。実Apple購入の試験ではない。

## 配布前に残る確認

実機での購入・復元・返金・アカウント切替・広告/機能ゲート/設定画面確認は、このサービス試験だけでは検証していない。App Storeへのupload、審査提出、公開は未実施。Google Playのサーバー検証も未実装。配布されるまで旧アプリの横断同期は再開しない。

`flutter pub get --enforce-lockfile`、`flutter test`、`flutter build ios --release --no-codesign` を実行し、既存ios/fastlaneのリリース手順で署名/配布する。ビルド出力は `~/.cache/koya-build/liftly/security-release` を固定して再利用する。

参照: [Apple VerificationResult](https://developer.apple.com/documentation/storekit/verificationresult)、[Supabase Swift Functions](https://supabase.com/docs/reference/swift/functions-invoke)、[Flutter StoreKit JWS](https://pub.dev/packages/in_app_purchase_storekit/changelog)。

## 全体ビルドの実測と配布上の制約

2026-11-10、source main `b1e3d20e2e6e7afb7e36f24f57b4d1c08794ed98` で全unit test 5ファイル42件が成功。変更した9ファイルの静的解析はerror 0。既存UIにwithOpacity等の非推奨info 5件と未使用_getTitleのwarning 1件が残る。新しい共有サービスのbrace指摘は修正済み。

現在の唯一のXcode 27.2では、既存Runner/PodsのiOS13（一部Pod9）のdeployment targetが対応下限iOS15未満として、通常の `flutter build ios --release --no-codesign` がTarget Integrityで停止した。ビルド時だけ `IPHONEOS_DEPLOYMENT_TARGET=15.0` を渡す全体Releaseコンパイル/リンクはBUILD SUCCEEDED。Runner.appのbundle IDはcom.fitnesslog.fitnessLogApp、version 1.1.1/build 10、検証成果物の最低OSは15.0。canonicalのPodfile/Runner projectの最低OS13は変更していない。FlutterCLIによるAppFrameworkInfo.plistの自動変更も正本へは入れていない。

実配布には、最低OS13を維持して確認できる対応toolchainを用意するか、最低OSを15へ変更する判断と設定整合が必要。この検証用overrideを、既存iOS13/14向けの配布確認が済んだものとは扱わない。Pods/既存Live Activity bridgeの非推奨・未使用警告、SPM未対応pluginの将来移行警告が残るが、今回の全体ビルドにエラーはない。

再実行時は空のbuildパスを固定cacheへsymlinkし、グローバルFlutter設定を変更しない。

```sh
mkdir -p ~/.cache/koya-build/liftly/security-release
# buildが存在する場合は上書きせず、現在の内容/参照先を確認する。
ln -s ~/.cache/koya-build/liftly/security-release build
flutter pub get --enforce-lockfile
flutter test --concurrency 1
flutter build ios --release --no-codesign --config-only --no-pub
(cd ios && pod install)
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination 'generic/platform=iOS' -derivedDataPath ~/.cache/koya-build/liftly/security-release/derived -jobs 2 CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0 build
```

署名/配布の前にサーバーの実署名検証正常系、実機の購入/復元/返金/アカウント切替と画面を確認し、ASCの最新ビルド番号より大きいbuild numberを設定する。App Storeへのupload/審査/公開は未実施。
