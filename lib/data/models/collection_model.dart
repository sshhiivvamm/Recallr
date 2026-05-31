import 'package:isar/isar.dart';

import 'Link/link_model.dart';

part 'collection_model.g.dart';

@collection
class FolderModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? icon;
  String? colorHex;

  int sortOrder = 0;

  DateTime createdAt = DateTime.now();

  // 👇 Back-link to see all links in this folder
  @Backlink(to: 'folder')
  final links = IsarLinks<LinkModel>();
}
