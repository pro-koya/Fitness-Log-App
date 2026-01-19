import 'package:flutter/material.dart';

/// テーマのプレビューを表示するカード
class ThemePreviewCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const ThemePreviewCard({
    super.key,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー風のプレビュー
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sample Header',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ボタンプレビュー
            Row(
              children: [
                // Primary button
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: () {},
                    child: const Text('Primary'),
                  ),
                ),
                const SizedBox(width: 12),
                // Secondary button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.secondary,
                      side: BorderSide(color: colorScheme.secondary),
                    ),
                    onPressed: () {},
                    child: const Text('Secondary'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // カラーパレット表示
            Row(
              children: [
                _buildColorChip('Primary', colorScheme.primary),
                const SizedBox(width: 8),
                _buildColorChip('Secondary', colorScheme.secondary),
                const SizedBox(width: 8),
                _buildColorChip('Surface', colorScheme.surface),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
