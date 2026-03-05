import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 記録完了回数に応じて App Store / Play Store のレビュー依頼を促すサービス。
/// 記録3回完了時に1回だけ依頼ダイアログを表示し、OKでネイティブのレビューUIを開く。
class ReviewPromptService {
  ReviewPromptService._();
  static const _keyCompletionCount = 'review_prompt_workout_completion_count';
  static const _keyPromptShown = 'review_prompt_shown';
  static const _triggerCount = 3;

  static final ReviewPromptService _instance = ReviewPromptService._();
  factory ReviewPromptService() => _instance;

  final InAppReview _inAppReview = InAppReview.instance;

  /// 記録完了回数を1増やし、現在の回数を返す。
  Future<int> incrementCompletionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_keyCompletionCount) ?? 0;
      final next = current + 1;
      await prefs.setInt(_keyCompletionCount, next);
      return next;
    } catch (e) {
      debugPrint('ReviewPromptService: incrementCompletionCount error: $e');
      return 0;
    }
  }

  /// レビュー依頼ダイアログを既に表示済みか。
  Future<bool> hasAlreadyShownPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPromptShown) ?? false;
    } catch (e) {
      debugPrint('ReviewPromptService: hasAlreadyShownPrompt error: $e');
      return true; // エラー時は再表示しない
    }
  }

  /// 依頼表示済みフラグを立てる（一度だけ表示するため）。
  Future<void> markPromptShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPromptShown, true);
    } catch (e) {
      debugPrint('ReviewPromptService: markPromptShown error: $e');
    }
  }

  /// 記録3回完了かつ未表示なら true。ダイアログ表示の要否判定に使う。
  Future<bool> shouldShowReviewPrompt() async {
    if (kIsWeb) return false;
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    final shown = await hasAlreadyShownPrompt();
    if (shown) return false;
    final count = await _getStoredCount();
    return count >= _triggerCount;
  }

  Future<int> _getStoredCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyCompletionCount) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// ネイティブのレビューUIを表示（利用可能な場合）。依頼表示済みフラグは呼び出し元で管理する。
  Future<void> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('ReviewPromptService: requestReview error: $e');
    }
  }
}
