import 'package:isar/isar.dart';

import 'package:recallr/data/models/Highlight/highlight_model.dart';
import 'package:recallr/data/models/Link/link_model.dart';
import 'package:recallr/data/models/Tag/tag_model.dart';
import 'package:recallr/data/models/collection_model.dart';

/// A handle to the tags/folders/links seeded by [seedTypicalData], so
/// individual golden tests can reference specific fixture rows (e.g. to
/// build a `ReCollectionLinks(folder: fixtures.work)` or filter by tag id).
class GoldenFixtures {
  const GoldenFixtures({
    required this.designTag,
    required this.devTag,
    required this.readingTag,
    required this.workFolder,
    required this.personalFolder,
    required this.aiDesignLink,
    required this.flutterPerfLink,
    required this.spacedRepetitionLink,
  });

  final TagModel designTag;
  final TagModel devTag;
  final TagModel readingTag;
  final FolderModel workFolder;
  final FolderModel personalFolder;
  final LinkModel aiDesignLink;
  final LinkModel flutterPerfLink;
  final LinkModel spacedRepetitionLink;
}

/// Seeds a realistic, varied data set: tags (one pinned), collections, links
/// covering favorite/read/unread/thumbnail/no-thumbnail/notes states, and one
/// highlight — enough for every screen to render its populated state.
Future<GoldenFixtures> seedTypicalData(Isar isar) async {
  late TagModel design, dev, reading;
  late FolderModel work, personal;
  late LinkModel aiDesign, flutterPerf, spacedRepetition;

  await isar.writeTxn(() async {
    design = TagModel()
      ..name = 'Design'
      ..colorHex = 'A78BFA'
      ..icon = 'design'
      ..isDefault = true;
    dev = TagModel()
      ..name = 'Dev'
      ..colorHex = '38BDF8'
      ..icon = 'code'
      ..isDefault = true;
    reading = TagModel()
      ..name = 'Reading'
      ..colorHex = '34D399'
      ..icon = 'book';
    await isar.tagModels.putAll([design, dev, reading]);

    work = FolderModel()
      ..name = 'Work'
      ..colorHex = '38BDF8'
      ..sortOrder = 0;
    personal = FolderModel()
      ..name = 'Personal'
      ..colorHex = 'F87171'
      ..sortOrder = 1;
    await isar.folderModels.putAll([work, personal]);

    final now = DateTime.now();

    aiDesign = LinkModel()
      ..title = 'The Future of AI Design Systems'
      ..url = 'https://example.com/ai-design'
      ..description =
          'How AI is reshaping design systems and component libraries for modern product teams.'
      ..domain = 'example.com'
      ..siteName = 'Example'
      ..favicon = 'https://example.com/favicon.png'
      ..thumbnail = 'https://example.com/thumb.jpg'
      ..isFavorite = true
      ..isRead = false
      ..createdAt = now.subtract(const Duration(hours: 3))
      ..lastOpenedAt = now.subtract(const Duration(hours: 1));

    flutterPerf = LinkModel()
      ..title = 'Flutter Performance Deep Dive'
      ..url = 'https://flutter.dev/perf'
      ..description =
          'Understanding widget rebuilds, const constructors, and RepaintBoundary.'
      ..domain = 'flutter.dev'
      ..siteName = 'Flutter'
      ..favicon = 'https://flutter.dev/favicon.png'
      ..isFavorite = false
      ..isRead = true
      ..createdAt = now.subtract(const Duration(days: 1))
      ..lastOpenedAt = now.subtract(const Duration(hours: 20));

    spacedRepetition = LinkModel()
      ..title =
          'Spaced Repetition — Why You Remember Some Things and Forget Others'
      ..url = 'https://en.wikipedia.org/wiki/Spaced_repetition'
      ..description =
          'Spaced repetition is a study technique that exploits the psychological spacing effect. '
          'Reviewing information at increasing intervals is one of the most effective ways to '
          'transfer knowledge into long-term memory.'
      ..domain = 'en.wikipedia.org'
      ..siteName = 'Wikipedia'
      ..notes = 'Great primer on SM-2 — review this before implementing.'
      ..isFavorite = false
      ..isRead = false
      ..createdAt = now.subtract(const Duration(days: 8));

    await isar.linkModels.putAll([aiDesign, flutterPerf, spacedRepetition]);

    aiDesign.tags.add(design);
    aiDesign.folder.value = work;
    flutterPerf.tags.add(dev);
    flutterPerf.folder.value = work;
    spacedRepetition.tags.add(reading);
    spacedRepetition.folder.value = personal;

    for (final link in [aiDesign, flutterPerf, spacedRepetition]) {
      await link.tags.save();
      await link.folder.save();
    }

    await isar.highlightModels.put(
      HighlightModel()
        ..linkId = spacedRepetition.id
        ..text =
            'Reviewing information at increasing intervals is one of the most '
            'effective ways to transfer knowledge into long-term memory.'
        ..colorHex = 'rgba(251,191,36,0.45)',
    );
  });

  return GoldenFixtures(
    designTag: design,
    devTag: dev,
    readingTag: reading,
    workFolder: work,
    personalFolder: personal,
    aiDesignLink: aiDesign,
    flutterPerfLink: flutterPerf,
    spacedRepetitionLink: spacedRepetition,
  );
}
