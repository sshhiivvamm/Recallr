import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/models/Link/link_model.dart';
import '../../../../data/models/Highlight/highlight_model.dart';
import '../../../../data/models/Tag/tag_model.dart';
import '../../../../data/models/collection_model.dart';

class LinkRepository {
  final Isar isar;

  LinkRepository(this.isar);

  Future<List<LinkModel>> getRecentLinks({int limit = 10}) async {
    return await isar.linkModels
        .where()
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  Stream<List<LinkModel>> watchRecentLinks({int limit = 10}) async* {
    yield* isar.linkModels
        .where()
        .sortByCreatedAtDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  Future<void> toggleFavorite(int id) async {
    await isar.writeTxn(() async {
      final link = await isar.linkModels.get(id);
      if (link != null) {
        link.isFavorite = !link.isFavorite;
        link.updatedAt = DateTime.now();
        await isar.linkModels.put(link);
      }
    });
  }

  Future<void> toggleRead(int id) async {
    await isar.writeTxn(() async {
      final link = await isar.linkModels.get(id);
      if (link != null) {
        link.isRead = !link.isRead;
        link.updatedAt = DateTime.now();
        await isar.linkModels.put(link);
      }
    });
  }

  Future<void> deleteLink(int id) async {
    await isar.writeTxn(() async {
      // Delete orphaned highlights for this link in the same transaction
      final orphanIds = await isar.highlightModels
          .filter()
          .linkIdEqualTo(id)
          .idProperty()
          .findAll();
      await isar.highlightModels.deleteAll(orphanIds);
      await isar.linkModels.delete(id);
    });
    // Clean up link health cache from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('health_$id'),
      prefs.remove('health_ts_$id'),
    ]);
  }

  Future<void> updateLink(int id, {String? title, String? notes}) async {
    await isar.writeTxn(() async {
      final link = await isar.linkModels.get(id);
      if (link == null) return;
      if (title != null && title.isNotEmpty) link.title = title;
      link.notes = notes?.isEmpty == true ? null : notes;
      link.updatedAt = DateTime.now();
      await isar.linkModels.put(link);
    });
  }

  Future<void> setTags(int linkId, List<TagModel> tags) async {
    await isar.writeTxn(() async {
      final link = await isar.linkModels.get(linkId);
      if (link == null) return;
      await link.tags.load();
      link.tags.clear();
      link.tags.addAll(tags);
      link.updatedAt = DateTime.now();
      await link.tags.save();
      await isar.linkModels.put(link);
    });
  }

  Future<void> setFolder(int linkId, FolderModel? folder) async {
    await isar.writeTxn(() async {
      final link = await isar.linkModels.get(linkId);
      if (link == null) return;
      await link.folder.load();
      link.folder.value = folder;
      link.updatedAt = DateTime.now();
      await link.folder.save();
      await isar.linkModels.put(link);
    });
  }

  Future<void> updateLastOpened(int id) async {
    await isar.writeTxn(() async {
      final link = await isar.linkModels.get(id);
      if (link != null) {
        link.lastOpenedAt = DateTime.now();
        await isar.linkModels.put(link);
      }
    });
  }

  Stream<int> watchTotalLinksCount() {
    // watchLazy fires without emitting the full list — count() is O(1) in Isar.
    return isar.linkModels
        .watchLazy(fireImmediately: true)
        .asyncMap((_) => isar.linkModels.count());
  }

  Stream<int> watchThisWeekLinksCount() {
    return isar.linkModels
        .watchLazy(fireImmediately: true)
        .asyncMap((_) {
          final now = DateTime.now();
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          return isar.linkModels
              .filter()
              .createdAtGreaterThan(weekStart)
              .count();
        });
  }

  Stream<List<int>> watchThisWeekDailyCounts() {
    return isar.linkModels
        .watchLazy(fireImmediately: true)
        .asyncMap((_) async {
          final now = DateTime.now();
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final mondayDate = DateTime(monday.year, monday.month, monday.day);
          final endDate = mondayDate.add(const Duration(days: 7));

          // Only load links from this week — index on createdAt makes this fast.
          final links = await isar.linkModels
              .filter()
              .createdAtBetween(mondayDate, endDate)
              .findAll();

          final counts = List.filled(7, 0);
          for (final link in links) {
            final d = link.createdAt;
            final diff =
                DateTime(d.year, d.month, d.day).difference(mondayDate).inDays;
            if (diff >= 0 && diff < 7) counts[diff]++;
          }
          return counts;
        });
  }

  Future<LinkModel?> getDiscoverLink() async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final all = await isar.linkModels.where().findAll();
    final candidates = all
        .where((l) => !l.isRead && l.createdAt.isBefore(cutoff))
        .toList();
    if (candidates.isEmpty) return null;

    // Weighted random: older + never-opened links surface more often.
    // Weight = ageDays × (2 if never opened, 1 otherwise).
    final weights = candidates.map((l) {
      final ageDays = now.difference(l.createdAt).inDays.toDouble();
      return ageDays * (l.lastOpenedAt == null ? 2.0 : 1.0);
    }).toList();

    final totalWeight = weights.fold(0.0, (a, b) => a + b);
    LinkModel selected;
    if (totalWeight <= 0) {
      // All candidates are from today (unlikely but guard anyway)
      selected = candidates[math.Random().nextInt(candidates.length)];
    } else {
      final rand = math.Random().nextDouble() * totalWeight;
      double cumulative = 0;
      selected = candidates.last;
      for (int i = 0; i < candidates.length; i++) {
        cumulative += weights[i];
        if (rand <= cumulative) {
          selected = candidates[i];
          break;
        }
      }
    }
    await selected.tags.load();
    return selected;
  }

  Future<int> getReadingStreak() async {
    final all = await isar.linkModels.where().findAll();
    final readDays = all
        .where((l) => l.lastOpenedAt != null)
        .map((l) => DateUtils.dateOnly(l.lastOpenedAt!))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (readDays.isEmpty) return 0;

    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (!readDays.contains(today) && !readDays.contains(yesterday)) return 0;

    int streak = 0;
    var expected = readDays.contains(today) ? today : yesterday;
    for (final day in readDays) {
      if (day == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (day.isBefore(expected)) {
        break;
      }
    }
    return streak;
  }

  Future<List<LinkModel>> getAllLinks() async {
    final links = await isar.linkModels.where().findAll();
    await Future.wait(links.map((l) => l.tags.load()));
    return links;
  }

  // Returns the highest-scored unread link using:
  // score = days_since_saved × (2 if never opened, 1 otherwise)
  Future<LinkModel?> getNextRead() async {
    final all = await isar.linkModels.where().findAll();
    if (all.isEmpty) return null;

    final now = DateTime.now();
    LinkModel? best;
    double bestScore = -1;

    for (final link in all) {
      if (link.isRead) continue;
      final days = now.difference(link.createdAt).inHours / 24.0;
      final multiplier = link.lastOpenedAt == null ? 2.0 : 1.0;
      final score = days * multiplier;
      if (score > bestScore) {
        bestScore = score;
        best = link;
      }
    }

    if (best != null) {
      await best.tags.load();
      await best.folder.load();
    }
    return best;
  }
}
