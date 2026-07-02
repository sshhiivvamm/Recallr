import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:recallr/core/database/providers/isar_provider.dart';
import 'package:recallr/data/models/Highlight/highlight_model.dart';
import 'package:recallr/data/models/Link/link_model.dart';
import 'package:recallr/data/models/Tag/tag_model.dart';
import 'package:recallr/data/models/collection_model.dart';
import 'package:recallr/theme/recallr_theme.dart';

/// Fixed phone viewport used for every screen golden so light/dark scenarios
/// render identically-sized surfaces.
const goldenPhoneSize = Size(390, 844);

int _isarCounter = 0;
bool _sqfliteFfiInitialized = false;

/// Mocks the `path_provider` method channel so `CachedNetworkImage` (used
/// for link thumbnails/favicons) doesn't throw `MissingPluginException`
/// when it tries to open its disk cache. Real network fetches still fail
/// (Flutter's test binding returns HTTP 400 for all requests), so
/// thumbnails render as their error/placeholder state — that's expected
/// and consistent across runs, not something golden tests need to avoid.
void mockPathProvider() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger = TestWidgetsFlutterBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    channel,
    (call) async => Directory.systemTemp.path,
  );
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}

/// `CachedNetworkImage`'s disk-cache bookkeeping (`flutter_cache_manager`)
/// opens a real sqflite database. There's no sqflite platform plugin
/// registered in a headless `flutter test` run, so without this,
/// `databaseFactory` throws "not initialized". `sqflite_common_ffi` is a
/// pure-Dart/FFI sqlite backend that works outside a real platform — set
/// once per process since `databaseFactory` is a global.
void ensureSqfliteFfiInitialized() {
  if (_sqfliteFfiInitialized) return;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  _sqfliteFfiInitialized = true;
}

/// Opens a fresh temp-directory Isar instance for a single golden test.
///
/// Screens read many file-private providers (e.g. `_tagLinksProvider` in
/// re_filtered_links.dart, `_searchResultsProvider` in re_search.dart) that
/// can't be overridden by identity from outside their file — they all bottom
/// out at [isarProvider] though, so overriding that with a real (but
/// temp/isolated) Isar instance is the one seam that reaches every screen.
Future<Isar> openGoldenIsar() async {
  mockPathProvider();
  ensureSqfliteFfiInitialized();
  _isarCounter++;
  final tempDir = await Directory.systemTemp.createTemp('golden_isar');
  final isar = await Isar.open(
    [LinkModelSchema, TagModelSchema, FolderModelSchema, HighlightModelSchema],
    directory: tempDir.path,
    name: 'golden_isar_$_isarCounter',
  );
  addTearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });
  return isar;
}

/// Wraps [child] with a [ProviderScope] (overriding [isarProvider] with
/// [isar], plus any [extraOverrides]) and a [MaterialApp] using the app's
/// real light/dark [AppTheme] so `context.colors`/`context.isDark` resolve
/// exactly as they do in the app.
Widget goldenApp({
  required Widget child,
  required Isar isar,
  required Brightness brightness,
  List<Override> extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      isarProvider.overrideWith((ref) async => isar),
      ...extraOverrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: child,
    ),
  );
}

/// Fixes the test binding's view to [size] so MediaQuery-driven layout
/// matches the GoldenTestScenario's rendered box, then restores it —
/// otherwise the override would bleed into later tests in the same file.
void setGoldenViewSize(WidgetTester tester, [Size size = goldenPhoneSize]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Fixes the golden view size, then pumps enough frames for Isar-backed
/// streams/futures to resolve. Intended as `goldenTest`'s `pumpBeforeTest`.
///
/// Deliberately NOT `pumpAndSettle` — several screens run infinite-repeat
/// `AnimationController`s (re_onboarding.dart) or periodic `Timer`s
/// (recallr_home.dart's word-cycle), which would make `pumpAndSettle` hang.
/// A bounded number of small pumps gives real async Isar operations time to
/// complete without ever waiting for "idle".
///
/// Every `StreamProvider` in this app is built on
/// `isar.linkModels.where().watch()`, which delivers events through a real
/// native `ReceivePort` — a genuine OS-level message, not a Dart
/// microtask/timer. `tester.pump(duration)` only advances Flutter's fake
/// clock and flushes already-arrived microtasks; it never actually returns
/// control to the real event loop, so a pending native watcher message can
/// sit undelivered forever no matter how many fake-time pumps you do (this
/// was the golden-suite blocker — see DOCUMENTATION.md § 5.13.1 history).
/// The fix: alternate a real `Future.delayed` (inside `tester.runAsync`, so
/// it actually yields to the real event loop and lets the native message
/// arrive) with a `tester.pump()` (to flush the resulting microtask into a
/// widget rebuild). One iteration was enough in isolated repro; `times`
/// gives generous headroom for slower CI machines.
Future<void> pumpForAsyncData(
  WidgetTester tester, {
  Size size = goldenPhoneSize,
  int times = 8,
}) async {
  setGoldenViewSize(tester, size);
  await tester.runAsync(() async {
    for (var i = 0; i < times; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 40));
    }
  });
}
