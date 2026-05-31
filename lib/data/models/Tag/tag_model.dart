import 'package:isar/isar.dart';

import '../Link/link_model.dart';

part 'tag_model.g.dart';

@collection
class TagModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  String? colorHex;

  String? icon;

  bool isDefault = false;
  // 🔹 Backlink to links
  @Backlink(to: 'tags')
  final links = IsarLinks<LinkModel>();
}