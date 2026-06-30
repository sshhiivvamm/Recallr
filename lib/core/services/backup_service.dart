import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/Highlight/highlight_model.dart';
import '../../data/models/Link/link_model.dart';
import '../../data/models/Tag/tag_model.dart';
import '../../data/models/collection_model.dart';

class BackupService {
  BackupService._();
  static final instance = BackupService._();

  Future<File?> _backupFile() async {
    try {
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

  Future<void> autoBackup(Isar isar) async {
    try {
      final file = await _backupFile();
      if (file == null) return;

      final links = await isar.linkModels.where().findAll();
      await Future.wait(links.map((l) async {
        await l.tags.load();
        await l.folder.load();
      }));

      // Build linkId → url index for highlight serialisation
      final idToUrl = {for (final l in links) l.id: l.url};

      final folders = await isar.folderModels.where().findAll();
      final highlights = await isar.highlightModels.where().findAll();

      final json = jsonEncode({
        'version': '2.0',
        'backedUpAt': DateTime.now().toIso8601String(),
        'total': links.length,
        'links': links.map(_linkToMap).toList(),
        'collections': folders.map(_folderToMap).toList(),
        'highlights': highlights
            .where((h) => idToUrl.containsKey(h.linkId))
            .map((h) => _highlightToMapWithUrl(h, idToUrl[h.linkId]!))
            .toList(),
      });

      await file.writeAsString(json);
    } catch (_) {
      // Backup is best-effort; never crash the app.
    }
  }

  // If the DB is empty and a backup file exists, restore it automatically.
  Future<bool> autoRestore(Isar isar) async {
    try {
      final count = await isar.linkModels.count();
      if (count > 0) return false;

      final file = await _backupFile();
      if (file == null || !file.existsSync()) return false;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final linksList =
          (data['links'] as List<dynamic>).cast<Map<String, dynamic>>();
      if (linksList.isEmpty) return false;

      final version = data['version'] as String? ?? '1.0';
      final isV2 = version.startsWith('2.');

      // Maps backup IDs to restored Isar IDs for cross-referencing
      final folderIdMap = <int, int>{}; // oldId -> newId
      final urlToLinkId = <String, int>{}; // url -> new Isar id

      await isar.writeTxn(() async {
        // ── 1. Restore collections ─────────────────────────────────────────
        if (isV2) {
          final folderList = (data['collections'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          for (final map in folderList) {
            final folder = _folderFromMap(map);
            final newId = await isar.folderModels.put(folder);
            final oldId = map['id'] as int?;
            if (oldId != null) folderIdMap[oldId] = newId;
          }
        }

        // ── 2. Restore links ───────────────────────────────────────────────
        for (final map in linksList) {
          final link = _linkFromMap(map);

          // Re-attach folder if it was referenced
          final oldFolderId = map['folderId'] as int?;
          if (isV2 && oldFolderId != null) {
            final newFolderId = folderIdMap[oldFolderId];
            if (newFolderId != null) {
              final folder = await isar.folderModels.get(newFolderId);
              if (folder != null) {
                await link.folder.load();
                link.folder.value = folder;
              }
            }
          }

          await isar.linkModels.put(link);
          urlToLinkId[link.url] = link.id;

          // Re-attach tags
          final tagNames = (map['tags'] as List<dynamic>).cast<String>();
          if (tagNames.isNotEmpty) {
            final tags = <TagModel>[];
            for (final name in tagNames) {
              var tag =
                  await isar.tagModels.filter().nameEqualTo(name).findFirst();
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

          // Persist folder link after tags so the link id is finalised
          if (link.folder.value != null) {
            await link.folder.save();
          }
        }

        // ── 3. Restore highlights ──────────────────────────────────────────
        if (isV2) {
          final highlightList = (data['highlights'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
          for (final map in highlightList) {
            final linkUrl = map['linkUrl'] as String?;
            final newLinkId =
                linkUrl != null ? urlToLinkId[linkUrl] : null;
            if (newLinkId == null) continue;
            final h = _highlightFromMap(map, newLinkId);
            await isar.highlightModels.put(h);
          }
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Serialisation helpers ──────────────────────────────────────────────────

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
        'folderId': l.folder.value?.id,
        'isFavorite': l.isFavorite,
        'isRead': l.isRead,
        'savedAt': l.createdAt.toIso8601String(),
        'lastOpenedAt': l.lastOpenedAt?.toIso8601String(),
        'updatedAt': l.updatedAt?.toIso8601String(),
        // SM-2 state
        'smRepetitions': l.smRepetitions,
        'smEaseFactor': l.smEaseFactor,
        'smInterval': l.smInterval,
        'smNextReview': l.smNextReview?.toIso8601String(),
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
      ..createdAt =
          DateTime.tryParse(m['savedAt'] as String? ?? '') ?? DateTime.now()
      ..smRepetitions = (m['smRepetitions'] as int?) ?? 0
      ..smEaseFactor = (m['smEaseFactor'] as num?)?.toDouble() ?? 2.5
      ..smInterval = (m['smInterval'] as int?) ?? 1;

    final lastOpened = m['lastOpenedAt'] as String?;
    if (lastOpened != null) link.lastOpenedAt = DateTime.tryParse(lastOpened);

    final updated = m['updatedAt'] as String?;
    if (updated != null) link.updatedAt = DateTime.tryParse(updated);

    final smNext = m['smNextReview'] as String?;
    if (smNext != null) link.smNextReview = DateTime.tryParse(smNext);

    return link;
  }

  Map<String, dynamic> _folderToMap(FolderModel f) => {
        'id': f.id,
        'name': f.name,
        'icon': f.icon,
        'colorHex': f.colorHex,
        'sortOrder': f.sortOrder,
        'createdAt': f.createdAt.toIso8601String(),
      };

  FolderModel _folderFromMap(Map<String, dynamic> m) => FolderModel()
    ..name = m['name'] as String? ?? ''
    ..icon = m['icon'] as String?
    ..colorHex = m['colorHex'] as String?
    ..sortOrder = (m['sortOrder'] as int?) ?? 0
    ..createdAt =
        DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now();

  Map<String, dynamic> _highlightToMapWithUrl(
          HighlightModel h, String linkUrl) =>
      {
        'linkUrl': linkUrl,
        'text': h.text,
        'colorHex': h.colorHex,
        'note': h.note,
        'createdAt': h.createdAt.toIso8601String(),
      };

  HighlightModel _highlightFromMap(Map<String, dynamic> m, int linkId) =>
      HighlightModel()
        ..linkId = linkId
        ..text = m['text'] as String? ?? ''
        ..colorHex = m['colorHex'] as String?
        ..note = m['note'] as String?
        ..createdAt =
            DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now();
}
