import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:recallr/core/features/view/re_reader.dart';
import 'package:recallr/theme/recallr_colors.dart';

import 'golden_helpers.dart';

/// `ReReader` constructs a real `WebViewController`/`WebViewWidget` in
/// `initState`/`build` unconditionally — no platform WebView implementation
/// is registered in a headless `flutter test` run, so the full screen can't
/// be golden-tested without a substantial fake `WebViewPlatform`. Per the
/// documented plan (DOCUMENTATION.md § 5.13.1), we golden only the chrome:
/// `ReaderTopBar` (made public specifically for this) plus a placeholder
/// standing in for the WebView content area — the only thing that couldn't
/// be exercised this way is the WebView itself.
class _ReaderChromePreview extends StatelessWidget {
  const _ReaderChromePreview({required this.loading, required this.readerMode});

  final bool loading;
  final bool readerMode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          ReaderTopBar(
            title: 'Flutter Performance Deep Dive',
            loading: loading,
            readerMode: readerMode,
            c: c,
            onBack: () {},
            onToggleReader: () {},
            onOpenExternal: () {},
            onViewHighlights: () {},
          ),
          if (loading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: c.border,
              color: c.accent,
            ),
          Expanded(
            child: Container(
              color: c.surfaceElevated,
              alignment: Alignment.center,
              child: Text(
                'WebView content\n(not rendered in golden tests)',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textHint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  Widget scenario(Isar isar, Brightness brightness, {required bool loading, required bool readerMode}) =>
      goldenApp(
        isar: isar,
        brightness: brightness,
        child: _ReaderChromePreview(loading: loading, readerMode: readerMode),
      );

  GoldenTestGroup scenarios(Isar isar, {required bool loading, required bool readerMode}) =>
      GoldenTestGroup(
        columns: 1,
        scenarioConstraints: BoxConstraints.tight(goldenPhoneSize),
        children: [
          GoldenTestScenario(
            name: 'light',
            child: scenario(isar, Brightness.light, loading: loading, readerMode: readerMode),
          ),
          GoldenTestScenario(
            name: 'dark',
            child: scenario(isar, Brightness.dark, loading: loading, readerMode: readerMode),
          ),
        ],
      );

  late Isar isar;

  setUp(() async {
    isar = await openGoldenIsar();
  });

  goldenTest(
    'renders the loaded chrome',
    fileName: 're_reader_chrome_loaded',
    pumpBeforeTest: pumpForAsyncData,
    builder: () => scenarios(isar, loading: false, readerMode: false),
  );

  goldenTest(
    'renders the loading chrome with reader mode active',
    fileName: 're_reader_chrome_loading',
    pumpBeforeTest: pumpForAsyncData,
    builder: () => scenarios(isar, loading: true, readerMode: true),
  );
}
