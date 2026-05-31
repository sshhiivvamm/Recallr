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

  String? description; // from metadata
  String? notes;       // user-added notes

  String? thumbnail;   // og:image
  String? favicon;     // NEW (site icon)
  String? domain;      // NEW
  String? siteName;    // NEW

  bool isFavorite = false;
  bool isRead = false;

  DateTime createdAt = DateTime.now();
  DateTime? lastOpenedAt; // NEW

  final tags = IsarLinks<TagModel>();
  final folder = IsarLink<FolderModel>();
}
