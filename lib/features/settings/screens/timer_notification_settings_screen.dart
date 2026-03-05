import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/timer_settings.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/timer_notification_service.dart';
import '../../ads/widgets/banner_ad_widget.dart';

/// タイマー終了時の通知設定画面
class TimerNotificationSettingsScreen extends ConsumerStatefulWidget {
  const TimerNotificationSettingsScreen({super.key});

  @override
  ConsumerState<TimerNotificationSettingsScreen> createState() =>
      _TimerNotificationSettingsScreenState();
}

class _TimerNotificationSettingsScreenState
    extends ConsumerState<TimerNotificationSettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final timerSettings = ref.watch(timerSettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(currentLanguageProvider);
    final isJa = lang == 'ja';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title = isJa ? 'タイマー終了時の通知' : 'Timer notification';
    final vibrationLabel = isJa ? 'バイブレーション' : 'Vibration';
    final soundLabel = isJa ? '音' : 'Sound';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 通知オン・オフ マスタースイッチ
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_outlined, color: colorScheme.primary, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              l10n.notificationSettingsEnableLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Switch(
                            value: timerSettings.notificationsEnabled,
                            onChanged: (v) async {
                              await ref.read(settingsNotifierProvider.notifier).saveTimerSettings(
                                    timerSettings.copyWith(notificationsEnabled: v),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // バイブレーション カード
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.vibration, color: colorScheme.primary, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              vibrationLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Switch(
                            value: timerSettings.vibrationEnabled,
                            onChanged: (v) async {
                              await ref.read(settingsNotifierProvider.notifier).saveTimerSettings(
                                    timerSettings.copyWith(vibrationEnabled: v),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 音 カード
                  Text(
                    soundLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          _buildSoundTile(
                            timerSettings,
                            TimerSettings.soundModeNone,
                            isJa ? 'なし' : 'None',
                            Icons.volume_off,
                            isFirst: true,
                          ),
                          ...TimerSettings.presetSounds.map((soundId) {
                            return _buildSoundTile(
                              timerSettings,
                              soundId,
                              _soundLabel(soundId, isJa),
                              _soundIcon(soundId),
                              showPreview: true,
                              isLast: soundId == TimerSettings.presetSounds.last,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildSoundTile(
    TimerSettings current,
    String mode,
    String label,
    IconData icon, {
    bool showPreview = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = current.soundMode == mode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        if (!isFirst) Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        RadioListTile<String>(
          value: mode,
          groupValue: current.soundMode,
          onChanged: (value) async {
            if (value == null) return;
            await ref.read(settingsNotifierProvider.notifier).saveTimerSettings(
                  current.copyWith(soundMode: value),
                );
          },
          title: Row(
            children: [
              Icon(icon, size: 22, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              const SizedBox(width: 14),
              Text(label, style: theme.textTheme.bodyLarge),
            ],
          ),
          secondary: showPreview
              ? IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Preview',
                  onPressed: () => _previewSound(mode),
                )
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(16) : Radius.zero,
              bottom: isLast ? const Radius.circular(16) : Radius.zero,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ],
    );
  }

  Future<void> _previewSound(String soundId) async {
    await TimerNotificationService.play(
      TimerSettings(vibrationEnabled: false, soundMode: soundId),
    );
  }

  String _soundLabel(String soundId, bool isJa) {
    switch (soundId) {
      case TimerSettings.soundModeAlarm:
        return isJa ? 'クラシックアラーム' : 'Classic alarm';
      case TimerSettings.soundModeChime:
        return isJa ? 'チャイム' : 'Chime';
      case TimerSettings.soundModeBeep:
        return isJa ? 'ビープ' : 'Beep';
      default:
        return soundId;
    }
  }

  IconData _soundIcon(String soundId) {
    switch (soundId) {
      case TimerSettings.soundModeAlarm:
        return Icons.alarm;
      case TimerSettings.soundModeChime:
        return Icons.notifications_active;
      case TimerSettings.soundModeBeep:
        return Icons.volume_up;
      default:
        return Icons.volume_up;
    }
  }
}
