import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/theme_settings_provider.dart';
import 'features/initial_setup/initial_setup_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(
    // Wrap the entire app with ProviderScope for Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _hasShownGlobalNotification = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final timerState = ref.watch(timerProvider);
    final appTheme = ref.watch(appThemeDataProvider);

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
      title: 'Fitness Log App',
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

    // Vibrate 3 times with short intervals
    for (int i = 0; i < 3; i++) {
      HapticFeedback.mediumImpact();
      if (i < 2) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // Play system alert sound
    SystemSound.play(SystemSoundType.alert);

    // Show enhanced dialog using navigator context
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
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_off,
                size: 64,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Rest Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'Your rest time is over.\nReady for the next set?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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
        // If settings exist, go to Home Screen
        // Otherwise, go to Initial Setup Screen
        if (settings != null) {
          return const HomeScreen();
        } else {
          return const InitialSetupScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }
}
