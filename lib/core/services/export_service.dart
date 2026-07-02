import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../data/models/Highlight/highlight_model.dart';
import '../../data/models/Link/link_model.dart';
import '../../data/models/collection_model.dart';

class ExportService {
  ExportService._();
  static final instance = ExportService._();

  Future<void> exportAsJson(Isar isar) async {
    final links = await isar.linkModels.where().findAll();
    for (final link in links) {
      await link.tags.load();
    }

    // Build highlights map keyed by linkId for O(1) lookup
    final allHighlights = await isar.highlightModels.where().findAll();
    final highlightsByLink = <int, List<HighlightModel>>{};
    for (final h in allHighlights) {
      highlightsByLink.putIfAbsent(h.linkId, () => []).add(h);
    }

    final collections = await isar.folderModels.where().findAll();

    final data = {
      'version': '2.0',
      'exported_at': DateTime.now().toIso8601String(),
      'total_links': links.length,
      'collections': collections.map((c) => _collectionToMap(c)).toList(),
      'links': links
          .map((l) => _linkToMap(l, highlightsByLink[l.id] ?? []))
          .toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    await _shareText(jsonStr, 'recallr_export.json', 'application/json');
  }

  Future<void> exportAsCsv(Isar isar) async {
    final links = await isar.linkModels.where().findAll();

    for (final link in links) {
      await link.tags.load();
    }

    final rows = <String>['title,url,domain,tags,isFavorite,isRead,savedAt,notes'];
    for (final l in links) {
      final tags = l.tags.map((t) => t.name).join('|');
      rows.add([
        _csv(l.title),
        _csv(l.url),
        _csv(l.domain ?? ''),
        _csv(tags),
        l.isFavorite.toString(),
        l.isRead.toString(),
        l.createdAt.toIso8601String(),
        _csv(l.notes ?? ''),
      ].join(','));
    }

    final csv = rows.join('\n');
    await _shareText(csv, 'recallr_export.csv', 'text/csv');
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  Map<String, dynamic> _collectionToMap(FolderModel c) => {
        'id': c.id,
        'name': c.name,
        'icon': c.icon,
        'colorHex': c.colorHex,
        'sortOrder': c.sortOrder,
        'createdAt': c.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _linkToMap(LinkModel l, List<HighlightModel> highlights) => {
        'title': l.title,
        'url': l.url,
        'description': l.description,
        'domain': l.domain,
        'siteName': l.siteName,
        'notes': l.notes,
        'tags': l.tags.map((t) => t.name).toList(),
        'isFavorite': l.isFavorite,
        'isRead': l.isRead,
        'savedAt': l.createdAt.toIso8601String(),
        'lastOpenedAt': l.lastOpenedAt?.toIso8601String(),
        'smRepetitions': l.smRepetitions,
        'smEaseFactor': l.smEaseFactor,
        'smInterval': l.smInterval,
        'smNextReview': l.smNextReview?.toIso8601String(),
        'highlights': highlights
            .map((h) => {
                  'text': h.text,
                  'colorHex': h.colorHex,
                  'note': h.note,
                  'createdAt': h.createdAt.toIso8601String(),
                })
            .toList(),
      };

  Future<void> _shareText(String content, String filename, String mimeType) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: 'Recallr Export',
    );
  }
}
