import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Free/Proプランの比較表ウィジェット
class ComparisonTable extends StatelessWidget {
  const ComparisonTable({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ヘッダー行
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                _buildCell('', flex: 2, isHeader: true),
                _buildCell(l10n.freeLabel, isHeader: true),
                _buildCell(l10n.proLabel, isHeader: true, isPro: true),
              ],
            ),
          ),
          const Divider(height: 1),
          // 行1: 履歴
          Row(
            children: [
              _buildCell(l10n.paywallCompareHistory, flex: 2),
              _buildCell(l10n.paywallCompareLast20),
              _buildCell(l10n.paywallCompareUnlimited, isPro: true),
            ],
          ),
          const Divider(height: 1),
          // 行2: グラフ
          Row(
            children: [
              _buildCell(l10n.paywallCompareCharts, flex: 2),
              _buildCell('−'),
              _buildCell('✓', isPro: true),
            ],
          ),
          const Divider(height: 1),
          // 行3: テーマ
          Row(
            children: [
              _buildCell(l10n.paywallCompareTheme, flex: 2),
              _buildCell(l10n.paywallCompareDefault),
              _buildCell(l10n.paywallCompareCustom, isPro: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(
    String text, {
    int flex = 1,
    bool isHeader = false,
    bool isPro = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            color: isPro ? Colors.blue : null,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
