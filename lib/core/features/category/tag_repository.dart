import 'package:isar/isar.dart';

import '../../../core/services/auto_categorizer.dart';
import '../../../data/models/Tag/tag_model.dart';

class TagRepository {
  final Isar isar;

  TagRepository(this.isar);

  /// Add new tag (chip)
  Future<void> addTag({
    required String name,
    String? colorHex,
    String? icon,
  }) async {
    final tag = TagModel()
      ..name = name
      ..colorHex = colorHex
      ..icon = icon
      ..isDefault = false;

    await isar.writeTxn(() async {
      await isar.tagModels.put(tag);
    });
  }

  /// Returns existing tag matching [name] (case-insensitive), or creates one
  /// with auto-categorizer icon/color if the name is a known system category.
  Future<TagModel> findOrCreateSystemTag(String name) async {
    final existing = await isar.tagModels
        .filter()
        .nameEqualTo(name, caseSensitive: false)
        .findFirst();
    if (existing != null) return existing;

    final meta = AutoCategorizer.metadata(name);
    final tag = TagModel()
      ..name = name
      ..colorHex = meta?.color
      ..icon = meta?.icon
      ..isDefault = false;

    await isar.writeTxn(() async {
      await isar.tagModels.put(tag);
    });
    return tag;
  }
}
