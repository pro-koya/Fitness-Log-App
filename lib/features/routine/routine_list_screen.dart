import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/entities/routine_template_entity.dart';
import '../../data/localization/exercise_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_providers.dart';
import '../../providers/routine_provider.dart';
import '../../providers/settings_provider.dart';
import '../ads/widgets/banner_ad_widget.dart';
import 'routine_edit_screen.dart';

/// Screen showing all saved routines
class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final routinesAsync = ref.watch(routineListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.routineTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: routinesAsync.when(
                data: (routines) {
                  if (routines.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.routineEmptyHint,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _navigateToEdit(context, ref, null),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.routineCreateNew),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      return _RoutineTile(
                        routine: routines[index],
                        onTap: () => _navigateToEdit(context, ref, routines[index].id),
                        onDelete: () => _deleteRoutine(context, ref, routines[index]),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(error.toString()),
                ),
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
      floatingActionButton: routinesAsync.whenOrNull(
        data: (routines) => routines.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _navigateToEdit(context, ref, null),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Future<void> _navigateToEdit(BuildContext context, WidgetRef ref, int? routineId) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RoutineEditScreen(routineId: routineId),
      ),
    );
    // Always invalidate to pick up any changes (save or delete from edit screen)
    ref.invalidate(routineListProvider);
    if (routineId != null) {
      ref.invalidate(routineDetailProvider(routineId));
    }
  }

  Future<void> _deleteRoutine(
    BuildContext context,
    WidgetRef ref,
    RoutineTemplateEntity routine,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.routineDelete),
        content: Text(l10n.routineDeleteConfirm(routine.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.deleteButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dao = ref.read(routineTemplateDaoProvider);
      await dao.delete(routine.id!);
      ref.invalidate(routineListProvider);
    }
  }
}

class _RoutineTile extends ConsumerWidget {
  final RoutineTemplateEntity routine;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RoutineTile({
    required this.routine,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final routineDetailAsync = ref.watch(routineDetailProvider(routine.id!));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.repeat,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    routineDetailAsync.when(
                      data: (detail) {
                        final language = ref.watch(currentLanguageProvider);
                        final exerciseNames = detail.exercises
                            .take(3)
                            .map((e) => ExerciseLocalization.getLocalizedName(
                                  englishName: e.exercise.name,
                                  language: language,
                                  isStandard: e.exercise.isCustom == 0,
                                ))
                            .join(', ');
                        final suffix = detail.exercises.length > 3 ? '...' : '';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.routineExerciseCount(detail.exercises.length),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (exerciseNames.isNotEmpty)
                              Text(
                                '$exerciseNames$suffix',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        );
                      },
                      loading: () => Text(
                        '...',
                        style: theme.textTheme.bodySmall,
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                color: Colors.grey,
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
