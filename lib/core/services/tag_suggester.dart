import '../../data/models/Tag/tag_model.dart';
import 'auto_categorizer.dart';

class TagSuggester {
  TagSuggester._();

  /// Given a URL + page title, returns the best-matching tag from the
  /// user's own tag list. Returns null if no confident match is found.
  static TagModel? suggest(
    String url,
    String title,
    List<TagModel> userTags,
  ) {
    if (userTags.isEmpty) return null;

    // Step 1: domain → known category name
    final categoryName = AutoCategorizer.suggest(url);
    if (categoryName != null) {
      final exact = userTags
          .where((t) => t.name.toLowerCase() == categoryName.toLowerCase())
          .firstOrNull;
      if (exact != null) return exact;

      final partial = userTags
          .where((t) =>
              categoryName.toLowerCase().contains(t.name.toLowerCase()))
          .firstOrNull;
      if (partial != null) return partial;
    }

    // Step 2: title keyword matching (only tags ≥ 3 chars to avoid noise)
    if (title.isNotEmpty) {
      final titleLower = title.toLowerCase();
      for (final tag in userTags) {
        final tagLower = tag.name.toLowerCase();
        if (tagLower.length >= 3 && titleLower.contains(tagLower)) {
          return tag;
        }
      }
    }

    return null;
  }
}
