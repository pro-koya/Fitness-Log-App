import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// 復元で使えるCSVの列順・列名・説明を表示するボトムシート
class CsvFormatGuideSheet extends StatelessWidget {
  const CsvFormatGuideSheet({super.key});

  static const List<String> _columnNames = [
    'session_date',
    'session_started_at',
    'exercise_name',
    'body_part',
    'set_number',
    'weight_kg',
    'weight_lb',
    'reps',
    'duration_seconds',
    'distance_meters',
    'memo',
  ];

  static const List<bool> _required = [
    true,
    false,
    true,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final descriptions = [
      l10n.csvGuideColSessionDate,
      l10n.csvGuideColSessionStartedAt,
      l10n.csvGuideColExerciseName,
      l10n.csvGuideColBodyPart,
      l10n.csvGuideColSetNumber,
      l10n.csvGuideColWeightKg,
      l10n.csvGuideColWeightLb,
      l10n.csvGuideColReps,
      l10n.csvGuideColDurationSeconds,
      l10n.csvGuideColDistanceMeters,
      l10n.csvGuideColMemo,
    ];

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.table_chart,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.csvGuideTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.csvGuideIntro,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 列一覧テーブル
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.view_list, size: 20, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                '列の順番と内容',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(_columnNames.length, (i) {
                            final isEven = i.isEven;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isEven
                                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outline.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _columnNames[i],
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _required[i]
                                                    ? colorScheme.errorContainer.withValues(alpha: 0.7)
                                                    : colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _required[i] ? l10n.csvGuideRequired : l10n.csvGuideOptional,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: _required[i]
                                                      ? colorScheme.onErrorContainer
                                                      : colorScheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          descriptions[i],
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // サンプルCSV
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.code, size: 20, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                l10n.csvGuideSampleTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: SelectableText(
                              'session_date,session_started_at,exercise_name,body_part,set_number,weight_kg,weight_lb,reps,duration_seconds,distance_meters,memo\n'
                              '2024-01-15,2024-01-15T19:30:00.000,ベンチプレス,胸,1,60,132.3,10,,,\n'
                              '2024-01-15,2024-01-15T19:30:00.000,ベンチプレス,胸,2,62,136.7,8,,,',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                height: 1.5,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 注意事項
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: colorScheme.tertiary),
                              const SizedBox(width: 8),
                              Text(
                                l10n.csvGuideNotesTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _NoteRow(icon: Icons.font_download, text: l10n.csvGuideNoteEncoding),
                          const SizedBox(height: 8),
                          _NoteRow(icon: Icons.calendar_today, text: l10n.csvGuideNoteDate),
                          const SizedBox(height: 8),
                          _NoteRow(icon: Icons.format_quote, text: l10n.csvGuideNoteQuotes),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.confirmButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.tertiary.withValues(alpha: 0.9)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
