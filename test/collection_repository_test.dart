import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:recallr/data/models/Link/link_model.dart';
import 'package:recallr/data/models/Tag/tag_model.dart';
import 'package:recallr/data/models/collection_model.dart';
import 'package:recallr/core/features/collections/collection_repository.dart';

void main() {
  late Directory tempDir;
  late Isar isar;
  late CollectionRepository repo;

  int _counter = 0;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    _counter++;
    tempDir = await Directory.systemTemp.createTemp('isar_col_test');
    isar = await Isar.open(
      [LinkModelSchema, TagModelSchema, FolderModelSchema],
      directory: tempDir.path,
      name: 'col_repo_test_$_counter',
    );
    repo = CollectionRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // create
  // ---------------------------------------------------------------------------
  group('create', () {
    test('adds a folder with the given name', () async {
      final folder = await repo.create('Work');
      expect(folder.name, 'Work');

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.name, 'Work');
    });

    test('stores optional icon and colorHex', () async {
      final folder = await repo.create('Art', icon: '🎨', colorHex: '#FF5722');
      expect(folder.icon, '🎨');
      expect(folder.colorHex, '#FF5722');
    });

    test('assigns sortOrder equal to the current count before insertion', () async {
      final f1 = await repo.create('First');
      final f2 = await repo.create('Second');
      final f3 = await repo.create('Third');

      expect(f1.sortOrder, 0);
      expect(f2.sortOrder, 1);
      expect(f3.sortOrder, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // getAll
  // ---------------------------------------------------------------------------
  group('getAll', () {
    test('returns empty list when no folders exist', () async {
      expect(await repo.getAll(), isEmpty);
    });

    test('returns all folders ordered by sortOrder', () async {
      await repo.create('Alpha');
      await repo.create('Beta');
      await repo.create('Gamma');

      final all = await repo.getAll();
      expect(all.map((f) => f.name).toList(), ['Alpha', 'Beta', 'Gamma']);
    });
  });

  // ---------------------------------------------------------------------------
  // delete
  // ---------------------------------------------------------------------------
  group('delete', () {
    test('removes the folder from the database', () async {
      final folder = await repo.create('Temporary');
      await repo.delete(folder.id);

      expect(await repo.getAll(), isEmpty);
    });

    test('clears the folder reference on assigned links', () async {
      final folder = await repo.create('MyFolder');

      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Linked Article'
          ..url = 'https://linked.com';
        await isar.linkModels.put(link);
        link.folder.value = folder;
        await link.folder.save();
      });

      await repo.delete(folder.id);

      final updated = await isar.linkModels.get(link.id);
      await updated!.folder.load();
      expect(updated.folder.value, isNull);
    });

    test('no-op for non-existent folder id', () async {
      await expectLater(repo.delete(9999), completes);
    });
  });

  // ---------------------------------------------------------------------------
  // assignToLink
  // ---------------------------------------------------------------------------
  group('assignToLink', () {
    test('sets a folder on a link', () async {
      final folder = await repo.create('Coding');

      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Tech Article'
          ..url = 'https://tech.com';
        await isar.linkModels.put(link);
      });

      await repo.assignToLink(link.id, folder);

      final updated = await isar.linkModels.get(link.id);
      await updated!.folder.load();
      expect(updated.folder.value?.name, 'Coding');
    });

    test('clears folder from a link when null is passed', () async {
      final folder = await repo.create('ToRemove');

      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Article'
          ..url = 'https://article.com';
        await isar.linkModels.put(link);
        link.folder.value = folder;
        await link.folder.save();
      });

      await repo.assignToLink(link.id, null);

      final updated = await isar.linkModels.get(link.id);
      await updated!.folder.load();
      expect(updated.folder.value, isNull);
    });

    test('reassigns a link from one folder to another', () async {
      final folder1 = await repo.create('Folder A');
      final folder2 = await repo.create('Folder B');

      late LinkModel link;
      await isar.writeTxn(() async {
        link = LinkModel()
          ..title = 'Moveable Link'
          ..url = 'https://moveable.com';
        await isar.linkModels.put(link);
        link.folder.value = folder1;
        await link.folder.save();
      });

      await repo.assignToLink(link.id, folder2);

      final updated = await isar.linkModels.get(link.id);
      await updated!.folder.load();
      expect(updated.folder.value?.name, 'Folder B');
    });
  });
}
