import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../../../../data/models/Link/link_model.dart';

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
        await isar.linkModels.put(link);
      }
    });
  }

  Future<void> toggleRead(int id) async {
    await isar.writeTxn(() async {
      final link = await isar.linkModels.get(id);
      if (link != null) {
        link.isRead = !link.isRead;
        await isar.linkModels.put(link);
      }
    });
  }

  Future<void> deleteLink(int id) async {
    await isar.writeTxn(() async {
      await isar.linkModels.delete(id);
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
    return isar.linkModels.where().watch(fireImmediately: true).map((links) => links.length);
  }

  Stream<int> watchThisWeekLinksCount() {
    return isar.linkModels.where().watch(fireImmediately: true).map((links) {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return links.where((link) => link.createdAt.isAfter(weekStart)).length;
    });
  }

  Future<LinkModel?> getDiscoverLink() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final all = await isar.linkModels.where().findAll();
    final candidates = all
        .where((l) => !l.isRead && l.createdAt.isBefore(cutoff))
        .toList();
    if (candidates.isEmpty) return null;
    candidates.shuffle();
    final link = candidates.first;
    await link.tags.load();
    return link;
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
}
