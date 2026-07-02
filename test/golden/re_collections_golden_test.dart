import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:recallr/core/features/view/re_collections.dart';

import 'fixtures.dart';
import 'golden_helpers.dart';

void main() {
  Widget scenario(Isar isar, Brightness brightness) => goldenApp(
        isar: isar,
        brightness: brightness,
        child: const ReCollections(),
      );

  GoldenTestGroup scenarios(Isar isar) => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: BoxConstraints.tight(goldenPhoneSize),
        children: [
          GoldenTestScenario(name: 'light', child: scenario(isar, Brightness.light)),
          GoldenTestScenario(name: 'dark', child: scenario(isar, Brightness.dark)),
        ],
      );

  group('populated', () {
    late Isar isar;

    setUp(() async {
      isar = await openGoldenIsar();
      await seedTypicalData(isar);
    });

    goldenTest(
      'renders the populated collections list',
      fileName: 're_collections_populated',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(isar),
    );
  });

  group('empty', () {
    late Isar isar;

    setUp(() async {
      isar = await openGoldenIsar();
    });

    goldenTest(
      'renders the empty collections state',
      fileName: 're_collections_empty',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(isar),
    );
  });
}
