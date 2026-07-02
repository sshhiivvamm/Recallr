import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:recallr/core/features/view/re_privacy_policy.dart';

import 'golden_helpers.dart';

void main() {
  Widget scenario(Isar isar, Brightness brightness) => goldenApp(
        isar: isar,
        brightness: brightness,
        child: const PrivacyPolicyScreen(),
      );

  GoldenTestGroup scenarios(Isar isar) => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: BoxConstraints.tight(goldenPhoneSize),
        children: [
          GoldenTestScenario(name: 'light', child: scenario(isar, Brightness.light)),
          GoldenTestScenario(name: 'dark', child: scenario(isar, Brightness.dark)),
        ],
      );

  late Isar isar;

  setUp(() async {
    isar = await openGoldenIsar();
  });

  goldenTest(
    'renders the privacy policy screen',
    fileName: 're_privacy_policy',
    pumpBeforeTest: pumpForAsyncData,
    builder: () => scenarios(isar),
  );
}
