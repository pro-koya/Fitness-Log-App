import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/entitlement.dart';
import '../../../providers/entitlement_provider.dart';
import '../../../services/iap_service.dart';
import '../models/paywall_reason.dart';
import 'comparison_table.dart';

/// サブスクリプションタイプ
enum SubscriptionType { monthly, yearly }

/// Paywall表示用のモーダルウィジェット
class PaywallModal extends ConsumerStatefulWidget {
  final PaywallReason reason;

  const PaywallModal({super.key, required this.reason});

  @override
  ConsumerState<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends ConsumerState<PaywallModal> {
  SubscriptionType _selectedType = SubscriptionType.yearly;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthlyPrice = ref.watch(monthlyPriceProvider);
    final yearlyPrice = ref.watch(yearlyPriceProvider);

    // IAPStateを直接watchして、状態変化時にrebuildを確実にトリガー
    final iapState = ref.watch(iapServiceProvider);

    // entitlement を監視: stream経由で購入完了 → Pro化したら自動クローズ
    ref.listen<EntitlementState>(entitlementProvider, (previous, next) {
      debugPrint('Paywall: EntitlementState changed: isPro=${next.isPro}');
      if ((_isPurchasing || _isRestoring) && next.isPro) {
        debugPrint('Paywall: Pro detected → closing modal');
        if (mounted) Navigator.pop(context, true);
      }
    });

    // Safety net: ローカルの_isPurchasingがtrueなのにIAPStateがisPurchasing=false
    // → 状態の不整合を検知してUIをリセット（直接returnパスが何らかの理由で効かない場合の保険）
    if ((_isPurchasing || _isRestoring) && !iapState.isPurchasing) {
      final entitlement = ref.read(entitlementProvider);
      if (!entitlement.isPro) {
        debugPrint('Paywall: Inconsistency detected in build - '
            'local _isPurchasing=$_isPurchasing, _isRestoring=$_isRestoring, '
            'iapState.isPurchasing=${iapState.isPurchasing}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && (_isPurchasing || _isRestoring)) {
            debugPrint('Paywall: Safety reset via addPostFrameCallback');
            setState(() {
              _isPurchasing = false;
              _isRestoring = false;
              _errorMessage = iapState.errorMessage != null
                  ? AppLocalizations.of(context)!.paywallSubscriptionError
                  : null;
            });
          }
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // クローズボタン
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isPurchasing ? null : () => Navigator.pop(context, false),
                ),
              ),

              // アイコン
              Icon(
                _getIcon(),
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),

              // トライアルタイトル
              Text(
                l10n.paywallTrialTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // トライアル説明
              Text(
                l10n.paywallTrialDescription,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 機能説明（元のreason-based説明）
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIcon(),
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getBody(l10n),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 比較表
              const ComparisonTable(),
              const SizedBox(height: 24),

              // サブスクリプション選択
              _buildSubscriptionSelector(l10n, monthlyPrice, yearlyPrice),
              const SizedBox(height: 16),

              // エラーメッセージ
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],

              // CTAボタン
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isPurchasing || _isRestoring ? null : _handlePurchase,
                  child: _isPurchasing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(l10n.paywallSubscriptionPurchasing),
                          ],
                        )
                      : Text(l10n.paywallCtaStartTrial),
                ),
              ),
              const SizedBox(height: 8),

              // トライアル注意事項
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.paywallTrialNotice,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // サブスク注意事項（自動更新・キャンセル方法）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.paywallSubscriptionDisclaimer,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // 復元ボタン
              TextButton(
                onPressed: _isPurchasing || _isRestoring ? null : _handleRestore,
                child: _isRestoring
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.paywallRestoring),
                        ],
                      )
                    : Text(l10n.paywallRestorePurchases),
              ),

              // Terms of Use / Privacy Policy リンク
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _openUrl('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                    child: Text(
                      l10n.paywallTermsOfService,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '|',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openPrivacyPolicy(),
                    child: Text(
                      l10n.paywallPrivacyPolicy,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // サブCTA
              TextButton(
                onPressed: _isPurchasing || _isRestoring ? null : () => Navigator.pop(context, false),
                child: Text(l10n.paywallCtaNotNow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// サブスクリプション選択UI
  Widget _buildSubscriptionSelector(
    AppLocalizations l10n,
    String monthlyPrice,
    String yearlyPrice,
  ) {
    return Row(
      children: [
        // 月額オプション
        Expanded(
          child: _buildSubscriptionOption(
            type: SubscriptionType.monthly,
            label: l10n.paywallSubscriptionMonthly,
            price: monthlyPrice,
            isSelected: _selectedType == SubscriptionType.monthly,
          ),
        ),
        const SizedBox(width: 12),
        // 年額オプション
        Expanded(
          child: _buildSubscriptionOption(
            type: SubscriptionType.yearly,
            label: l10n.paywallSubscriptionYearly,
            price: yearlyPrice,
            isSelected: _selectedType == SubscriptionType.yearly,
            badge: l10n.paywallSubscriptionYearlySave,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionOption({
    required SubscriptionType type,
    required String label,
    required String price,
    required bool isSelected,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: _isPurchasing ? null : () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? primaryColor.withOpacity(0.05) : null,
        ),
        child: Column(
          children: [
            // バッジ
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const SizedBox(height: 22),
            // ラベル
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : null,
              ),
            ),
            const SizedBox(height: 4),
            // 価格
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    debugPrint('Paywall: _handlePurchase started, type=$_selectedType');
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      final entitlementNotifier = ref.read(entitlementProvider.notifier);
      PurchaseResult result;

      if (_selectedType == SubscriptionType.monthly) {
        result = await entitlementNotifier.purchaseMonthly();
      } else {
        result = await entitlementNotifier.purchaseYearly();
      }

      debugPrint('Paywall: purchase result=$result, mounted=$mounted');

      if (!mounted) return;

      switch (result) {
        case PurchaseResult.success:
          debugPrint('Paywall: success → closing modal');
          Navigator.pop(context, true);
          break;
        case PurchaseResult.pending:
          debugPrint('Paywall: pending → waiting for stream');
          // 購入処理中 - ストリームからの結果を待つ
          // build() 内の iapState watch + entitlement listen で自動処理
          break;
        case PurchaseResult.cancelled:
          debugPrint('Paywall: cancelled → resetting UI');
          // ユーザーがキャンセル - 即座にUIリセット
          setState(() {
            _isPurchasing = false;
          });
          break;
        case PurchaseResult.error:
          debugPrint('Paywall: error → showing error message');
          final l10n = AppLocalizations.of(context)!;
          setState(() {
            _isPurchasing = false;
            _errorMessage = l10n.paywallSubscriptionError;
          });
          break;
      }
    } catch (e) {
      debugPrint('Paywall: _handlePurchase exception: $e');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _isPurchasing = false;
        _errorMessage = l10n.paywallSubscriptionError;
      });
    }
  }

  Future<void> _handleRestore() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(entitlementProvider.notifier).restorePurchases();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paywallRestoreSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isRestoring = false;
          _errorMessage = l10n.paywallRestoreNoSubscription;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestoring = false;
        _errorMessage = l10n.paywallSubscriptionError;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open URL: $e');
    }
  }

  void _openPrivacyPolicy() {
    final locale = Localizations.localeOf(context);
    final url = locale.languageCode == 'ja'
        ? 'https://lovely-kitty-76f.notion.site/2f60ff4893228039a89fed882469cdde?source=copy_link'
        : 'https://lovely-kitty-76f.notion.site/Privacy-Policy-2f60ff489322807398aac2e94993f0a9?source=copy_link';
    _openUrl(url);
  }

  IconData _getIcon() {
    switch (widget.reason) {
      case PaywallReason.historyLocked:
        return Icons.history;
      case PaywallReason.chart:
        return Icons.show_chart;
      case PaywallReason.theme:
        return Icons.palette;
      case PaywallReason.stats:
        return Icons.analytics;
      case PaywallReason.backup:
        return Icons.backup;
    }
  }

  String _getTitle(AppLocalizations l10n) {
    switch (widget.reason) {
      case PaywallReason.historyLocked:
        return l10n.paywallTitleHistory;
      case PaywallReason.chart:
        return l10n.paywallTitleChart;
      case PaywallReason.theme:
        return l10n.paywallTitleTheme;
      case PaywallReason.stats:
        return l10n.paywallTitleStats;
      case PaywallReason.backup:
        return l10n.paywallTitleBackup;
    }
  }

  String _getBody(AppLocalizations l10n) {
    switch (widget.reason) {
      case PaywallReason.historyLocked:
        return l10n.paywallBodyHistory;
      case PaywallReason.chart:
        return l10n.paywallBodyChart;
      case PaywallReason.theme:
        return l10n.paywallBodyTheme;
      case PaywallReason.stats:
        return l10n.paywallBodyStats;
      case PaywallReason.backup:
        return l10n.paywallBodyBackup;
    }
  }
}
