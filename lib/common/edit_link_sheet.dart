import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recallr/theme/recallr_colors.dart';

import '../core/features/category/tag_list_provider.dart';
import '../core/features/collections/collection_provider.dart';
import '../core/repositrories/link_providers/link_repository_provider.dart';
import '../data/models/Link/link_model.dart';
import '../data/models/collection_model.dart';

Future<void> showEditLink(
  BuildContext context,
  WidgetRef ref,
  LinkModel link,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => EditLinkSheet(link: link),
  );
}

class EditLinkSheet extends ConsumerStatefulWidget {
  final LinkModel link;
  const EditLinkSheet({super.key, required this.link});

  @override
  ConsumerState<EditLinkSheet> createState() => EditLinkSheetState();
}

class EditLinkSheetState extends ConsumerState<EditLinkSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  Set<int> _selectedTagIds = {};
  FolderModel? _selectedFolder;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.link.title);
    _notesCtrl = TextEditingController(text: widget.link.notes ?? '');
    _init();
  }

  Future<void> _init() async {
    await widget.link.tags.load();
    await widget.link.folder.load();
    if (mounted) {
      setState(() {
        _selectedTagIds = widget.link.tags.map((t) => t.id).toSet();
        _selectedFolder = widget.link.folder.value;
        _ready = true;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final repo = ref.read(linkRepositoryProvider);
    final allTags = ref.read(tagListProvider).value ?? [];
    final selectedTags =
        allTags.where((t) => _selectedTagIds.contains(t.id)).toList();

    await repo.updateLink(
      widget.link.id,
      title: _titleCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    await repo.setTags(widget.link.id, selectedTags);
    await repo.setFolder(widget.link.id, _selectedFolder);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: c.border, width: 0.5),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: c.borderSoft,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: c.textSecondary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Edit Link',
                    style: theme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                _saving
                    ? Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(8),
                        child:
                            CircularProgressIndicator(color: c.accent, strokeWidth: 2),
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
              ],
            ),
          ),

          Divider(
              color: c.border,
              height: 24,
              thickness: 0.5,
              indent: 16,
              endIndent: 16),

          if (!_ready)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: c.accent, strokeWidth: 2),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('TITLE', c, theme),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: _titleCtrl,
                      hint: 'Link title',
                      maxLines: 2,
                      c: c,
                      theme: theme,
                    ),

                    const SizedBox(height: 20),
                    _sectionLabel('NOTES', c, theme),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: _notesCtrl,
                      hint: 'Add your notes, thoughts, or highlights…',
                      maxLines: 5,
                      c: c,
                      theme: theme,
                    ),

                    const SizedBox(height: 20),
                    _TagSection(
                      selectedTagIds: _selectedTagIds,
                      onToggle: (id) => setState(() {
                        if (_selectedTagIds.contains(id)) {
                          _selectedTagIds.remove(id);
                        } else {
                          _selectedTagIds.add(id);
                        }
                      }),
                      c: c,
                      theme: theme,
                    ),

                    const SizedBox(height: 20),
                    _FolderSection(
                      selectedFolder: _selectedFolder,
                      onSelect: (f) => setState(() => _selectedFolder = f),
                      c: c,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, dynamic c, TextTheme theme) => Text(
        label,
        style: theme.labelSmall!.copyWith(
          color: c.textHint,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required dynamic c,
    required TextTheme theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: theme.bodyMedium!.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.bodyMedium!.copyWith(color: c.textHint),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

// ── Tag section ───────────────────────────────────────────────────────────────

class _TagSection extends ConsumerWidget {
  final Set<int> selectedTagIds;
  final ValueChanged<int> onToggle;
  final dynamic c;
  final TextTheme theme;

  const _TagSection({
    required this.selectedTagIds,
    required this.onToggle,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TAGS',
              style: theme.labelSmall!.copyWith(
                color: c.textHint,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (selectedTagIds.isNotEmpty)
              Text(
                '${selectedTagIds.length} selected',
                style:
                    theme.labelSmall!.copyWith(color: c.accent, fontSize: 10),
              ),
          ],
        ),
        const SizedBox(height: 10),
        tagsAsync.when(
          data: (tags) {
            if (tags.isEmpty) {
              return Text(
                'No tags yet — create some in the Categories tab.',
                style: theme.bodySmall!.copyWith(color: c.textHint),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final selected = selectedTagIds.contains(tag.id);
                return GestureDetector(
                  onTap: () => onToggle(tag.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? c.accentDim : c.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? c.accent : c.border,
                        width: selected ? 1.0 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          Icon(Icons.check_rounded,
                              size: 12, color: c.accent),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          tag.name,
                          style: theme.labelMedium!.copyWith(
                            color: selected ? c.accent : c.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () =>
              CircularProgressIndicator(color: c.accent, strokeWidth: 2),
          error: (e, _) => Text('Failed to load tags',
              style: theme.bodySmall!.copyWith(color: c.coral)),
        ),
      ],
    );
  }
}

// ── Folder section ────────────────────────────────────────────────────────────

class _FolderSection extends ConsumerWidget {
  final FolderModel? selectedFolder;
  final ValueChanged<FolderModel?> onSelect;
  final dynamic c;
  final TextTheme theme;

  const _FolderSection({
    required this.selectedFolder,
    required this.onSelect,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(collectionsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FOLDER',
          style: theme.labelSmall!.copyWith(
            color: c.textHint,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        foldersAsync.when(
          data: (folders) {
            final options = <FolderModel?>[null, ...folders];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((folder) {
                final selected = folder?.id == selectedFolder?.id &&
                    !(folder == null && selectedFolder != null);
                final label = folder?.name ?? 'None';
                return GestureDetector(
                  onTap: () => onSelect(folder),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? c.purpleDim : c.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? c.purple : c.border,
                        width: selected ? 1.0 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          folder == null
                              ? Icons.folder_off_outlined
                              : Icons.folder_rounded,
                          size: 13,
                          color: selected ? c.purple : c.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: theme.labelMedium!.copyWith(
                            color:
                                selected ? c.purple : c.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () =>
              CircularProgressIndicator(color: c.accent, strokeWidth: 2),
          error: (e, _) => Text('Failed to load folders',
              style: theme.bodySmall!.copyWith(color: c.coral)),
        ),
      ],
    );
  }
}
