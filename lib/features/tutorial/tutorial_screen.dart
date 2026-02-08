import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../home/home_screen.dart';

/// Tutorial screen shown after initial setup
/// Uses PageView to display multiple tutorial pages with swipe navigation
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialPage> _pages = const [
    _TutorialPage(
      icon: Icons.fitness_center,
      titleEn: 'Track Your Workouts',
      titleJa: 'トレーニングを記録',
      descriptionEn:
          'Easily log exercises, sets, and reps for each workout session.',
      descriptionJa: '種目、セット数、回数を簡単に記録できます。',
    ),
    _TutorialPage(
      icon: Icons.timer,
      titleEn: 'Rest Timer',
      titleJa: 'レストタイマー',
      descriptionEn:
          'Use the built-in timer to track rest intervals between sets.',
      descriptionJa: 'セット間の休憩時間をタイマーで管理できます。',
    ),
    _TutorialPage(
      icon: Icons.show_chart,
      titleEn: 'View Progress',
      titleJa: '成長を確認',
      descriptionEn:
          'Track your progress over time with detailed charts and statistics.',
      descriptionJa: 'グラフと統計で成長を振り返ることができます。',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToHome();
    }
  }

  void _skipTutorial() {
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Mark setup as completed before navigating
    await ref.read(settingsNotifierProvider.notifier).markSetupCompleted();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final isJapanese = currentLanguage == 'ja';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipTutorial,
                  child: Text(
                    isJapanese ? 'スキップ' : 'Skip',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildTutorialPage(page, isJapanese);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next/Start button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? (isJapanese ? '始める' : 'Get Started')
                        : (isJapanese ? '次へ' : 'Next'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(_TutorialPage page, bool isJapanese) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            isJapanese ? page.titleJa : page.titleEn,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            isJapanese ? page.descriptionJa : page.descriptionEn,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// Tutorial page data model
class _TutorialPage {
  final IconData icon;
  final String titleEn;
  final String titleJa;
  final String descriptionEn;
  final String descriptionJa;

  const _TutorialPage({
    required this.icon,
    required this.titleEn,
    required this.titleJa,
    required this.descriptionEn,
    required this.descriptionJa,
  });
}
