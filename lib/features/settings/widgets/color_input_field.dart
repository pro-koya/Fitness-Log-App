import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/hex_color.dart';

/// カラーコード入力フィールド（リアルタイム更新対応）
class ColorInputField extends StatefulWidget {
  final String label;
  final Color currentColor;
  final String? initialHex;
  final ValueChanged<String> onColorChanged;

  const ColorInputField({
    super.key,
    required this.label,
    required this.currentColor,
    this.initialHex,
    required this.onColorChanged,
  });

  @override
  State<ColorInputField> createState() => _ColorInputFieldState();
}

class _ColorInputFieldState extends State<ColorInputField> {
  late TextEditingController _controller;
  String? _errorText;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialHex ?? HexColor.toHex(widget.currentColor),
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(ColorInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ユーザーが編集中でなければ、外部からの色変更を反映
    if (!_isEditing && oldWidget.currentColor != widget.currentColor) {
      final newHex = HexColor.toHex(widget.currentColor);
      if (_controller.text != newHex) {
        _controller.removeListener(_onTextChanged);
        _controller.text = newHex;
        _controller.addListener(_onTextChanged);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  /// テキスト変更時のリアルタイム処理
  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = null);
      return;
    }

    final normalizedHex = HexColor.normalize(text);
    if (HexColor.isValid(normalizedHex)) {
      setState(() => _errorText = null);
      // リアルタイムで色を更新
      widget.onColorChanged(normalizedHex);
    } else if (text.length >= 4) {
      // 4文字以上入力されたらエラー表示
      setState(() {
        _errorText = AppLocalizations.of(context)?.invalidHexColor ?? 'Invalid color';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        // カラープレビュー（タップでカラーピッカー表示）
        GestureDetector(
          onTap: () => _showEnhancedColorPicker(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: widget.currentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.colorize,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 入力フィールド
        Expanded(
          child: Focus(
            onFocusChange: (hasFocus) {
              setState(() => _isEditing = hasFocus);
            },
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: l10n.hexColorHint,
                errorText: _errorText,
                prefixText: '#',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.palette),
                  tooltip: l10n.colorPalette,
                  onPressed: () => _showEnhancedColorPicker(context),
                ),
              ),
              inputFormatters: [
                // #を除いた部分のみ入力可能に
                FilteringTextInputFormatter.allow(RegExp(r'[#A-Fa-f0-9]')),
                LengthLimitingTextInputFormatter(7), // #RRGGBB
              ],
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        ),
      ],
    );
  }

  /// 強化されたカラーピッカーダイアログ
  void _showEnhancedColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnhancedColorPickerSheet(
        currentColor: widget.currentColor,
        onColorSelected: (color) {
          final hex = HexColor.toHex(color);
          _controller.removeListener(_onTextChanged);
          _controller.text = hex;
          _controller.addListener(_onTextChanged);
          widget.onColorChanged(hex);
        },
      ),
    );
  }
}

