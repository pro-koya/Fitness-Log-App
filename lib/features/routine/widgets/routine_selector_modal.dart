import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/entities/routine_template_entity.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/routine_provider.dart';

/// Bottom sheet for selecting a routine to load into a workout
class RoutineSelectorModal extends ConsumerWidget {
  const RoutineSelectorModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final routinesAsync = ref.watch(routineListProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            l10n.routineLoadIntoWorkout,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        routinesAsync.when(
          data: (routines) {
            if (routines.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    l10n.routineEmptyHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return ListTile(
                  leading: const Icon(Icons.repeat),
                  title: Text(routine.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(routine),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Icon(Icons.error)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
