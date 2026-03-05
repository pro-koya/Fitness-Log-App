import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../ads/widgets/banner_ad_widget.dart';
import '../exercise_list/exercise_list_screen.dart';
import '../goal_list/goal_list_screen.dart';
import '../history/all_records_screen.dart';
import '../memo_search/memo_search_screen.dart';
import '../routine/routine_list_screen.dart';

/// フッター「一覧」タブ用。種目一覧・目標一覧・全ての記録一覧・メモ検索の導線を表示。
class ListMenuTabScreen extends StatelessWidget {
  const ListMenuTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        l10n.navListLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.listMenuSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 32),
                      _ListTile(
                        icon: Icons.repeat,
                        title: l10n.routineTitle,
                        subtitle: l10n.listMenuRoutineDescription,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RoutineListScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ListTile(
                        icon: Icons.fitness_center,
                        title: l10n.exerciseListTooltip,
                        subtitle: l10n.listMenuExerciseListDescription,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ExerciseListScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ListTile(
                        icon: Icons.flag,
                        title: l10n.goalListTitle,
                        subtitle: l10n.listMenuGoalListDescription,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const GoalListScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ListTile(
                        icon: Icons.list_alt,
                        title: l10n.allRecordsTitle,
                        subtitle: l10n.listMenuAllRecordsDescription,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AllRecordsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ListTile(
                        icon: Icons.search,
                        title: l10n.memoSearch,
                        subtitle: l10n.listMenuMemoSearchDescription,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MemoSearchScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            // 広告をナビ下部に固定（体重・履歴画面と同じ構成）
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
