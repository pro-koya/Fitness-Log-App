import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../tutorial/providers/interactive_tutorial_provider.dart';
import '../home/home_screen.dart';

/// Initial setup screen shown on first launch
class InitialSetupScreen extends ConsumerStatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  ConsumerState<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends ConsumerState<InitialSetupScreen> {
  String _selectedLanguage = 'en';
  String _selectedUnit = 'kg';
  String _selectedDistanceUnit = 'km';

  @override
  void initState() {
    super.initState();
    // Set default based on system locale
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (systemLocale.languageCode == 'ja') {
      _selectedLanguage = 'ja';
    }
  }

  Future<void> _onStartPressed() async {
    // Update settings
    final notifier = ref.read(settingsNotifierProvider.notifier);

    // Update language first
    await notifier.updateLanguage(_selectedLanguage);

    // Then update unit
    await notifier.updateUnit(_selectedUnit);

    // Update distance unit
    await notifier.updateDistanceUnit(_selectedDistanceUnit);

    // Mark initial setup as completed (so we don't show this screen again on next launch)
    await notifier.markSetupCompleted();

    if (!mounted) return;

    // Start interactive tutorial (only once, when user completes initial setup)
    ref.read(interactiveTutorialProvider.notifier).startTutorial();

    // Navigate to Home Screen (tutorial overlay will be shown)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // App Icon/Logo
              Image.asset(
                'assets/icon/liftly-pro.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Colors.blue,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Welcome Message
              const Text(
                'Welcome to Liftly',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Language Selection
              _buildSectionLabel('Language / 言語'),
              const SizedBox(height: 12),
              _buildLanguageSelector(),
              const SizedBox(height: 32),

              // Weight Unit Selection
              _buildSectionLabel('Weight / 重さ'),
              const SizedBox(height: 12),
              _buildUnitSelector(),
              const SizedBox(height: 32),

              // Distance Unit Selection
              _buildSectionLabel('Distance / 距離'),
              const SizedBox(height: 12),
              _buildDistanceUnitSelector(),

              const Spacer(),

              // Start Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onStartPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start / 始める',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildLanguageOption('English', 'en'),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildLanguageOption('日本語', 'ja'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String label, String value) {
    final isSelected = _selectedLanguage == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildUnitOption('kg', 'kg'),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildUnitOption('lb', 'lb'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitOption(String label, String value) {
    final isSelected = _selectedUnit == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedUnit = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceUnitSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDistanceUnitOption('km', 'km'),
          ),
          Container(
            width: 1,
            height: 48,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _buildDistanceUnitOption('mile', 'mile'),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceUnitOption(String label, String value) {
    final isSelected = _selectedDistanceUnit == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDistanceUnit = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
        ),
      ),
    );
  }
}
