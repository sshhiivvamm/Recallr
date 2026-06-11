import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';

import '../../data/models/Link/link_model.dart';

class LinkHealthService {
  LinkHealthService._();
  static final instance = LinkHealthService._();

  static const _prefix = 'health_';
  static const _tsPrefix = 'health_ts_';
  static const _checkIntervalHours = 24;

  static const _concurrency = 5;

  Future<void> checkAll(Isar isar) async {
    final prefs = await SharedPreferences.getInstance();
    final links = await isar.linkModels.where().findAll();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Filter to only links that are actually due for a re-check
    final due = links.where((link) {
      final lastTs = prefs.getInt('$_tsPrefix${link.id}') ?? 0;
      return (now - lastTs) / (1000 * 3600) >= _checkIntervalHours;
    }).toList();

    // Process in batches of _concurrency to avoid hammering the network
    for (int i = 0; i < due.length; i += _concurrency) {
      final batch = due.skip(i).take(_concurrency).toList();
      await Future.wait(batch.map((link) async {
        final alive = await _checkUrl(link.url);
        await prefs.setBool('$_prefix${link.id}', alive);
        await prefs.setInt('$_tsPrefix${link.id}', now);
      }));
    }
  }

  Future<bool?> getCachedStatus(int linkId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$linkId');
  }

  Future<bool> checkSingle(int linkId, String url) async {
    final prefs = await SharedPreferences.getInstance();
    final alive = await _checkUrl(url);
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setBool('$_prefix$linkId', alive);
    await prefs.setInt('$_tsPrefix$linkId', now);
    return alive;
  }

  Future<bool> _checkUrl(String url) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      final resp = await http
          .head(uri)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode < 400) return true;
      // Some servers reject HEAD — fallback to GET
      final resp2 = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));
      return resp2.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}
