import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';

import 'package:recallr/common/link_options_sheet.dart';
import 'package:recallr/core/database/providers/isar_provider.dart';
import 'package:recallr/data/models/Link/link_model.dart';
import 'package:recallr/theme/recallr_theme.dart';

import 'fixtures.dart';
import 'golden_helpers.dart';

/// `LinkOptionsSheet.build()` calls `GoRouter.of(context)` *and*
/// `ref.read(linkRepositoryProvider)` unconditionally on every build (not
/// gated behind `ref.watch`/`AsyncValue.when`), so it needs both a real
/// `GoRouter` ancestor (`goldenApp()`'s plain `MaterialApp` isn't enough)
/// and — like `re_review_golden_test.dart` — a pre-warmed `ProviderContainer`
/// so `isarProvider` isn't still `loading` on the very first frame (which
/// would otherwise throw "Isar loading" with no retry, same root cause as
/// `ReReview`'s one-shot `ref.read`).
Future<Widget> _scenario(Isar isar, LinkModel link, Brightness brightness) async {
  final container = ProviderContainer(
    overrides: [isarProvider.overrideWith((ref) async => isar)],
  );
  await container.read(isarProvider.future);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Consumer(
              builder: (context, ref, _) => LinkOptionsSheet(link: link, ref: ref),
            ),
          ),
        ),
      ),
    ],
  );

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      routerConfig: router,
    ),
  );
}

/// The favicon `CachedNetworkImage` triggers `flutter_cache_manager` to
/// schedule a 10s cleanup `Timer` (`CacheStore._scheduleCleanup`) — harmless,
/// but `flutter_test` asserts no timers are left pending at teardown, so we
/// advance the fake clock far enough to let it fire before returning.
Future<void> _pumpAndFlushCacheCleanupTimer(WidgetTester tester) async {
  await pumpForAsyncData(tester);
  await tester.pump(const Duration(seconds: 11));
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

  late Widget light;
  late Widget dark;

  setUp(() async {
    final isar = await openGoldenIsar();
    final fixtures = await seedTypicalData(isar);
    light = await _scenario(isar, fixtures.aiDesignLink, Brightness.light);
    dark = await _scenario(isar, fixtures.aiDesignLink, Brightness.dark);
  });

  goldenTest(
    'renders the link options sheet',
    fileName: 'link_options_sheet',
    pumpBeforeTest: _pumpAndFlushCacheCleanupTimer,
    builder: () => scenarios(light, dark),
  );
}
