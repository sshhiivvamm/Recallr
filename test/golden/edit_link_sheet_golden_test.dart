import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:recallr/common/edit_link_sheet.dart';

import 'fixtures.dart';
import 'golden_helpers.dart';

void main() {
  Widget scenario(Isar isar, GoldenFixtures fixtures, Brightness brightness) => goldenApp(
        isar: isar,
        brightness: brightness,
        child: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: EditLinkSheet(link: fixtures.aiDesignLink),
          ),
        ),
      );

  GoldenTestGroup scenarios(Isar isar, GoldenFixtures fixtures) => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: BoxConstraints.tight(goldenPhoneSize),
        children: [
          GoldenTestScenario(name: 'light', child: scenario(isar, fixtures, Brightness.light)),
          GoldenTestScenario(name: 'dark', child: scenario(isar, fixtures, Brightness.dark)),
        ],
      );

  late Isar isar;
  late GoldenFixtures fixtures;

  setUp(() async {
    isar = await openGoldenIsar();
    fixtures = await seedTypicalData(isar);
  });

  goldenTest(
    'renders the edit link sheet',
    fileName: 'edit_link_sheet',
    pumpBeforeTest: pumpForAsyncData,
    builder: () => scenarios(isar, fixtures),
  );
}
