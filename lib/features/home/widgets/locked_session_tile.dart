import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/entities/workout_session_entity.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/date_formatter.dart';
import '../../paywall/paywall_service.dart';
import '../../paywall/models/paywall_reason.dart';

/// ロックされたワークアウトセッションを表示するタイル
///
/// Freeユーザーが直近20件より古い履歴をタップした際に
/// Paywallを表示するためのUIコンポーネント
class LockedSessionTile extends ConsumerWidget {
  final WorkoutSessionEntity session;

  const LockedSessionTile({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final completedAt = session.completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(session.completedAt! * 1000)
        : null;

    final dateStr = completedAt != null
        ? DateFormatter.formatDate(completedAt, currentLanguage)
        : l10n.unknownDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey.shade100,
      child: InkWell(
        onTap: () async {
          await showPaywall(context, reason: PaywallReason.historyLocked);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // ロックアイコン
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.lockedSessionHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
