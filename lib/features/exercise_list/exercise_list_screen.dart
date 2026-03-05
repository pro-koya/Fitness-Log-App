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

/// 種目一覧画面。部位フィルター・検索・カード一覧。テーマ適用・レスポンシブ対応。
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

  static const double _maxContentWidth = 560;
  static const double _paddingPhone = 16;
  static const double _paddingWide = 24;

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

  IconData _getBodyPartIcon(String? bodyPart) {
    switch (bodyPart) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.accessibility_new;
      case 'legs':
        return Icons.sports_martial_arts;
      case 'shoulders':
        return Icons.sports_handball;
      case 'biceps':
        return Icons.sports_gymnastics;
      case 'triceps':
        return Icons.sports_kabaddi;
      case 'abs':
        return Icons.airline_seat_flat_angled;
      case 'cardio':
        return Icons.directions_run;
      case 'other':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  Future<void> _navigateToProgress(ExerciseMasterEntity exercise) async {
    final gate = ref.read(featureGateProvider);
    final currentLanguage = ref.read(currentLanguageProvider);

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

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > _maxContentWidth + _paddingWide * 2
        ? _paddingWide
        : _paddingPhone;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final padding = _horizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exerciseListTooltip),
        scrolledUnderElevation: 4,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Column(
            children: [
              // 部位フィルター
              _buildBodyPartFilterChips(context, currentLanguage, colorScheme, theme),

              // 検索
              Padding(
                padding: EdgeInsets.fromLTRB(padding, 8, padding, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchExercisePlaceholder,
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              // 一覧
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredExercises.isEmpty
                        ? _buildEmptyState(context, theme, colorScheme, currentLanguage)
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                            itemCount: _filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = _filteredExercises[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildExerciseCard(
                                  context,
                                  exercise,
                                  currentLanguage,
                                  colorScheme,
                                  theme,
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String currentLanguage,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              currentLanguage == 'ja' ? '種目が見つかりません' : 'No exercises found',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    ExerciseMasterEntity exercise,
    String currentLanguage,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isStandard = exercise.isCustom == 0;
    final displayName = ExerciseLocalization.getLocalizedName(
      englishName: exercise.name,
      language: currentLanguage,
      isStandard: isStandard,
    );
    final bodyPartName = exercise.bodyPart != null
        ? BodyPartLocalization.getLocalizedName(exercise.bodyPart!, currentLanguage)
        : null;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToProgress(exercise),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getBodyPartIcon(exercise.bodyPart),
                  color: colorScheme.onPrimaryContainer,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (bodyPartName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        bodyPartName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (exercise.isCustom == 1)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentLanguage == 'ja' ? 'カスタム' : 'Custom',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyPartFilterChips(
    BuildContext context,
    String currentLanguage,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final padding = _horizontalPadding(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(currentLanguage == 'ja' ? 'すべて' : 'All'),
              selected: _selectedBodyPartFilter == null,
              onSelected: (_) {
                setState(() {
                  _selectedBodyPartFilter = null;
                  _applyFilters();
                });
              },
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: _selectedBodyPartFilter == null
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ),
          ...BodyPartLocalization.allBodyParts.map((bodyPartKey) {
            final localizedName =
                BodyPartLocalization.getLocalizedName(bodyPartKey, currentLanguage);
            final isSelected = _selectedBodyPartFilter == bodyPartKey;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(localizedName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedBodyPartFilter = selected ? bodyPartKey : null;
                    _applyFilters();
                  });
                },
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.onPrimaryContainer,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
