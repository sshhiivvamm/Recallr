import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:recallr/core/features/view/re_collection_links.dart';
import 'package:recallr/data/models/collection_model.dart';

import 'fixtures.dart';
import 'golden_helpers.dart';

void main() {
  Widget scenario(Isar isar, FolderModel folder, Brightness brightness) => goldenApp(
        isar: isar,
        brightness: brightness,
        child: ReCollectionLinks(folder: folder),
      );

  GoldenTestGroup scenarios(Isar isar, FolderModel folder) => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: BoxConstraints.tight(goldenPhoneSize),
        children: [
          GoldenTestScenario(name: 'light', child: scenario(isar, folder, Brightness.light)),
          GoldenTestScenario(name: 'dark', child: scenario(isar, folder, Brightness.dark)),
        ],
      );

  group('populated', () {
    late Isar isar;
    late GoldenFixtures fixtures;

    setUp(() async {
      isar = await openGoldenIsar();
      fixtures = await seedTypicalData(isar);
    });

    goldenTest(
      'renders a folder with links',
      fileName: 're_collection_links_populated',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(isar, fixtures.workFolder),
    );
  });

  group('empty', () {
    late Isar isar;
    late FolderModel emptyFolder;

    setUp(() async {
      isar = await openGoldenIsar();
      await seedTypicalData(isar);
      emptyFolder = FolderModel()
        ..name = 'Unsorted'
        ..colorHex = '94A3B8'
        ..sortOrder = 99;
      await isar.writeTxn(() => isar.folderModels.put(emptyFolder));
    });

    goldenTest(
      'renders a folder with no links',
      fileName: 're_collection_links_empty',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(isar, emptyFolder),
    );
  });
}
