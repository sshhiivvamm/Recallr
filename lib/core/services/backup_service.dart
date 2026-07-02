import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/Highlight/highlight_model.dart';
import '../../data/models/Link/link_model.dart';
import '../../data/models/Tag/tag_model.dart';
import '../../data/models/collection_model.dart';

class BackupService {
  BackupService._();
  static final instance = BackupService._();

  /// Primary write location — always internal app documents directory.
  /// This is always accessible without any OS-level storage permissions.
  Future<File?> _backupFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/recallr_auto_backup.json');
    } catch (_) {
      return null;
    }
  }

  /// Secondary location — external storage (old write location).
  /// Checked as a fallback during restore so existing backups aren't lost.
  Future<File?> _externalBackupFile() async {
    try {
      if (!Platform.isAndroid) return null;
      final dir = await getExternalStorageDirectory();
      if (dir == null) return null;
      final file = File('${dir.path}/recallr_auto_backup.json');
      return file.existsSync() ? file : null;
    } catch (_) {
      return null;
    }
  }

  /// Checks for the backup left by the old app (applicationId = com.example.recallr).
  Future<File?> _legacyBackupFile() async {
    try {
      if (!Platform.isAndroid) return null;
      const path =
          '/storage/emulated/0/Android/data/com.example.recallr/files/recallr_auto_backup.json';
      final file = File(path);
      return file.existsSync() ? file : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> autoBackup(Isar isar) async {
    try {
      final file = await _backupFile();
      if (file == null) return;

      final links = await isar.linkModels.where().findAll();
      // Never overwrite a non-empty backup with empty data (e.g. on a fresh install
      // before restore has run, or after isar.clear() during restore).
      if (links.isEmpty) return;
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

  /// Returns the path of the active backup file (internal storage).
  Future<String?> backupFilePath() async {
    final file = await _backupFile();
    return file?.path;
  }

  /// Manual restore: reads and validates the backup BEFORE clearing the DB so
  /// live data is never destroyed if the backup is empty or missing.
  /// Falls back to the legacy (com.example.recallr) backup path automatically.
  /// Returns true if data was restored.
  Future<bool> restoreToIsar(Isar isar) async {
    try {
      debugPrint('[Backup] restoreToIsar: starting');
      final parsed = await _readValidBackup();
      if (parsed == null) {
        debugPrint('[Backup] restoreToIsar: _readValidBackup returned null → aborting');
        return false;
      }
      final links = parsed[1] as List<Map<String, dynamic>>;
      debugPrint('[Backup] restoreToIsar: found ${links.length} links — clearing DB');

      await isar.writeTxn(() async {
        await isar.clear();
      });
      debugPrint('[Backup] restoreToIsar: DB cleared — starting _restoreFromData');

      final ok = await _restoreFromData(
        isar,
        parsed[0] as Map<String, dynamic>,
        links,
      );
      debugPrint('[Backup] restoreToIsar: _restoreFromData returned $ok');

      // Fetch missing thumbnails in background — doesn't block the UI
      if (ok) refreshMissingThumbnails(isar).ignore();

      return ok;
    } catch (e, st) {
      debugPrint('[Backup] restoreToIsar: EXCEPTION $e\n$st');
      return false;
    }
  }

  /// Reads and parses a backup file. Checks internal → external → legacy paths.
  /// Returns a two-element list [data, linksList] if valid, null otherwise.
  Future<List<Object>?> _readValidBackup() async {
    final candidates = [
      await _backupFile(),
      await _externalBackupFile(),
      await _legacyBackupFile(),
    ];
    for (final file in candidates) {
      if (file == null) {
        debugPrint('[Backup] _readValidBackup: candidate is null — skipping');
        continue;
      }
      final exists = file.existsSync();
      debugPrint('[Backup] _readValidBackup: checking ${file.path} — exists=$exists');
      if (!exists) continue;
      try {
        final content = await file.readAsString();
        debugPrint('[Backup] _readValidBackup: read ${content.length} chars from ${file.path}');
        final data = jsonDecode(content) as Map<String, dynamic>;
        final linksList = (data['links'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        debugPrint('[Backup] _readValidBackup: parsed — links=${linksList.length}, version=${data["version"]}');
        if (linksList.isNotEmpty) return [data, linksList];
        debugPrint('[Backup] _readValidBackup: links list is empty — trying next');
      } catch (e) {
        debugPrint('[Backup] _readValidBackup: parse error on ${file.path}: $e');
        continue;
      }
    }
    debugPrint('[Backup] _readValidBackup: no valid backup found');
    return null;
  }

  // If the DB is empty and a backup file exists, restore it automatically.
  Future<bool> autoRestore(Isar isar) async {
    try {
      final count = await isar.linkModels.count();
      if (count > 0) return false;

      final parsed = await _readValidBackup();
      if (parsed == null) return false;

      return await _restoreFromData(
        isar,
        parsed[0] as Map<String, dynamic>,
        parsed[1] as List<Map<String, dynamic>>,
      );
    } catch (e, st) {
      debugPrint('[Backup] autoRestore: EXCEPTION $e\n$st');
      return false;
    }
  }

  /// Fetches OG thumbnails for every link that was restored without one.
  /// Runs in the background after restore — never blocks the UI.
  Future<void> refreshMissingThumbnails(Isar isar) async {
    try {
      final links = await isar.linkModels
          .filter()
          .thumbnailIsNull()
          .findAll();
      debugPrint('[Backup] refreshMissingThumbnails: ${links.length} links need thumbnails');
      for (final link in links) {
        try {
          final url = link.url;
          if (!url.startsWith('http')) continue;
          final meta = await MetadataFetch.extract(url);
          if (meta?.image != null) {
            await isar.writeTxn(() async {
              link.thumbnail = meta!.image;
              await isar.linkModels.put(link);
            });
          }
        } catch (_) {
          // Best-effort per link — never abort the whole batch
        }
      }
      debugPrint('[Backup] refreshMissingThumbnails: done');
    } catch (_) {}
  }

  Future<bool> _restoreFromData(
    Isar isar,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> linksList,
  ) async {
    try {
      final version = data['version'] as String? ?? '1.0';
      final isV2 = version.startsWith('2.');
      debugPrint('[Backup] _restoreFromData: version=$version isV2=$isV2 links=${linksList.length}');

      // ── Phase 1: create all unique tags (own transaction, no reads inside) ──
      final allTagNames = <String>{};
      for (final map in linksList) {
        allTagNames.addAll((map['tags'] as List<dynamic>? ?? []).cast<String>());
      }
      debugPrint('[Backup] _restoreFromData: creating ${allTagNames.length} unique tags');
      final tagByName = <String, TagModel>{};
      if (allTagNames.isNotEmpty) {
        await isar.writeTxn(() async {
          for (final name in allTagNames) {
            final tag = TagModel()..name = name;
            await isar.tagModels.put(tag);
            tagByName[name] = tag; // id is now assigned
          }
        });
      }

      // ── Phase 2: create collections (own transaction) ──────────────────────
      final folderByOldId = <int, FolderModel>{}; // oldBackupId -> restored model
      if (isV2) {
        final folderList = (data['collections'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        debugPrint('[Backup] _restoreFromData: creating ${folderList.length} collections');
        if (folderList.isNotEmpty) {
          await isar.writeTxn(() async {
            for (final map in folderList) {
              final folder = _folderFromMap(map);
              await isar.folderModels.put(folder); // id assigned
              final oldId = map['id'] as int?;
              if (oldId != null) folderByOldId[oldId] = folder;
            }
          });
        }
      }

      // ── Phase 3: create links + attach relations (own transaction, writes only) ──
      debugPrint('[Backup] _restoreFromData: writing ${linksList.length} links');
      final urlToLinkId = <String, int>{};
      await isar.writeTxn(() async {
        for (final map in linksList) {
          final link = _linkFromMap(map);

          // Track folder with a flag — never access .value inside a writeTxn
          // because IsarLink.value getter calls loadSync which opens a nested
          // read transaction and Isar throws "nesting transactions" error.
          var folderSet = false;
          final oldFolderId = map['folderId'] as int?;
          if (isV2 && oldFolderId != null) {
            final folder = folderByOldId[oldFolderId];
            if (folder != null) {
              link.folder.value = folder;
              folderSet = true;
            }
          }

          await isar.linkModels.put(link); // assigns link.id
          urlToLinkId[link.url] = link.id;

          // Save folder relation now that link has an id
          if (folderSet) await link.folder.save();

          // Attach tags — addAll() on a new link needs no prior load()
          final tagNames = (map['tags'] as List<dynamic>? ?? []).cast<String>();
          final tags = tagNames
              .map((n) => tagByName[n])
              .whereType<TagModel>()
              .toList();
          if (tags.isNotEmpty) {
            link.tags.addAll(tags);
            await link.tags.save();
          }
        }
      });
      debugPrint('[Backup] _restoreFromData: links written');

      // ── Phase 4: restore highlights (own transaction) ──────────────────────
      if (isV2) {
        final highlightList = (data['highlights'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        if (highlightList.isNotEmpty) {
          await isar.writeTxn(() async {
            for (final map in highlightList) {
              final linkUrl = map['linkUrl'] as String?;
              final newLinkId = linkUrl != null ? urlToLinkId[linkUrl] : null;
              if (newLinkId == null) continue;
              await isar.highlightModels.put(_highlightFromMap(map, newLinkId));
            }
          });
        }
      }

      final finalCount = await isar.linkModels.count();
      debugPrint('[Backup] _restoreFromData: done — DB now has $finalCount links');
      return finalCount > 0;
    } catch (e, st) {
      debugPrint('[Backup] _restoreFromData: EXCEPTION $e\n$st');
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
    final url = m['url'] as String? ?? '';
    final rawDomain = m['domain'] as String?;
    // Derive domain from URL if the backup didn't store it
    final domain = (rawDomain != null && rawDomain.isNotEmpty)
        ? rawDomain
        : Uri.tryParse(url)?.host ?? '';

    // Favicon was absent in v1.0 exports — reconstruct from domain so social
    // icons (Instagram, LinkedIn, YouTube…) appear immediately after restore.
    final favicon = m['favicon'] as String? ??
        (domain.isNotEmpty
            ? 'https://www.google.com/s2/favicons?domain=$domain&sz=64'
            : null);

    final link = LinkModel()
      ..title = m['title'] as String? ?? ''
      ..url = url
      ..description = m['description'] as String?
      ..domain = domain.isNotEmpty ? domain : null
      ..siteName = m['siteName'] as String?
      ..thumbnail = m['thumbnail'] as String?
      ..favicon = favicon
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
