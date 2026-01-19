import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/entitlement_provider.dart';
import '../models/paywall_reason.dart';
import 'comparison_table.dart';

/// Paywall表示用のモーダルウィジェット
class PaywallModal extends ConsumerWidget {
  final PaywallReason reason;

  const PaywallModal({super.key, required this.reason});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // クローズボタン
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),

            // アイコン
            Icon(
              _getIcon(),
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),

            // タイトル
            Text(
              _getTitle(l10n),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // 本文
            Text(
              _getBody(l10n),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 比較表
            const ComparisonTable(),
            const SizedBox(height: 24),

            // 価格
            Text(
              '${l10n.paywallPriceMonthly}  ${l10n.paywallPriceOr}  ${l10n.paywallPriceYearly}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // CTAボタン
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  // TODO: 購入フロー（スタブではProに設定）
                  await ref.read(entitlementProvider.notifier).purchaseMonthly();
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: Text(l10n.paywallCtaTryPro),
              ),
            ),
            const SizedBox(height: 8),

            // サブCTA
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.paywallCtaNotNow),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (reason) {
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
    switch (reason) {
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
    switch (reason) {
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
