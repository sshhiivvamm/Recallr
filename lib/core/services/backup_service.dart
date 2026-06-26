import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/Link/link_model.dart';
import '../../data/models/Tag/tag_model.dart';

class BackupService {
  BackupService._();
  static final instance = BackupService._();

  Future<File?> _backupFile() async {
    try {
      // External storage survives flutter run reinstalls on same package.
      // Falls back to app documents dir if external is unavailable (e.g. iOS).
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();
      return File('${dir.path}/recallr_auto_backup.json');
    } catch (_) {
      return null;
    }
  }

  // Silently write all links to the backup file. Call this on startup and
  // after any write operation so the backup stays current.
  Future<void> autoBackup(Isar isar) async {
    try {
      final file = await _backupFile();
      if (file == null) return;

      final links = await isar.linkModels.where().findAll();
      await Future.wait(links.map((l) => l.tags.load()));

      final json = jsonEncode({
        'version': '1.0',
        'backedUpAt': DateTime.now().toIso8601String(),
        'total': links.length,
        'links': links.map(_linkToMap).toList(),
      });

      await file.writeAsString(json);
    } catch (_) {
      // Backup is best-effort; never crash the app.
    }
  }

  // If the DB is empty and a backup file exists, restore it automatically.
  // Returns true if data was restored.
  Future<bool> autoRestore(Isar isar) async {
    try {
      final count = await isar.linkModels.count();
      if (count > 0) return false;

      final file = await _backupFile();
      if (file == null || !file.existsSync()) return false;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final linksList = (data['links'] as List<dynamic>).cast<Map<String, dynamic>>();

      if (linksList.isEmpty) return false;

      await isar.writeTxn(() async {
        for (final map in linksList) {
          final link = _linkFromMap(map);
          await isar.linkModels.put(link);

          final tagNames = (map['tags'] as List<dynamic>).cast<String>();
          if (tagNames.isNotEmpty) {
            final tags = <TagModel>[];
            for (final name in tagNames) {
              var tag = await isar.tagModels.filter().nameEqualTo(name).findFirst();
              if (tag == null) {
                tag = TagModel()..name = name;
                await isar.tagModels.put(tag);
              }
              tags.add(tag);
            }
            await link.tags.load();
            link.tags.addAll(tags);
            await link.tags.save();
          }
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _linkToMap(LinkModel l) => {
        'title': l.title,
        'url': l.url,
        'description': l.description,
        'domain': l.domain,
        'siteName': l.siteName,
        'thumbnail': l.thumbnail,
        'favicon': l.favicon,
        'notes': l.notes,
        'tags': l.tags.map((t) => t.name).toList(),
        'isFavorite': l.isFavorite,
        'isRead': l.isRead,
        'savedAt': l.createdAt.toIso8601String(),
        'lastOpenedAt': l.lastOpenedAt?.toIso8601String(),
        'updatedAt': l.updatedAt?.toIso8601String(),
      };

  LinkModel _linkFromMap(Map<String, dynamic> m) {
    final link = LinkModel()
      ..title = m['title'] as String? ?? ''
      ..url = m['url'] as String? ?? ''
      ..description = m['description'] as String?
      ..domain = m['domain'] as String?
      ..siteName = m['siteName'] as String?
      ..thumbnail = m['thumbnail'] as String?
      ..favicon = m['favicon'] as String?
      ..notes = m['notes'] as String?
      ..isFavorite = m['isFavorite'] as bool? ?? false
      ..isRead = m['isRead'] as bool? ?? false
      ..createdAt = DateTime.tryParse(m['savedAt'] as String? ?? '') ?? DateTime.now();

    final lastOpened = m['lastOpenedAt'] as String?;
    if (lastOpened != null) link.lastOpenedAt = DateTime.tryParse(lastOpened);

    final updated = m['updatedAt'] as String?;
    if (updated != null) link.updatedAt = DateTime.tryParse(updated);

    return link;
  }
}
