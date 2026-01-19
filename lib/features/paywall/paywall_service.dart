import 'package:flutter/material.dart';
import 'models/paywall_reason.dart';
import 'widgets/paywall_modal.dart';

/// Paywallを表示し、購入結果を返す
///
/// [context] BuildContext
/// [reason] Paywallを表示する理由
///
/// 返り値: 購入が完了した場合は true、キャンセルした場合は false
Future<bool> showPaywall(
  BuildContext context, {
  required PaywallReason reason,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaywallModal(reason: reason),
  );
  return result ?? false;
}
