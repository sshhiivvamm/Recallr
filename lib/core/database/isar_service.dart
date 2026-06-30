import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/collection_model.dart';
import '../../data/models/Highlight/highlight_model.dart';
import '../../data/models/Link/link_model.dart';
import '../../data/models/Tag/tag_model.dart';
import '../services/backup_service.dart';
import '../services/sm2_migration_service.dart';

class IsarService {
  IsarService._();

  static final instance = IsarService._();

  late final Future<Isar> db = _openDB();

  Future<Isar> _openDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open([
      LinkModelSchema,
      FolderModelSchema,
      TagModelSchema,
      HighlightModelSchema,
    ], directory: dir.path);

    // Auto-restore from backup if DB is empty (e.g. after reinstall).
    await BackupService.instance.autoRestore(isar);

    // One-time migration: move SM-2 state from SharedPreferences into Isar.
    await Sm2MigrationService.instance.migrate(isar);

    return isar;
  }
}
