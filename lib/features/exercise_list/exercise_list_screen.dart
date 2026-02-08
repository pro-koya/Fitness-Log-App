import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/entities/exercise_master_entity.dart';
import '../../data/localization/exercise_localization.dart';
import '../../data/localization/body_part_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/database_providers.dart';
import '../../providers/settings_provider.dart';
import '../../utils/feature_gate.dart';
import '../exercise_progress/exercise_progress_screen.dart';
import '../paywall/paywall_service.dart';
import '../paywall/models/paywall_reason.dart';

/// Exercise list screen - shows all exercises with ability to view progress
class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ExerciseMasterEntity> _allExercises = [];
  List<ExerciseMasterEntity> _filteredExercises = [];
  bool _isLoading = true;
  String? _selectedBodyPartFilter;

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
      final dao = ref.read(exerciseMasterDaoProvider);
      final exercises = await dao.getAllExercises();
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

  IconData _getBodyPartIcon(String? bodyPart) {
    switch (bodyPart) {
      case 'chest':
        // Bench Press - weights/dumbbells
        return Icons.fitness_center;
      case 'back':
        // Pull-up - person with arms up (like hanging from bar)
        return Icons.accessibility_new;
      case 'legs':
        // Squat - person in squatting position
        return Icons.sports_martial_arts;
      case 'shoulders':
        // Shoulder Press - person with arm raised overhead
        return Icons.sports_handball;
      case 'biceps':
        // Arm Curl - person doing arm curl motion
        return Icons.sports_gymnastics;
      case 'triceps':
        // Cable Press Down - person pushing down
        return Icons.sports_kabaddi;
      case 'abs':
        // Sit-up - person lying down doing sit-up
        return Icons.airline_seat_flat_angled;
      case 'cardio':
        // Running
        return Icons.directions_run;
      case 'other':
        // Meditation
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  Future<void> _navigateToProgress(ExerciseMasterEntity exercise) async {
    final gate = ref.read(featureGateProvider);
    final currentLanguage = ref.read(currentLanguageProvider);

    // Check feature gate for charts
    if (!gate.canAccessCharts) {
      await showPaywall(context, reason: PaywallReason.chart);
      return;
    }

    if (!mounted) return;

    final isStandard = exercise.isCustom == 0;
    final displayName = ExerciseLocalization.getLocalizedName(
      englishName: exercise.name,
      language: currentLanguage,
      isStandard: isStandard,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseProgressScreen(
          exerciseId: exercise.id!,
          exerciseName: displayName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentLanguage == 'ja' ? '種目一覧' : 'Exercises'),
      ),
      body: Column(
        children: [
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
                              currentLanguage == 'ja'
                                  ? '種目が見つかりません'
                                  : 'No exercises found',
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
                          return _buildExerciseListTile(
                            exercise,
                            currentLanguage,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseListTile(
    ExerciseMasterEntity exercise,
    String currentLanguage,
  ) {
    final isStandard = exercise.isCustom == 0;
    final displayName = ExerciseLocalization.getLocalizedName(
      englishName: exercise.name,
      language: currentLanguage,
      isStandard: isStandard,
    );
    final bodyPartName = exercise.bodyPart != null
        ? BodyPartLocalization.getLocalizedName(
            exercise.bodyPart!,
            currentLanguage,
          )
        : null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _getBodyPartIcon(exercise.bodyPart),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(displayName),
      subtitle: bodyPartName != null
          ? Text(
              bodyPartName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (exercise.isCustom == 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text(
                  'Custom',
                  style: TextStyle(fontSize: 11),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 0,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
      onTap: () => _navigateToProgress(exercise),
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
              label: Text(currentLanguage == 'ja' ? 'すべて' : 'All'),
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
