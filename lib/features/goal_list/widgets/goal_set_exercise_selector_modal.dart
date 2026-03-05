import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/dao/exercise_master_dao.dart';
import '../../../data/entities/exercise_master_entity.dart';
import '../../../data/localization/body_part_localization.dart';
import '../../../data/localization/exercise_localization.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/database_providers.dart';
import '../../../providers/settings_provider.dart';

/// 目標設定用の種目選択モーダル。部位絞り込み・曖昧検索付き。選択した種目を返す。
class GoalSetExerciseSelectorModal extends ConsumerStatefulWidget {
  const GoalSetExerciseSelectorModal({super.key});

  @override
  ConsumerState<GoalSetExerciseSelectorModal> createState() =>
      _GoalSetExerciseSelectorModalState();
}

class _GoalSetExerciseSelectorModalState
    extends ConsumerState<GoalSetExerciseSelectorModal> {
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
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        if (_selectedBodyPartFilter != null &&
            exercise.bodyPart != _selectedBodyPartFilter) {
          return false;
        }
        if (query.isEmpty) return true;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(currentLanguageProvider);
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.selectExerciseTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildBodyPartFilterChips(lang),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                                lang == 'ja'
                                    ? '該当する種目がありません'
                                    : 'No exercises match',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _filteredExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _filteredExercises[index];
                            final isStandard = exercise.isCustom == 0;
                            final displayName =
                                ExerciseLocalization.getLocalizedName(
                              englishName: exercise.name,
                              language: lang,
                              isStandard: isStandard,
                            );
                            return ListTile(
                              title: Text(displayName),
                              subtitle: exercise.bodyPart != null
                                  ? Text(
                                      BodyPartLocalization.getLocalizedName(
                                        exercise.bodyPart!,
                                        lang,
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    )
                                  : null,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                if (exercise.id != null) {
                                  Navigator.of(context).pop(exercise);
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPartFilterChips(String lang) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text(lang == 'ja' ? 'すべて' : 'All'),
            selected: _selectedBodyPartFilter == null,
            onSelected: (_) {
              setState(() {
                _selectedBodyPartFilter = null;
                _applyFilters();
              });
            },
          ),
          const SizedBox(width: 8),
          ...BodyPartLocalization.allBodyParts.map((bodyPartKey) {
            final localizedName =
                BodyPartLocalization.getLocalizedName(bodyPartKey, lang);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(localizedName),
                selected: _selectedBodyPartFilter == bodyPartKey,
                onSelected: (selected) {
                  setState(() {
                    _selectedBodyPartFilter =
                        selected ? bodyPartKey : null;
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
