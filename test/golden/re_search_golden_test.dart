import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:recallr/core/features/view/re_search.dart';

import 'fixtures.dart';
import 'golden_helpers.dart';

// NOTE: only the idle (no-query) state is golden-tested here. Driving the
// results/no-results states requires `tester.enterText` into the search
// `TextField` (the only external seam, since `_searchParamsProvider` is
// file-private) — but doing so reliably hangs alchemist's golden capture
// step *after* pumpBeforeTest completes (confirmed via diagnostics: the
// enterText + pumpForAsyncData logic itself finishes fine and prints
// confirm it; the hang is inside alchemist's own image-capture, even after
// explicitly unfocusing the field first). Not yet root-caused — see
// DOCUMENTATION.md § 5.13.1 and the golden-test-suite-status memory before
// re-attempting.

void main() {
  Widget scenario(Isar isar, Brightness brightness) => goldenApp(
        isar: isar,
        brightness: brightness,
        child: const ReSearch(),
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
    await seedTypicalData(isar);
  });

  goldenTest(
    'renders the idle quick-picks state',
    fileName: 're_search_idle',
    pumpBeforeTest: pumpForAsyncData,
    builder: () => scenarios(isar),
  );
}
