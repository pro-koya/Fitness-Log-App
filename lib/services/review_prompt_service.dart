import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

/// 記録完了回数に応じて App Store / Play Store のレビュー依頼を促すサービス。
/// アプリ更新後、記録2回完了時に依頼ダイアログを表示。
/// 「あとで」の場合はさらに2回記録後に再表示する。
class ReviewPromptService {
  ReviewPromptService._();
  static const _keyCompletionCount = 'review_prompt_workout_completion_count';
  static const _keyNextPromptAtCount = 'review_prompt_next_at_count';
  static const _keyTrackedAppVersion = 'review_prompt_tracked_app_version';
  static const _keyReviewedAppVersion = 'review_prompt_reviewed_app_version';
  static const _triggerCount = 2;
  static const _skipAgainAfter = 2;

  static final ReviewPromptService _instance = ReviewPromptService._();
  factory ReviewPromptService() => _instance;

  final InAppReview _inAppReview = InAppReview.instance;

  Future<String> _getCurrentAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<void> _ensureVersionState(SharedPreferences prefs) async {
    final currentVersion = await _getCurrentAppVersion();
    final trackedVersion = prefs.getString(_keyTrackedAppVersion);
    if (trackedVersion == currentVersion) return;

    await prefs.setString(_keyTrackedAppVersion, currentVersion);
    await prefs.setInt(_keyCompletionCount, 0);
    await prefs.remove(_keyNextPromptAtCount);
  }

  /// 記録完了回数を1増やし、現在の回数を返す。
  Future<int> incrementCompletionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _ensureVersionState(prefs);
      final current = prefs.getInt(_keyCompletionCount) ?? 0;
      final next = current + 1;
      await prefs.setInt(_keyCompletionCount, next);
      return next;
    } catch (e) {
      debugPrint('ReviewPromptService: incrementCompletionCount error: $e');
      return 0;
    }
  }

  /// 現在のアプリバージョンでレビュー導線を完了済みか。
  Future<bool> hasReviewedCurrentVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _ensureVersionState(prefs);
      final currentVersion = await _getCurrentAppVersion();
      final reviewedVersion = prefs.getString(_keyReviewedAppVersion);
      return reviewedVersion == currentVersion;
    } catch (e) {
      debugPrint('ReviewPromptService: hasReviewedCurrentVersion error: $e');
      return true; // エラー時は再表示しない
    }
  }

  /// 現在のアプリバージョンでレビュー導線を完了扱いにする。
  Future<void> markReviewCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = await _getCurrentAppVersion();
      await prefs.setString(_keyReviewedAppVersion, currentVersion);
      await prefs.remove(_keyNextPromptAtCount);
    } catch (e) {
      debugPrint('ReviewPromptService: markReviewCompleted error: $e');
    }
  }

  /// 次にレビュー依頼を表示する完了回数（スキップ時に設定）。null なら初回は _triggerCount で表示。
  Future<int?> getNextPromptAtCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _ensureVersionState(prefs);
      final v = prefs.getInt(_keyNextPromptAtCount);
      return v;
    } catch (_) {
      return null;
    }
  }

  /// スキップ時: 現在の完了回数から _skipAgainAfter 回後に再表示するよう設定する。
  Future<void> markPromptSkipped(int currentCompletionCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyNextPromptAtCount, currentCompletionCount + _skipAgainAfter);
    } catch (e) {
      debugPrint('ReviewPromptService: markPromptSkipped error: $e');
    }
  }

  /// 記録2回完了かつ（現在のバージョンで未対応、再表示タイミングなら）true。
  Future<bool> shouldShowReviewPrompt(int currentCount) async {
    if (kIsWeb) return false;
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    if (await hasReviewedCurrentVersion()) return false;
    if (currentCount < _triggerCount) return false;
    final nextAt = await getNextPromptAtCount();
    if (nextAt != null && currentCount < nextAt) return false;
    return true;
  }

  Future<ReviewPromptAction?> showReviewPromptDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return showDialog<ReviewPromptAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star_rounded,
                size: 34,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.reviewPromptTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewPromptRateLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (_) => Icon(
                  Icons.star_rounded,
                  color: Colors.amber.shade600,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.reviewPromptMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(ReviewPromptAction.later),
            child: Text(l10n.reviewPromptLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(ReviewPromptAction.reviewNow),
            child: Text(l10n.reviewPromptWriteReview),
          ),
        ],
      ),
    );
  }

  /// ユーザーがレビュー意思を示した後にストアのレビュー導線を開く。
  /// まずストア一覧を開き、失敗時のみ in-app review を試す。
  Future<void> requestReview() async {
    try {
      if (Platform.isIOS) {
        await _inAppReview.openStoreListing(appStoreId: '6757798075');
      } else if (Platform.isAndroid) {
        await _inAppReview.openStoreListing();
      }
    } catch (e) {
      debugPrint('ReviewPromptService: openStoreListing error: $e');
      try {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
        }
      } catch (nested) {
        debugPrint('ReviewPromptService: requestReview fallback error: $nested');
      }
    }
  }
}

enum ReviewPromptAction {
  reviewNow,
  later,
}
