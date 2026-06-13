import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/entitlement_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_providers.dart';
import 'providers/timer_provider.dart';
import 'providers/theme_settings_provider.dart';
import 'services/bundle_entitlement_service.dart';
import 'services/timer_persistence_service.dart';
import 'services/timer_notification_service.dart';
import 'services/timer_local_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'features/initial_setup/initial_setup_screen.dart';
import 'features/main_tab/main_tab_screen.dart';
import 'features/tutorial/providers/interactive_tutorial_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final timerPersistence = TimerPersistenceService(prefs);

  TimerLocalNotificationService? timerNotificationService;
  try {
    final flutterLocalNotifications = FlutterLocalNotificationsPlugin();
    timerNotificationService = TimerLocalNotificationService(flutterLocalNotifications);
    await timerNotificationService.initialize();
  } catch (_) {
    // MissingPluginException on unsupported platform (e.g. simulator/desktop) or plugin not registered
    timerNotificationService = null;
  }

  runApp(
    ProviderScope(
      overrides: [
        timerPersistenceServiceOverride.overrideWith((ref) => timerPersistence),
        timerLocalNotificationServiceOverride.overrideWith((ref) => timerNotificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _hasShownGlobalNotification = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// アプリがフォアグラウンドに戻った時にバンドル状態を再取得する。
  /// TTL（60分）チェックは BundleEntitlementNotifier.refresh() が内部で行うため、
  /// キャッシュが有効な間は余分な Supabase RPC 呼び出しは発生しない。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(bundleEntitlementProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final timerState = ref.watch(timerProvider);
    final appTheme = ref.watch(appThemeDataProvider);

    // ログイン完了時にストアから課金状態を取得し、有料/無料を反映する
    ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (prev, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedIn && authState.session != null) {
          ref.read(entitlementProvider.notifier).refreshSubscriptionStatus();
        }
      });
    });

    // Monitor timer state globally
    // Only show global notification if notification hasn't been shown yet (prevents duplicate)
    if (timerState.hasFinished &&
        !timerState.isRunning &&
        !timerState.notificationShown &&
        !_hasShownGlobalNotification) {
      _hasShownGlobalNotification = true;
      // Use addPostFrameCallback to show dialog after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Mark notification as shown AFTER build completes (prevents Riverpod error)
        Future(() {
          ref.read(timerProvider.notifier).markNotificationShown();
        });
        _showGlobalTimerFinishedNotification();
      });
    }

    // Reset notification flag when timer is reset or started
    if (timerState.isRunning || (!timerState.hasFinished && _hasShownGlobalNotification)) {
      _hasShownGlobalNotification = false;
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Liftly',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(currentLanguage),
      home: const AppStartupScreen(),
    );
  }

  Future<void> _showGlobalTimerFinishedNotification() async {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext == null || !mounted) return;

    final settings = ref.read(timerSettingsProvider);
    await TimerNotificationService.play(settings);

    if (navigatorContext.mounted) {
      await _showTimerFinishedDialog(navigatorContext);
    }
  }

  Future<void> _showTimerFinishedDialog(BuildContext navigatorContext) async {
    final dialogColorScheme = Theme.of(navigatorContext).colorScheme;

    await showDialog(
      context: navigatorContext,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large timer icon with animation-like styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dialogColorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_off,
                size: 64,
                color: dialogColorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              AppLocalizations.of(navigatorContext)!.timerRestComplete,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              AppLocalizations.of(navigatorContext)!.timerRestCompleteMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: dialogColorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      // Clear the finished flag and reset timer (will use custom time if set)
                      ref.read(timerProvider.notifier).clearFinished();
                      ref.read(timerProvider.notifier).reset();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: dialogColorScheme.primary,
                      foregroundColor: dialogColorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reset Timer',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // Clear the finished flag after dialog is dismissed
    if (mounted) {
      ref.read(timerProvider.notifier).clearFinished();
    }
  }
}

/// Screen to determine which screen to show on startup
class AppStartupScreen extends ConsumerWidget {
  const AppStartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        // Show initial setup only on first launch (setup not completed)
        if (settings == null || !settings.setupCompleted) {
          return const InitialSetupScreen();
        }
        // Tutorial is started only once from InitialSetupScreen when user taps Start.
        // Do not auto-start tutorial here so it doesn't run on every app launch.
        // P1-4: ボトムナビで記録・履歴・設定を切り替える
        return const MainTabScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.errorLoadFailed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(settingsProvider),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: Text(l10n.retryButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
