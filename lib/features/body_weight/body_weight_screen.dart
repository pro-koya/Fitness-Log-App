import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dao/body_weight_dao.dart';
import '../../data/entities/body_weight_entity.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../utils/chart_aggregation.dart';
import '../../utils/date_formatter.dart';
import '../exercise_progress/providers/exercise_progress_provider.dart';
import '../exercise_progress/widgets/progress_chart_widget.dart';
import '../workout_input/widgets/timer_icon_button.dart';
import '../ads/widgets/banner_ad_widget.dart';
import 'providers/body_weight_provider.dart';

/// Body weight tracking screen.
/// When [isEmbeddedInTab] is true, no AppBar (used as tab of MainTabScreen).
class BodyWeightScreen extends ConsumerStatefulWidget {
  const BodyWeightScreen({super.key, this.isEmbeddedInTab = false});

  final bool isEmbeddedInTab;

  @override
  ConsumerState<BodyWeightScreen> createState() => _BodyWeightScreenState();
}

class _BodyWeightScreenState extends ConsumerState<BodyWeightScreen> {
  final _weightController = TextEditingController();
  final _memoController = TextEditingController();
  int? _existingRecordId;

  @override
  void initState() {
    super.initState();
    _loadTodayRecord();
  }

  Future<void> _loadTodayRecord() async {
    final dao = BodyWeightDao();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final timestamp = startOfDay.millisecondsSinceEpoch ~/ 1000;
    final existing = await dao.getByDate(timestamp);

    if (existing != null && mounted) {
      final settings = await ref.read(settingsProvider.future);
      final unit = settings?.unit ?? 'kg';
      setState(() {
        _existingRecordId = existing.id;
        _weightController.text = existing.getWeight(unit).toStringAsFixed(1);
        _memoController.text = existing.memo ?? '';
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final currentUnit = ref.watch(currentUnitProvider);

    return Scaffold(
      appBar: widget.isEmbeddedInTab
          ? null
          : AppBar(
              title: Text(l10n.bodyWeightTitle),
              actions: const [TimerIconButton()],
            ),
      body: SafeArea(
        top: widget.isEmbeddedInTab,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Weight input card
                  _buildInputCard(l10n, currentUnit),
                  const SizedBox(height: 16),

                  // Period filter chips
                  _buildPeriodFilterChips(),
                  const SizedBox(height: 16),

                  // Chart
                  _buildChart(currentUnit),
                  const SizedBox(height: 24),

                  // Summary stats
                  _buildSummary(l10n, currentUnit),
                  const SizedBox(height: 24),

                  // Monthly insight
                  _buildMonthlyInsight(l10n, currentUnit, currentLanguage),
                  const SizedBox(height: 24),

                  // History
                  _buildHistory(l10n, currentUnit, currentLanguage),
                ],
              ),
            ),
          ),
          const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(AppLocalizations l10n, String unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.bodyWeightLabel,
                      suffixText: unit,
                      border: const OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _saveWeight,
                  child: Text(_existingRecordId != null
                      ? l10n.saveButton
                      : l10n.saveButton),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              decoration: InputDecoration(
                hintText: l10n.bodyWeightMemoHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilterChips() {
    final period = ref.watch(bodyWeightPeriodProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ProgressPeriod.values.map((p) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(p.label),
              selected: period == p,
              onSelected: (selected) {
                if (selected) {
                  ref.read(bodyWeightPeriodProvider.notifier).state = p;
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(String unit) {
    final chartAsync = ref.watch(bodyWeightChartProvider);

    return chartAsync.when(
      data: (dataPoints) {
        if (dataPoints.isEmpty) {
          return const SizedBox.shrink();
        }
        final period = ref.watch(bodyWeightPeriodProvider);
        return ProgressChartWidget(
          dataPoints: dataPoints,
          unit: unit,
          chartMode: 'weight',
          xAxisBucket: bodyWeightBucketForPeriod(period),
        );
      },
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSummary(AppLocalizations l10n, String unit) {
    final summaryAsync = ref.watch(bodyWeightSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        if (summary.totalRecords == 0) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bodyWeightSummary,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow(l10n.bodyWeightTotalRecords, '${summary.totalRecords}'),
                if (summary.currentWeight != null)
                  _buildStatRow(l10n.bodyWeightCurrentWeight,
                      '${summary.currentWeight!.toStringAsFixed(1)} $unit'),
                if (summary.startingWeight != null)
                  _buildStatRow(l10n.bodyWeightStartingWeight,
                      '${summary.startingWeight!.toStringAsFixed(1)} $unit'),
                if (summary.totalChange != null)
                  _buildStatRow(
                    l10n.bodyWeightTotalChange,
                    '${summary.totalChange! >= 0 ? '+' : ''}${summary.totalChange!.toStringAsFixed(1)} $unit',
                    valueColor: summary.totalChange! < 0 ? Colors.green : (summary.totalChange! > 0 ? Colors.red : null),
                  ),
                if (summary.minWeight != null)
                  _buildStatRow(l10n.bodyWeightMinWeight,
                      '${summary.minWeight!.toStringAsFixed(1)} $unit'),
                if (summary.maxWeight != null)
                  _buildStatRow(l10n.bodyWeightMaxWeight,
                      '${summary.maxWeight!.toStringAsFixed(1)} $unit'),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyInsight(AppLocalizations l10n, String unit, String language) {
    final summaryAsync = ref.watch(bodyWeightSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        if (summary.monthlyWorkoutCount == 0 && summary.monthlyWeightChange == null) {
          return const SizedBox.shrink();
        }

        String insightText;
        if (summary.monthlyWeightChange != null) {
          final changeStr = '${summary.monthlyWeightChange! >= 0 ? '+' : ''}${summary.monthlyWeightChange!.toStringAsFixed(1)} $unit';
          insightText = l10n.bodyWeightInsightMessage(
            summary.monthlyWorkoutCount,
            changeStr,
          );
        } else {
          insightText = l10n.bodyWeightInsightNoData(summary.monthlyWorkoutCount);
        }

        final colorScheme = Theme.of(context).colorScheme;
        return Card(
          color: colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.bodyWeightInsightTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  insightText,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildHistory(AppLocalizations l10n, String unit, String language) {
    final historyAsync = ref.watch(bodyWeightHistoryProvider);

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.bodyWeightNoData,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bodyWeightHistory,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...records.map((record) {
              final date = DateTime.fromMillisecondsSinceEpoch(record.recordedAt * 1000);
              final dateStr = DateFormatter.formatDate(date, language);
              final weight = record.getWeight(unit);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${weight.toStringAsFixed(1)} $unit',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: record.memo != null && record.memo!.isNotEmpty
                    ? Text(record.memo!)
                    : null,
                trailing: Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                onLongPress: () => _confirmDelete(record, l10n),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _saveWeight() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) return;

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) return;

    // l10n を await の前に取得する（use_build_context_synchronously 対策）
    final l10n = AppLocalizations.of(context)!;

    final settings = await ref.read(settingsProvider.future);
    final unit = settings?.unit ?? 'kg';

    // Convert to both units
    double weightKg;
    double weightLb;
    if (unit == 'kg') {
      weightKg = weight;
      weightLb = weight * 2.20462;
    } else {
      weightLb = weight;
      weightKg = weight / 2.20462;
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final recordedAt = startOfDay.millisecondsSinceEpoch ~/ 1000;
    final memo = _memoController.text.trim().isEmpty ? null : _memoController.text.trim();

    final dao = BodyWeightDao();;

    if (_existingRecordId != null) {
      // Update
      await dao.update(BodyWeightEntity(
        id: _existingRecordId,
        weightKg: weightKg,
        weightLb: weightLb,
        memo: memo,
        recordedAt: recordedAt,
        createdAt: 0, // Will be preserved by update
        updatedAt: 0,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bodyWeightUpdated), backgroundColor: Colors.green),
        );
      }
    } else {
      // Insert
      final id = await dao.insert(BodyWeightEntity(
        weightKg: weightKg,
        weightLb: weightLb,
        memo: memo,
        recordedAt: recordedAt,
        createdAt: 0,
        updatedAt: 0,
      ));
      setState(() {
        _existingRecordId = id;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bodyWeightSaved), backgroundColor: Colors.green),
        );
      }
    }

    // Refresh providers
    ref.invalidate(bodyWeightChartProvider);
    ref.invalidate(bodyWeightSummaryProvider);
    ref.invalidate(bodyWeightHistoryProvider);
    ref.invalidate(latestBodyWeightProvider);
    ref.invalidate(previousBodyWeightProvider);

    // Dismiss keyboard
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }

  Future<void> _confirmDelete(BodyWeightEntity record, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bodyWeightDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteButton, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dao = BodyWeightDao();
      await dao.delete(record.id!);

      // If deleting today's record, clear the input
      if (record.id == _existingRecordId) {
        setState(() {
          _existingRecordId = null;
          _weightController.clear();
          _memoController.clear();
        });
      }

      // Refresh providers
      ref.invalidate(bodyWeightChartProvider);
      ref.invalidate(bodyWeightSummaryProvider);
      ref.invalidate(bodyWeightHistoryProvider);
      ref.invalidate(latestBodyWeightProvider);
      ref.invalidate(previousBodyWeightProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bodyWeightDeleted), backgroundColor: Colors.green),
        );
      }
    }
  }
}
