# バンドル購入の検証と配布（2026-11-10）

購入端末のストア権利と、ログイン中の本人に属するアプリ間共有を分ける。自己申告の取引ID/期限を送る旧 `record_bundle_purchase` RPC と、端末から加入状態を書き換える経路は使わない。

- 新規バンドル購入はログイン後に開始し、Supabase UUIDをAppleのappAccountTokenへ渡す。
- `verify-bundle-purchase` Edgeへ、利用者のBearer sessionと `{bundleId, signedTransaction}` だけを送る。JWS/トークン/利用者ID/サーバー生エラーをログへ出さない。
- ProductionとSandboxのサーバー共有は別realmとする。署名・アプリ/商品・購入者・appAccountToken一致・Apple最新状態をサーバーで照合し、署名で確定した環境だけで保存先を決める。StoreKit Testは端末のローカル権利だけで検証する。
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

## 全体ビルドの実測と最低OS

2026-11-10、OS設定変更前のsource main `b1e3d20e2e6e7afb7e36f24f57b4d1c08794ed98` で全unit test 5ファイル42件が成功。変更した9ファイルの静的解析はerror 0。既存UIにwithOpacity等の非推奨info 5件と未使用_getTitleのwarning 1件が残る。新しい共有サービスのbrace指摘は修正済み。

最低OSをiOS15以上へ変更するユーザーの明示了承により、RunnerのDebug/Profile/Release、AppFrameworkInfo.plist、Podfile platformを15.0へ揃えた。Podsのpost_installも15.0を下限とし、それ以上を要求する依存の値は下げない。iOS13/14は今回の更新対象外。

通常の `flutter build ios --release --no-codesign` が、deployment targetの引数/環境上書きなしで成功（Xcode build 83.3秒、Runner.app 41.4MB）。生成したPods projectの対象値はすべて15.0。Runner.appのbundle IDはcom.fitnesslog.fitnessLogApp、version 1.1.1/build 10、MinimumOSVersionは15.0。Flutter SDKが生成する組込framework自身の下限値はSDKのままとし、アプリの対象OSはRunnerの15.0で制御する。Flutter SDKやグローバル設定は変更していない。

今回の差分はOS設定のみのため42試験は重複実行せず、Ruby構文、plist、生成Pods/成果物の最低OS、通常の全体Release buildで確認した。既存pluginのSPM未対応警告は残る。サーバー側の署名検証経路は修復済みだが、正規購入/restoreを含む実機の全通し、署名配布、App Storeへのupload/審査/公開は未実施。

再実行時は空のbuildパスを固定cacheへsymlinkし、グローバルFlutter設定を変更しない。

```sh
mkdir -p ~/.cache/koya-build/liftly/security-release
# buildが存在する場合は上書きせず、現在の内容/参照先を確認する。
ln -s ~/.cache/koya-build/liftly/security-release build
flutter pub get --enforce-lockfile
flutter build ios --release --no-codesign
```

署名/配布の前に実機の購入/復元/返金/アカウント切替と画面を確認し、ASCの最新ビルド番号より大きいbuild numberを設定する。

## 署名済み配布候補（未アップロード）

2026-11-10、既存のASC用キー・同じTeam設定を使い、署名付きarchiveとApp Store Connect向けIPAのローカルexportを完了。購入検証用SubscriptionKeyは配布に使用していない。

| Item | Value |
|---|---|
| Version / build | 1.1.2 / 11 |
| Source main | `dbe48d09d14c26044ee1f7ce2660b0327b239aca` |
| Archive | `/Users/koya1104/.cache/koya-build/liftly/security-release/Runner.xcarchive` |
| IPA | `/Users/koya1104/.cache/koya-build/liftly/security-release/appstore-export/fitness_log_app.ipa` |
| IPA SHA256 | `463d01513bd9c80641375473bd49006ae5970817b13d160738e68a35e9656791` |
| Minimum iOS | 15.0 |
| Signature | Apple Distribution / Team 992BWJ82JX |

archiveの既存開発署名をもとに、export時にIPAをApple Distributionへ再署名した。IPAを展開して `codesign --verify --deep --strict` とApple anchor/Team OU要件を確認。get-task-allow=false、App Store profile（端末リスト/全端末配布なし、beta-reports-active=true、有効期限内）、bundle ID・version/build・最低OSの一致を確認した。ExportOptionsはdestination=export、manageAppVersionAndBuildNumber=false。実機の正規購入/restore・更新/返金・アカウント切替の全通し、App Storeへのupload/審査/公開は未実施。

採用ログとexportのPackaging.logにJWTやprivate keyの値を残さない。Xcodeが内部配布ログへ自動記録する一時JWTも、終了直後に走査・伏字化した。archive/IPAはdisk-guardで消されないよう各フォルダに.disk-guard-keepを置き、公開が承認されるまで保持する。


## Sandbox配布QAの環境分離（署名候補の再作成前）

クライアントはOSの購入環境を毎回確認する。iOS 16以上はStoreKitの検証済みAppTransaction.environmentを優先し、取得に失敗した場合（iOS 15では常に）は実在するApp Store receiptのファイル名を使う。sandboxReceiptはSandbox、receiptはProduction、それ以外・未生成・未検証は不明。Xcode環境も共有は付けない。不明なら端末購入を維持したまま、次の起動/復帰・定期更新・購入/復元で再取得する。自動で認証promptを出す強制refreshはしない。LiftlyはiOS native MethodChannel経由で同じ判定を渡す。Androidの新バンドル購入停止は継続する。

Sandboxはget_sandbox_bundle_statusだけ、Productionはget_bundle_statusだけを読む。verify-bundle-purchaseへのbodyはbundleIdとsignedTransactionのまま、environmentの自己申告は送らない。GET/POSTのresponse.environmentが現在の既知環境と一致した場合だけ共有leaseを反映する。欠落/不明/不一致は共有権利を破棄し、UID/環境変更と同じく古い応答を世代で拒否する。端末のStoreKit検証済み権利はこれらと別に維持する。Sandboxは30秒の再読間隔、本番は5分のcacheを使い、サーバー期限でも失効する。Sandbox権利は本番の有料APIや本番表の権利にはならない。

この変更後の実機/TestFlightでの正常購入・復元、receipt未生成からの再取得、本番/Sandboxの往復は未検証。上記の署名済みarchive/IPAはこの環境分離変更より前の成果物なので、未アップロードの同じversion/buildで再作成してから配布する。この段階で新しい署名build/upload/審査/公開は行っていない。

環境分離変更の検証: Flutter全5ファイル48試験、変更serviceのanalyze（問題0）、実Flutter.framework/StoreKitを使うiOS15 AppDelegate型検査を確認。型検査では既存registrant/timer bridgeの型だけstubを使い、この変更後の全体アプリbuildはまだ行っていない。 採用ログは `/Users/koya1104/.local/state/miyakoya-security/builds/bundle-realm-verification-20261110.log`（0600）。一時試験cacheは整理し、新規に残したsimulator/devserver/watchはない。
