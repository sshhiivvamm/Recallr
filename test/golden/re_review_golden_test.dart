import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recallr/core/database/providers/isar_provider.dart';
import 'package:recallr/core/features/view/re_review.dart';
import 'package:recallr/theme/recallr_theme.dart';

import 'fixtures.dart';
import 'golden_helpers.dart';

/// `ReReview` loads its queue via a one-shot `ref.read(...future)` inside
/// `addPostFrameCallback`, fired on the very first frame — unlike every
/// other screen here, it doesn't `ref.watch` reactively. `isarProvider`
/// needs at least one microtask to flip from loading to data even when its
/// underlying future is already complete, so on a fresh `ProviderScope`
/// the callback races ahead of it and `linkRepositoryProvider` throws
/// ("Isar loading") with no retry. Pre-warming a `ProviderContainer` (i.e.
/// actually awaiting `isarProvider.future` before the first frame) and
/// reusing it via `UncontrolledProviderScope` avoids the race — `goldenApp`
/// can't do this since its `ProviderScope` builds+resolves its container
/// lazily on first pump.
Future<Widget> _warmedReviewApp({
  required Isar isar,
  required Brightness brightness,
}) async {
  final container = ProviderContainer(
    overrides: [isarProvider.overrideWith((ref) async => isar)],
  );
  await container.read(isarProvider.future);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: const ReReview(),
    ),
  );
}

void main() {
  GoldenTestGroup scenarios(Widget light, Widget dark) => GoldenTestGroup(
        columns: 1,
        scenarioConstraints: BoxConstraints.tight(goldenPhoneSize),
        children: [
          GoldenTestScenario(name: 'light', child: light),
          GoldenTestScenario(name: 'dark', child: dark),
        ],
      );

  // Sm2Service.isDue() treats a null smNextReview as due, and none of the
  // fixture links set it — so the seeded set is already a non-empty queue.
  group('populated', () {
    late Widget light;
    late Widget dark;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final isar = await openGoldenIsar();
      await seedTypicalData(isar);
      light = await _warmedReviewApp(isar: isar, brightness: Brightness.light);
      dark = await _warmedReviewApp(isar: isar, brightness: Brightness.dark);
    });

    goldenTest(
      'renders a due review card',
      fileName: 're_review_populated',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(light, dark),
    );
  });

  group('empty', () {
    late Widget light;
    late Widget dark;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final isar = await openGoldenIsar();
      light = await _warmedReviewApp(isar: isar, brightness: Brightness.light);
      dark = await _warmedReviewApp(isar: isar, brightness: Brightness.dark);
    });

    goldenTest(
      'renders the all-caught-up state',
      fileName: 're_review_empty',
      pumpBeforeTest: pumpForAsyncData,
      builder: () => scenarios(light, dark),
    );
  });
}
