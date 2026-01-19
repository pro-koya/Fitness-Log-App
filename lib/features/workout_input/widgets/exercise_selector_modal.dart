import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/dao/exercise_master_dao.dart';
import '../../../data/entities/exercise_master_entity.dart';
import '../../../data/localization/exercise_localization.dart';
import '../../../data/localization/body_part_localization.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';

/// Exercise selector modal with search and custom exercise support
class ExerciseSelectorModal extends ConsumerStatefulWidget {
  final ExerciseMasterDao exerciseMasterDao;

  const ExerciseSelectorModal({
    super.key,
    required this.exerciseMasterDao,
  });

  @override
  ConsumerState<ExerciseSelectorModal> createState() =>
      _ExerciseSelectorModalState();
}

class _ExerciseSelectorModalState
    extends ConsumerState<ExerciseSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  List<ExerciseMasterEntity> _allExercises = [];
  List<ExerciseMasterEntity> _filteredExercises = [];
  bool _isLoading = true;
  String? _selectedBodyPartFilter; // null = "All"

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);

    try {
      final exercises = await widget.exerciseMasterDao.getAllExercises();
      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        // Body part filter
        if (_selectedBodyPartFilter != null &&
            exercise.bodyPart != _selectedBodyPartFilter) {
          return false;
        }

        // Search filter
        if (query.isEmpty) {
          return true;
        }

        final isStandard = exercise.isCustom == 0;
        final matchesName = ExerciseLocalization.matchesSearch(
          exercise.name,
          query,
          isStandard,
        );
        final bodyPart = exercise.bodyPart?.toLowerCase() ?? '';
        return matchesName || bodyPart.contains(query);
      }).toList();
    });
  }

  Future<void> _showAddCustomExerciseDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.read(currentLanguageProvider);
    final nameController = TextEditingController();
    String selectedBodyPart = BodyPartLocalization.other;
    String selectedRecordType = 'reps';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              minWidth: 320,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    l10n.customExerciseDialogTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),

                  // Exercise name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.exerciseNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    onTapOutside: (_) {
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Body part selection
                  Text(
                    currentLanguage == 'ja' ? '部位 *' : 'Body Part *',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedBodyPart,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: BodyPartLocalization.allBodyParts.map((bodyPartKey) {
                      final localizedName = BodyPartLocalization.getLocalizedName(
                        bodyPartKey,
                        currentLanguage,
                      );
                      return DropdownMenuItem(
                        value: bodyPartKey,
                        child: Text(localizedName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedBodyPart = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Record type selection (hidden for cardio)
                  if (selectedBodyPart != BodyPartLocalization.cardio) ...[
                    Text(
                      currentLanguage == 'ja' ? '記録タイプ *' : 'Record Type *',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'reps',
                          label: Text(currentLanguage == 'ja' ? '回数' : 'Reps'),
                          icon: const Icon(Icons.repeat, size: 18),
                        ),
                        ButtonSegment(
                          value: 'time',
                          label: Text(currentLanguage == 'ja' ? '時間' : 'Time'),
                          icon: const Icon(Icons.timer, size: 18),
                        ),
                      ],
                      selected: {selectedRecordType},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() {
                          selectedRecordType = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedRecordType == 'reps'
                          ? (currentLanguage == 'ja'
                              ? '例：ベンチプレス、スクワット'
                              : 'e.g., Bench Press, Squat')
                          : (currentLanguage == 'ja'
                              ? '例：プランク、ウォールシット'
                              : 'e.g., Plank, Wall Sit'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else ...[
                    // Cardio info text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_run,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentLanguage == 'ja'
                                  ? '有酸素運動は時間と距離を記録します'
                                  : 'Cardio tracks time and distance',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancelButton),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            // Use 'cardio' record type for cardio body part
                            final recordType = selectedBodyPart == BodyPartLocalization.cardio
                                ? 'cardio'
                                : selectedRecordType;
                            Navigator.of(context).pop({
                              'name': name,
                              'bodyPart': selectedBodyPart,
                              'recordType': recordType,
                            });
                          }
                        },
                        child: Text(l10n.addButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      await _addCustomExercise(
        result['name']!,
        result['bodyPart']!,
        result['recordType'] ?? 'reps',
      );
    }
  }

  Future<void> _addCustomExercise(
    String name,
    String bodyPart,
    String recordType,
  ) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final customExercise = ExerciseMasterEntity(
        name: name,
        bodyPart: bodyPart,
        isCustom: 1,
        recordType: recordType,
        createdAt: now,
        updatedAt: now,
      );

      final id = await widget.exerciseMasterDao.insertExercise(customExercise);
      final insertedExercise = customExercise.copyWith(id: id);

      // Reload exercises to include the new custom exercise
      await _loadExercises();

      // Auto-select the newly created exercise
      if (mounted) {
        Navigator.of(context).pop(insertedExercise.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding custom exercise: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteCustomExerciseDialog(
    ExerciseMasterEntity exercise,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCustomExerciseDialogTitle),
        content: Text(
          l10n.deleteCustomExerciseDialogMessage(exercise.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteCustomExercise(exercise);
    }
  }

  Future<void> _deleteCustomExercise(ExerciseMasterEntity exercise) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await widget.exerciseMasterDao.deleteExercise(exercise.id!);

      // Reload exercises after deletion
      await _loadExercises();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exerciseDeleted(exercise.name)),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting exercise: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.selectExerciseTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),

            // Body part filter chips
            _buildBodyPartFilterChips(currentLanguage),

            // Search box
            Padding(
              padding: const EdgeInsets.all(16.0).copyWith(top: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchExercisePlaceholder,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Exercise list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredExercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No exercises found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _filteredExercises[index];
                            final isStandard = exercise.isCustom == 0;
                            final displayName = ExerciseLocalization.getLocalizedName(
                              englishName: exercise.name,
                              language: currentLanguage,
                              isStandard: isStandard,
                            );
                            return ListTile(
                              title: Text(displayName),
                              subtitle: exercise.bodyPart != null
                                  ? Text(
                                      BodyPartLocalization.getLocalizedName(
                                        exercise.bodyPart!,
                                        currentLanguage,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  : null,
                              trailing: exercise.isCustom == 1
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Chip(
                                          label: const Text(
                                            'Custom',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () {
                                            _showDeleteCustomExerciseDialog(exercise);
                                          },
                                          color: Colors.grey.shade600,
                                          tooltip: 'Delete custom exercise',
                                        ),
                                      ],
                                    )
                                  : null,
                              onTap: () {
                                Navigator.of(context).pop(exercise.id);
                              },
                            );
                          },
                        ),
            ),

            // Add custom exercise button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAddCustomExerciseDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addCustomExerciseButton),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPartFilterChips(String currentLanguage) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedBodyPartFilter == null,
              onSelected: (selected) {
                setState(() {
                  _selectedBodyPartFilter = null;
                  _applyFilters();
                });
              },
            ),
          ),

          // Body part chips
          ...BodyPartLocalization.allBodyParts.map((bodyPartKey) {
            final localizedName = BodyPartLocalization.getLocalizedName(
              bodyPartKey,
              currentLanguage,
            );
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(localizedName),
                selected: _selectedBodyPartFilter == bodyPartKey,
                onSelected: (selected) {
                  setState(() {
                    _selectedBodyPartFilter = selected ? bodyPartKey : null;
                    _applyFilters();
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
