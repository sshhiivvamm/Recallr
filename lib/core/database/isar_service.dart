// This file is responsible for opening and managing the database

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/collection_model.dart';
import '../../data/models/Link/link_model.dart';
import '../../data/models/Tag/tag_model.dart';

class IsarService {
  IsarService._();

  // Singleton instance (only one DB instance in whole app)
  static final instance = IsarService._();

  // Lazy-loaded database (opens only once when needed)
  late final Future<Isar> db = _openDB();

  Future<Isar> _openDB() async {
    // Get device storage path
    final dir = await getApplicationDocumentsDirectory();
    // Open Isar database with all schemas (tables)
    return await Isar.open([
      LinkModelSchema, // stores links
      FolderModelSchema, // stores categories
      TagModelSchema, // stores tags (chips)
    ], directory: dir.path);
  }
}
