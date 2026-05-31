import 'package:isar/isar.dart';

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
    // Create tag object
    final tag = TagModel()
      ..name = name
      ..colorHex = colorHex
      ..icon = icon
      ..isDefault = false;

    // Save into database
    await isar.writeTxn(() async {
      await isar.tagModels.put(tag);
    });
  }
}
