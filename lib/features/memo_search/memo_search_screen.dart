import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dao/workout_exercise_dao.dart';
import '../../data/localization/exercise_localization.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../utils/date_formatter.dart';
import '../../utils/feature_gate.dart';
import '../exercise_progress/exercise_progress_screen.dart';
import '../paywall/paywall_service.dart';
import '../paywall/models/paywall_reason.dart';

/// Model for memo search result
class MemoSearchResult {
  final String memo;
  final int exerciseId;
  final String exerciseName;
  final bool isCustomExercise;
  final DateTime date;

  MemoSearchResult({
    required this.memo,
    required this.exerciseId,
    required this.exerciseName,
    required this.isCustomExercise,
    required this.date,
  });
}

/// Provider for memo search
final memoSearchProvider = FutureProvider.autoDispose
    .family<List<MemoSearchResult>, String>((ref, keyword) async {
  if (keyword.isEmpty) {
    return [];
  }

  final exerciseDao = WorkoutExerciseDao();
  final results = await exerciseDao.searchMemos(keyword);

  return results.map((data) {
    final timestamp = data['date'] as int;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    return MemoSearchResult(
      memo: data['memo'] as String,
      exerciseId: data['exercise_id'] as int,
      exerciseName: data['exercise_name'] as String,
      isCustomExercise: (data['is_custom'] as int) == 1,
      date: date,
    );
  }).toList();
});

/// Memo search screen
class MemoSearchScreen extends ConsumerStatefulWidget {
  const MemoSearchScreen({super.key});

  @override
  ConsumerState<MemoSearchScreen> createState() => _MemoSearchScreenState();
}

class _MemoSearchScreenState extends ConsumerState<MemoSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus on search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword = value.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memoSearch),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: l10n.memoSearchPlaceholder,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
            ),
          ),

          // Results
          Expanded(
            child: _searchKeyword.isEmpty
                ? _buildEmptyState(l10n)
                : _buildSearchResults(l10n, currentLanguage),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.memoSearchHint,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n, String currentLanguage) {
    final searchResultsAsync = ref.watch(memoSearchProvider(_searchKeyword));

    return searchResultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.memoSearchNoResults,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildResultCard(context, result, currentLanguage);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Text(
          'Error: $error',
          style: TextStyle(color: Colors.red[400]),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    MemoSearchResult result,
    String currentLanguage,
  ) {
    final localizedExerciseName = ExerciseLocalization.getLocalizedName(
      englishName: result.exerciseName,
      language: currentLanguage,
      isStandard: !result.isCustomExercise,
    );
    final gate = ref.watch(featureGateProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: () async {
          // Check if charts are accessible
          if (!gate.canAccessCharts) {
            await showPaywall(context, reason: PaywallReason.chart);
            return;
          }

          // Navigate to exercise progress screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExerciseProgressScreen(
                exerciseId: result.exerciseId,
                exerciseName: localizedExerciseName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise name and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizedExerciseName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    DateFormatter.formatDate(result.date, currentLanguage),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Memo content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      result.memo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
