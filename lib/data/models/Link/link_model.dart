import 'package:isar/isar.dart';

import '../Tag/tag_model.dart';
import '../collection_model.dart';

part 'link_model.g.dart';


@collection
class LinkModel {
  Id id = Isar.autoIncrement;

  @Index()
  late String title;

  @Index(unique: true)
  late String url;

  @Index(type: IndexType.value, caseSensitive: false)
  String? description; // from metadata

  @Index(type: IndexType.value, caseSensitive: false)
  String? notes;       // user-added notes

  String? thumbnail;   // og:image
  String? favicon;     // NEW (site icon)
  String? domain;      // NEW
  String? siteName;    // NEW

  bool isFavorite = false;
  bool isRead = false;

  @Index()
  DateTime createdAt = DateTime.now();
  DateTime? lastOpenedAt;
  DateTime? updatedAt;

  // SM-2 spaced-repetition state — persisted here so backup/restore preserves it
  int smRepetitions = 0;
  double smEaseFactor = 2.5;
  int smInterval = 1;
  DateTime? smNextReview;

  final tags = IsarLinks<TagModel>();
  final folder = IsarLink<FolderModel>();
}
