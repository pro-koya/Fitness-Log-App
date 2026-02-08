あなたはFlutterのシニアエンジニアです。下記のApp Store Reviewリジェクトを解消するため、コード修正を行ってください。

## 背景
- アプリ：Liftly（筋トレ記録）
- 課金：Auto-Renewable Subscription（月額/年額）
- productId:
  - com.fitnesslog.liftly.pro.monthly
  - com.fitnesslog.liftly.pro.yearly

## 解決必須（最優先）
### 1) IAP購入が審査端末で失敗した（Guideline 2.1）
- in_app_purchaseの実装を確認し、Sandbox環境で購入が成功するように修正
- queryProductDetailsが成功し、購入フローが完了すること
- purchaseStreamを購読し、購入成功時にcompletePurchaseを必ず呼ぶ
- 失敗時にUIでエラー表示（無反応/クラッシュを禁止）
- Restore Purchasesを実装し、復元できること
- Pro entitlementを端末に永続化し、再起動後も維持

### 2) サブスク必須情報（3.1.2）
アプリ内に以下のリンクを追加（SettingsとPaywallのどちらか、可能なら両方）
- Privacy Policy（日本語版）: https://lovely-kitty-76f.notion.site/2f60ff4893228039a89fed882469cdde?source=copy_link
- Privacy Policy（英語版）: https://lovely-kitty-76f.notion.site/Privacy-Policy-2f60ff489322807398aac2e94993f0a9?source=copy_link
- Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- それぞれタップで外部ブラウザが開くこと（url_launcherでOK）

## 望ましい仕様
- 無料でも基本機能は利用可能（課金強制NG）
- Paywallの下部に短い注意書き：
  - 自動更新、キャンセル方法（Apple IDのサブスク管理）、トライアル後課金
- UIは世界一シンプル思想を崩さない

## 出力
- 修正したファイル一覧
- 主要コード（IAP service/provider, purchaseStream handling, restore, link UI）
- 手動テスト手順（Sandboxでの確認手順）
