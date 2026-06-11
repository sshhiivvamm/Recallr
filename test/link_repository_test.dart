import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recallr/data/models/Link/link_model.dart';
import 'package:recallr/data/models/Tag/tag_model.dart';
import 'package:recallr/data/models/collection_model.dart';
import 'package:recallr/core/repositrories/link_providers/link_repository.dart';

void main() {
  late Directory tempDir;
  late Isar isar;
  late LinkRepository repo;

  int _counter = 0;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _counter++;
    tempDir = await Directory.systemTemp.createTemp('isar_link_test');
    isar = await Isar.open(
      [LinkModelSchema, TagModelSchema, FolderModelSchema],
      directory: tempDir.path,
      name: 'link_repo_test_$_counter',
    );
    repo = LinkRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // getReadingStreak
  // ---------------------------------------------------------------------------
  group('getReadingStreak', () {
    test('returns 0 when database is empty', () async {
      expect(await repo.getReadingStreak(), 0);
    });

    test('returns 0 when no links have been opened', () async {
      await isar.writeTxn(() async {
        await isar.linkModels.put(
          LinkModel()
            ..title = 'Unopened'
            ..url = 'https://unopened.com',
        );
      });
      expect(await repo.getReadingStreak(), 0);
    });

    test('returns 1 for a link opened today', () async {
      await isar.writeTxn(() async {
        await isar.linkModels.put(
          LinkModel()
            ..title = 'Today'
            ..url = 'https://today.com'
            ..lastOpenedAt = DateTime.now(),
        );
      });
      expect(await repo.getReadingStreak(), 1);
    });

    test('returns 3 for three consecutive days', () async {
      final now = DateTime.now();
      await isar.writeTxn(() async {
        await isar.linkModels.putAll([
          LinkModel()
            ..title = 'Day 0'
            ..url = 'https://d0.com'
            ..lastOpenedAt = now,
          LinkModel()
            ..title = 'Day 1'
            ..url = 'https://d1.com'
            ..lastOpenedAt = now.subtract(const Duration(days: 1)),
          LinkModel()
            ..title = 'Day 2'
            ..url = 'https://d2.com'
            ..lastOpenedAt = now.subtract(const Duration(days: 2)),
        ]);
      });
      expect(await repo.getReadingStreak(), 3);
    });

    test('breaks streak when a day is skipped', () async {
      final now = DateTime.now();
      await isar.writeTxn(() async {
        await isar.linkModels.putAll([
          LinkModel()
            ..title = 'Today'
            ..url = 'https://today.com'
            ..lastOpenedAt = now,
          // gap: day 1 is missing
          LinkModel()
            ..title = 'Day 2 ago'
            ..url = 'https://d2.com'
            ..lastOpenedAt = now.subtract(const Duration(days: 2)),
        ]);
      });
      expect(await repo.getReadingStreak(), 1);
    });

    test('counts streak starting from yesterday when not opened today', () async {
      final now = DateTime.now();
      await isar.writeTxn(() async {
        await isar.linkModels.putAll([
          LinkModel()
            ..title = 'Yesterday'
            ..url = 'https://y.com'
            ..lastOpenedAt = now.subtract(const Duration(days: 1)),
          LinkModel()
            ..title = 'Two days ago'
            ..url = 'https://y2.com'
            ..lastOpenedAt = now.subtract(const Duration(days: 2)),
        ]);
      });
      expect(await repo.getReadingStreak(), 2);
    });

    test('multiple opens on same day count as one streak day', () async {
      final now = DateTime.now();
      await isar.writeTxn(() async {
        await isar.linkModels.putAll([
          LinkModel()
            ..title = 'Morning'
            ..url = 'https://morning.com'
            ..lastOpenedAt = DateTime(now.year, now.month, now.day, 8),
          LinkModel()
            ..title = 'Evening'
            ..url = 'https://evening.com'
            ..lastOpenedAt = DateTime(now.year, now.month, now.day, 20),
        ]);
      });
      expect(await repo.getReadingStreak(), 1);
    });
  });

  // ---------------------------------------------------------------------------
  // getDiscoverLink
  // ---------------------------------------------------------------------------
  group('getDiscoverLink', () {
    test('returns null when no links exist', () async {
      expect(await repo.getDiscoverLink(), isNull);
    });

    test('returns null when all links are read', () async {
      await isar.writeTxn(() async {
        await isar.linkModels.put(
          LinkModel()
            ..title = 'Read'
            ..url = 'https://read.com'
            ..createdAt = DateTime.now().subtract(const Duration(days: 10))
            ..isRead = true,
        );
      });
      expect(await repo.getDiscoverLink(), isNull);
    });

    test('returns null when unread link is newer than 7 days', () async {
      await isar.writeTxn(() async {
        await isar.linkModels.put(
          LinkModel()
            ..title = 'Recent'
            ..url = 'https://recent.com'
            ..createdAt = DateTime.now().subtract(const Duration(days: 3))
            ..isRead = false,
        );
      });
      expect(await repo.getDiscoverLink(), isNull);
    });

    test('returns unread link older than 7 days', () async {
      await isar.writeTxn(() async {
        await isar.linkModels.put(
          LinkModel()
            ..title = 'Old Unread'
            ..url = 'https://old.com'
            ..createdAt = DateTime.now().subtract(const Duration(days: 10))
            ..isRead = false,
        );
      });
      final result = await repo.getDiscoverLink();
      expect(result, isNotNull);
      expect(result!.url, 'https://old.com');
    });

    test('excludes recent link but returns old unread one', () async {
      await isar.writeTxn(() async {
        await isar.linkModels.putAll([
          LinkModel()
            ..title = 'New'
            ..url = 'https://new.com'
            ..createdAt = DateTime.now().subtract(const Duration(days: 2))
            ..isRead = false,
          LinkModel()
            ..title = 'Old'
            ..url = 'https://veryold.com'
            ..createdAt = DateTime.now().subtract(const Duration(days: 14))
            ..isRead = false,
        ]);
      });
      final result = await repo.getDiscoverLink();
      expect(result?.url, 'https://veryold.com');
    });
  });

  // ---------------------------------------------------------------------------
  // toggleFavorite
  // ---------------------------------------------------------------------------
  group('toggleFavorite', () {
    test('flips isFavorite from false to true', () async {
      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Fav Test'
          ..url = 'https://fav.com'
          ..isFavorite = false;
        await isar.linkModels.put(link);
      });

      await repo.toggleFavorite(link.id);
      final updated = await isar.linkModels.get(link.id);
      expect(updated!.isFavorite, true);
    });

    test('flips isFavorite from true back to false', () async {
      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Fav Test 2'
          ..url = 'https://fav2.com'
          ..isFavorite = true;
        await isar.linkModels.put(link);
      });

      await repo.toggleFavorite(link.id);
      final updated = await isar.linkModels.get(link.id);
      expect(updated!.isFavorite, false);
    });
  });

  // ---------------------------------------------------------------------------
  // toggleRead
  // ---------------------------------------------------------------------------
  group('toggleRead', () {
    test('flips isRead from false to true', () async {
      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Read Test'
          ..url = 'https://readtest.com'
          ..isRead = false;
        await isar.linkModels.put(link);
      });

      await repo.toggleRead(link.id);
      final updated = await isar.linkModels.get(link.id);
      expect(updated!.isRead, true);
    });

    test('flips isRead from true back to false', () async {
      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Read Test 2'
          ..url = 'https://readtest2.com'
          ..isRead = true;
        await isar.linkModels.put(link);
      });

      await repo.toggleRead(link.id);
      final updated = await isar.linkModels.get(link.id);
      expect(updated!.isRead, false);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteLink
  // ---------------------------------------------------------------------------
  group('deleteLink', () {
    test('removes link from the database', () async {
      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Deletable'
          ..url = 'https://delete.com';
        await isar.linkModels.put(link);
      });

      await repo.deleteLink(link.id);
      expect(await isar.linkModels.get(link.id), isNull);
    });

    test('no-op when link does not exist', () async {
      // Should not throw
      await expectLater(repo.deleteLink(9999), completes);
    });
  });

  // ---------------------------------------------------------------------------
  // updateLastOpened
  // ---------------------------------------------------------------------------
  group('updateLastOpened', () {
    test('sets lastOpenedAt timestamp', () async {
      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Open Me'
          ..url = 'https://open.com'
          ..lastOpenedAt = null;
        await isar.linkModels.put(link);
      });

      await repo.updateLastOpened(link.id);
      final updated = await isar.linkModels.get(link.id);
      expect(updated!.lastOpenedAt, isNotNull);
    });
  });
}
