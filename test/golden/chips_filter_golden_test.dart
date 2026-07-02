import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:recallr/common/chips_filter.dart';
import 'package:recallr/theme/recallr_colors.dart';

import 'golden_helpers.dart';

/// Small presentational fragments from `lib/common/chips_filter.dart` — no
/// providers, no Isar data. Laid out together in one gallery Scaffold so a
/// single golden covers every variant (active/inactive chip, selected/
/// unselected toggle, empty state, skeleton) without a separate file per
/// widget.
class _ChipsGallery extends StatelessWidget {
  const _ChipsGallery();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppFilterChip(
                    label: 'Design',
                    icon: Icons.palette_outlined,
                    active: true,
                    onTap: () {},
                    c: c,
                    theme: theme,
                  ),
                  AppFilterChip(
                    label: 'Dev',
                    icon: Icons.code_rounded,
                    active: false,
                    onTap: () {},
                    c: c,
                    theme: theme,
                  ),
                  ClearChip(count: 2, onTap: () {}, c: c, theme: theme),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ViewToggleBtn(
                    icon: Icons.grid_view_rounded,
                    selected: true,
                    onTap: () {},
                    c: c,
                  ),
                  const SizedBox(width: 8),
                  ViewToggleBtn(
                    icon: Icons.view_list_rounded,
                    selected: false,
                    onTap: () {},
                    c: c,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SkeletonCard(c: c),
              const SizedBox(height: 8),
              SkeletonCard(c: c),
              const SizedBox(height: 20),
              SizedBox(
                height: 260,
                child: EmptyState(c: c, theme: theme),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  Widget scenario(Isar isar, Brightness brightness) => goldenApp(
        isar: isar,
        brightness: brightness,
        child: const _ChipsGallery(),
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
    'renders chip/toggle/empty/skeleton fragments',
    fileName: 'chips_filter_gallery',
    pumpBeforeTest: pumpForAsyncData,
    builder: () => scenarios(isar),
  );
}
