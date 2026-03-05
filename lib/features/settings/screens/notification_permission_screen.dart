import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/timer_provider.dart';

/// 通知を許可するかどうかの確認画面。トグルで「通知を送る」を ON にしたときのみ表示。
/// 許可する / あとで の選択肢を表示し、許可した場合のみ設定を ON に保存する。
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _isRequesting = false;

  Future<void> _onAllow() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    try {
      final service = ref.read(timerLocalNotificationServiceOverride);
      if (service != null) {
        await service.requestPermission();
      }
      if (mounted) {
        final timerSettings = ref.read(timerSettingsProvider);
        await ref.read(settingsNotifierProvider.notifier).saveTimerSettings(
              timerSettings.copyWith(notificationsEnabled: true),
            );
        if (mounted) Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _onNotNow() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationPermissionTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.notifications_active_outlined,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.notificationPermissionMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isRequesting ? null : _onAllow,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.notificationPermissionAllow),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isRequesting ? null : _onNotNow,
                child: Text(l10n.notificationPermissionNotNow),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
