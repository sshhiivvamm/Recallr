import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recallr/core/features/view/recallr_home.dart';

import 'fixtures.dart';
import 'golden_helpers.dart';

void main() {
  Widget scenario(Isar isar, Brightness brightness) => goldenApp(
        isar: isar,
        brightness: brightness,
        child: const RecallrHome(),
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
      SharedPreferences.setMockInitialValues({});
      isar = await openGoldenIsar();
      await seedTypicalData(isar);
    });

    goldenTest(
      'renders the populated home feed',
      fileName: 'recallr_home_populated',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(isar),
    );
  });

  group('empty', () {
    late Isar isar;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      isar = await openGoldenIsar();
    });

    goldenTest(
      'renders the empty home feed',
      fileName: 'recallr_home_empty',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(isar),
    );
  });
}
