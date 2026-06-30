import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/Link/link_model.dart';

/// One-time migration: copies SM-2 state from SharedPreferences into Isar.
/// Runs once on first launch of the new build; safe to call on every startup
/// because the migration flag short-circuits immediately after first run.
class Sm2MigrationService {
  Sm2MigrationService._();
  static final instance = Sm2MigrationService._();

  static const _migratedKey = 'sm2_migrated_v1';

  Future<void> migrate(Isar isar) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;

    final sm2Keys = prefs.getKeys()
        .where((k) => k.startsWith('sm2_') && k != _migratedKey)
        .toList();

    if (sm2Keys.isNotEmpty) {
      final updates = <LinkModel>[];
      for (final key in sm2Keys) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        final id = int.tryParse(key.substring(4)); // strip 'sm2_'
        if (id == null) continue;
        try {
          final j = jsonDecode(raw) as Map<String, dynamic>;
          final link = await isar.linkModels.get(id);
          if (link == null) continue;
          link.smRepetitions = (j['reps'] as int?) ?? 0;
          link.smEaseFactor = (j['ease'] as num?)?.toDouble() ?? 2.5;
          link.smInterval = (j['interval'] as int?) ?? 1;
          final next = j['nextReview'] as String?;
          if (next != null) link.smNextReview = DateTime.tryParse(next);
          updates.add(link);
        } catch (_) {
          // Corrupt entry — skip
        }
      }

      if (updates.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.linkModels.putAll(updates);
        });
      }

      // Remove migrated keys
      for (final key in sm2Keys) {
        await prefs.remove(key);
      }
    }

    await prefs.setBool(_migratedKey, true);
  }
}
