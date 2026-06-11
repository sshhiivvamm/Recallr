import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recallr/theme/recallr_colors.dart';

import '../../features/category/tag_provider.dart';

class ReAddcategory extends ConsumerStatefulWidget {
  const ReAddcategory({super.key});

  @override
  ConsumerState<ReAddcategory> createState() => _ReAddcategoryState();
}

class _ReAddcategoryState extends ConsumerState<ReAddcategory> {
  final _nameCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Color _selectedColor = const Color(0xFF38BDF8);
  IconData _selectedIcon = Icons.bookmark_rounded;
  bool _saving = false;

  static const _colors = [
    Color(0xFF38BDF8), // cyan
    Color(0xFFA78BFA), // purple
    Color(0xFF34D399), // green
    Color(0xFFFBBF24), // amber
    Color(0xFFF87171), // coral
    Color(0xFF60A5FA), // blue
    Color(0xFFF472B6), // pink
    Color(0xFF94A3B8), // slate
  ];

  static const _icons = [
    Icons.code_rounded,
    Icons.book_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.lightbulb_rounded,
    Icons.sports_esports_rounded,
    Icons.science_rounded,
    Icons.palette_rounded,
    Icons.music_note_rounded,
    Icons.trending_up_rounded,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _focusNode.requestFocus();
      return;
    }
    setState(() => _saving = true);

    final hex =
        '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    await ref.read(tagRepositoryProvider).addTag(
          name: name,
          colorHex: hex,
          icon: _selectedIcon.codePoint.toString(),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_rounded, size: 20, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'New Category',
          style: theme.titleLarge!.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _saving
                ? Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                        color: c.accent, strokeWidth: 2),
                  )
                : GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Save',
                        style: theme.labelMedium!.copyWith(
                          color: c.isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _selectedColor.withValues(alpha: 0.10),
                    _selectedColor.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _selectedColor.withValues(alpha: 0.25), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_selectedIcon,
                        size: 22, color: _selectedColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameCtrl.text.isEmpty
                              ? 'Category name'
                              : _nameCtrl.text,
                          style: theme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _nameCtrl.text.isEmpty
                                ? c.textHint
                                : c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '0 links',
                          style: theme.bodySmall!
                              .copyWith(color: c.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _label('NAME', c, theme),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focusNode.hasFocus ? c.accent : c.border,
                  width: _focusNode.hasFocus ? 1.0 : 0.5,
                ),
              ),
              child: TextField(
                controller: _nameCtrl,
                focusNode: _focusNode,
                onChanged: (_) => setState(() {}),
                style: theme.bodyMedium!.copyWith(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Design, Research, Reading…',
                  hintStyle:
                      theme.bodyMedium!.copyWith(color: c.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),

            const SizedBox(height: 28),

            _label('COLOR', c, theme),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colors.map((color) {
                final selected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                      border: Border.all(
                        color: selected ? c.background : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: selected
                        ? Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            _label('ICON', c, theme),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _icons.map((icon) {
                final selected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? _selectedColor.withValues(alpha: 0.15)
                          : c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _selectedColor : c.border,
                        width: selected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: selected ? _selectedColor : c.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, dynamic c, TextTheme theme) => Text(
        text,
        style: theme.labelSmall!.copyWith(
          color: c.textHint,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      );
}