/// 強化されたカラーピッカーシート
class _EnhancedColorPickerSheet extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const _EnhancedColorPickerSheet({
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  State<_EnhancedColorPickerSheet> createState() => _EnhancedColorPickerSheetState();
}

class _EnhancedColorPickerSheetState extends State<_EnhancedColorPickerSheet> {
  late Color _selectedColor;
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  /// ローカライズされたカテゴリー名を取得
  List<String> _getLocalizedCategoryNames(AppLocalizations? l10n) {
    return [
      l10n?.colorCategoryBasic ?? 'Basic',
      l10n?.colorCategoryRed ?? 'Red',
      l10n?.colorCategoryPink ?? 'Pink',
      l10n?.colorCategoryPurple ?? 'Purple',
      l10n?.colorCategoryBlue ?? 'Blue',
      l10n?.colorCategoryGreen ?? 'Green',
      l10n?.colorCategoryOrange ?? 'Orange',
      l10n?.colorCategoryBrown ?? 'Brown',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoryNames = _getLocalizedCategoryNames(l10n);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ヘッダー
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 現在の色プレビュー
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.selectColor ?? 'Select Color',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        HexColor.toHex(_selectedColor),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onColorSelected(_selectedColor);
                    Navigator.pop(context);
                  },
                  child: Text(l10n?.saveButton ?? 'Save'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // カテゴリータブ
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _colorCategoryColors.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedCategoryIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(categoryNames[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategoryIndex = index);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          // カラーグリッド
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _colorCategoryColors[_selectedCategoryIndex].length,
              itemBuilder: (context, index) {
                final color = _colorCategoryColors[_selectedCategoryIndex][index];
                final isSelected = _isSameColor(color, _selectedColor);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ),
          // 最近使った色（将来的な拡張用）
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  bool _isSameColor(Color a, Color b) {
    return (a.toARGB32() & 0xFFFFFF) == (b.toARGB32() & 0xFFFFFF);
  }
}

/// カラーカテゴリーの色一覧（インデックスはカテゴリー名のリストと対応）
const _colorCategoryColors = [
  // Basic
  [
    Color(0xFF000000), // Black
    Color(0xFF212121),
    Color(0xFF424242),
    Color(0xFF616161),
    Color(0xFF757575),
    Color(0xFF9E9E9E),
    Color(0xFFBDBDBD),
    Color(0xFFE0E0E0),
    Color(0xFFEEEEEE),
    Color(0xFFF5F5F5),
    Color(0xFFFFFFFF), // White
    Color(0xFFFFEBEE),
  ],
  // Red
  [
    Color(0xFFFFEBEE),
    Color(0xFFFFCDD2),
    Color(0xFFEF9A9A),
    Color(0xFFE57373),
    Color(0xFFEF5350),
    Color(0xFFF44336),
    Color(0xFFE53935),
    Color(0xFFD32F2F),
    Color(0xFFC62828),
    Color(0xFFB71C1C),
    Color(0xFFFF8A80),
    Color(0xFFFF5252),
  ],
  // Pink
  [
    Color(0xFFFCE4EC),
    Color(0xFFF8BBD0),
    Color(0xFFF48FB1),
    Color(0xFFF06292),
    Color(0xFFEC407A),
    Color(0xFFE91E63),
    Color(0xFFD81B60),
    Color(0xFFC2185B),
    Color(0xFFAD1457),
    Color(0xFF880E4F),
    Color(0xFFFF80AB),
    Color(0xFFFF4081),
  ],
  // Purple
  [
    Color(0xFFF3E5F5),
    Color(0xFFE1BEE7),
    Color(0xFFCE93D8),
    Color(0xFFBA68C8),
    Color(0xFFAB47BC),
    Color(0xFF9C27B0),
    Color(0xFF8E24AA),
    Color(0xFF7B1FA2),
    Color(0xFF6A1B9A),
    Color(0xFF4A148C),
    Color(0xFFEA80FC),
    Color(0xFFE040FB),
  ],
  // Blue
  [
    Color(0xFFE3F2FD),
    Color(0xFFBBDEFB),
    Color(0xFF90CAF9),
    Color(0xFF64B5F6),
    Color(0xFF42A5F5),
    Color(0xFF2196F3),
    Color(0xFF1E88E5),
    Color(0xFF1976D2),
    Color(0xFF1565C0),
    Color(0xFF0D47A1),
    Color(0xFF82B1FF),
    Color(0xFF448AFF),
  ],
  // Green
  [
    Color(0xFFE8F5E9),
    Color(0xFFC8E6C9),
    Color(0xFFA5D6A7),
    Color(0xFF81C784),
    Color(0xFF66BB6A),
    Color(0xFF4CAF50),
    Color(0xFF43A047),
    Color(0xFF388E3C),
    Color(0xFF2E7D32),
    Color(0xFF1B5E20),
    Color(0xFFB9F6CA),
    Color(0xFF69F0AE),
  ],
  // Orange
  [
    Color(0xFFFFF3E0),
    Color(0xFFFFE0B2),
    Color(0xFFFFCC80),
    Color(0xFFFFB74D),
    Color(0xFFFFA726),
    Color(0xFFFF9800),
    Color(0xFFFB8C00),
    Color(0xFFF57C00),
    Color(0xFFEF6C00),
    Color(0xFFE65100),
    Color(0xFFFFD180),
    Color(0xFFFFAB40),
  ],
  // Brown
  [
    Color(0xFFEFEBE9),
    Color(0xFFD7CCC8),
    Color(0xFFBCAAA4),
    Color(0xFFA1887F),
    Color(0xFF8D6E63),
    Color(0xFF795548),
    Color(0xFF6D4C41),
    Color(0xFF5D4037),
    Color(0xFF4E342E),
    Color(0xFF3E2723),
    Color(0xFF607D8B),
    Color(0xFF455A64),
  ],
];
