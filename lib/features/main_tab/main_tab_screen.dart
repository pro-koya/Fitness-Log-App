import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../body_weight/body_weight_screen.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'list_menu_tab_screen.dart';
import 'widgets/quick_action_rail.dart';

/// ヘッダーなし・フッター5タブ（記録・履歴・一覧・体重・設定）。
/// 右端: 開閉可能な縦バー（タイマー・記録開始・再開・ルーティンから開始）。
const double _kBottomNavHeight = 80;

class MainTabScreen extends ConsumerStatefulWidget {
  const MainTabScreen({super.key});

  @override
  ConsumerState<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends ConsumerState<MainTabScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              HomeScreen(isEmbeddedInTab: true),
              HistoryScreen(isEmbeddedInTab: true),
              ListMenuTabScreen(),
              BodyWeightScreen(isEmbeddedInTab: true),
              SettingsScreen(isEmbeddedInTab: true),
            ],
          ),
          // 右下: 開閉式クイックアクション縦バー（親指で操作しやすく、広告・ナビと被らない位置）
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: _kBottomNavHeight + bottomPadding + 12,
            child: Align(
              alignment: Alignment.bottomRight,
              child: QuickActionRail(bottomOffset: bottomPadding),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.edit_note_outlined),
            selectedIcon: const Icon(Icons.edit_note),
            label: l10n.navHomeLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.navHistoryLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_outlined),
            selectedIcon: const Icon(Icons.list),
            label: l10n.navListLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_weight_outlined),
            selectedIcon: const Icon(Icons.monitor_weight),
            label: l10n.navWeightLabel,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettingsLabel,
          ),
        ],
      ),
    );
  }
}
