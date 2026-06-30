import 'package:isar/isar.dart';

part 'highlight_model.g.dart';

@collection
class HighlightModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int linkId;

  @Index()
  late String text;

  String? colorHex;

  String? note;

  DateTime createdAt = DateTime.now();
}
