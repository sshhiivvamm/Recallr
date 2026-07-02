import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:recallr/core/features/view/re_filtered_links.dart';
import 'package:recallr/data/models/Tag/tag_model.dart';

import 'fixtures.dart';
import 'golden_helpers.dart';

void main() {
  Widget scenario(Isar isar, int tagId, Brightness brightness) => goldenApp(
        isar: isar,
        brightness: brightness,
        child: ReFilteredLinks(
          title: 'Design',
          color: const Color(0xFFA78BFA),
          icon: Icons.palette_outlined,
          tagId: tagId,
        ),
      );

  GoldenTestGroup scenarios(Isar isar, int tagId) => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: BoxConstraints.tight(goldenPhoneSize),
        children: [
          GoldenTestScenario(name: 'light', child: scenario(isar, tagId, Brightness.light)),
          GoldenTestScenario(name: 'dark', child: scenario(isar, tagId, Brightness.dark)),
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
      'renders links filtered by tag',
      fileName: 're_filtered_links_populated',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(isar, fixtures.designTag.id),
    );
  });

  group('empty', () {
    late Isar isar;
    late int emptyTagId;

    setUp(() async {
      isar = await openGoldenIsar();
      await seedTypicalData(isar);
      final emptyTag = TagModel()
        ..name = 'Unused'
        ..colorHex = '94A3B8'
        ..icon = 'tag';
      await isar.writeTxn(() => isar.tagModels.put(emptyTag));
      emptyTagId = emptyTag.id;
    });

    goldenTest(
      'renders a tag with no links',
      fileName: 're_filtered_links_empty',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(isar, emptyTagId),
    );
  });
}
