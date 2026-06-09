import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../data/models/Link/link_model.dart';

class ExportService {
  ExportService._();
  static final instance = ExportService._();

  Future<void> exportAsJson(Isar isar) async {
    final links = await isar.linkModels.where().findAll();

    for (final link in links) {
      await link.tags.load();
    }

    final data = {
      'version': '1.0',
      'total': links.length,
      'links': links.map((l) => _linkToMap(l)).toList(),
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

  Map<String, dynamic> _linkToMap(LinkModel l) => {
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
