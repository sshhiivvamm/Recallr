import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/add_category_sheet.dart';
import '../../../core/database/providers/isar_provider.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/link_health_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../theme/controller/theme_controller.dart';
import '../../../theme/recallr_colors.dart';
import '../../features/category/tag_list_provider.dart';
import '../../features/collections/collection_provider.dart';
import '../../repositrories/link_providers/recent_links_provider.dart';

final _notifEnabledProvider =
    StateNotifierProvider<_NotifNotifier, bool>(
  (ref) => _NotifNotifier(),
);

class _ReminderTimeNotifier extends StateNotifier<TimeOfDay> {
  _ReminderTimeNotifier() : super(const TimeOfDay(hour: 10, minute: 0)) {
    _load();
  }

  Future<void> _load() async {
    final (h, m) = await NotificationService.instance.getReminderTime();
    state = TimeOfDay(hour: h, minute: m);
  }

  Future<void> update(int hour, int minute) async {
    await NotificationService.instance.setReminderTime(hour, minute);
    state = TimeOfDay(hour: hour, minute: minute);
  }
}

final _reminderTimeProvider =
    StateNotifierProvider<_ReminderTimeNotifier, TimeOfDay>(
  (ref) => _ReminderTimeNotifier(),
);

class _NotifNotifier extends StateNotifier<bool> {
  _NotifNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    state = await NotificationService.instance.isEnabled();
  }

  Future<void> toggle(bool val) async {
    if (val) {
      final granted =
          await NotificationService.instance.requestPermissions();
      if (!granted) return;
    }
    await NotificationService.instance.setEnabled(val);
    state = val;
  }
}

class ReProfile extends ConsumerWidget {
  const ReProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeProvider);

    final totalLinks = ref.watch(totalLinksCountProvider);
    final thisWeek = ref.watch(thisWeekLinksCountProvider);
    final tags = ref.watch(tagListProvider);
    final streakAsync = ref.watch(readingStreakProvider);
    final collectionsCount = ref.watch(collectionsCountProvider);
    final notifEnabled = ref.watch(_notifEnabledProvider);
    final dailyCounts = ref.watch(thisWeekDailyCountsProvider);
    final reminderTod = ref.watch(_reminderTimeProvider);

    final savedVal =
        totalLinks.maybeWhen(data: (n) => '$n', orElse: () => '—');
    final tagsVal =
        tags.maybeWhen(data: (t) => '${t.length}', orElse: () => '—');
    final weekVal =
        thisWeek.maybeWhen(data: (n) => '$n', orElse: () => '—');
    final streakVal =
        streakAsync.maybeWhen(data: (n) => '$n', orElse: () => '—');
    final collVal = collectionsCount.maybeWhen(
        data: (n) => '$n', orElse: () => '—');
    final weekInt =
        thisWeek.maybeWhen(data: (n) => n, orElse: () => 0);
    final dailyCountsVal = dailyCounts.maybeWhen(
        data: (counts) => counts, orElse: () => List.filled(7, 0));

    // True when the app is currently rendered in dark — accounts for system theme
    final effectiveDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);


    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('PROFILE', style: theme.headlineLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 4),

          // ── Identity card ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.accent.withValues(alpha: 0.12),
                  c.purple.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: c.accentBorder, width: 0.5),
            ),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1.0),
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  onEnd: () {},
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: c.accent.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/icons/logo.png',
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECALLR',
                        style: theme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: c.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your knowledge vault',
                        style: theme.bodySmall!
                            .copyWith(color: c.textHint),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: c.border, width: 0.5),
                  ),
                  child: Text(
                    'v1.0',
                    style: theme.labelSmall!
                        .copyWith(color: c.textHint),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Colored stat tiles ─────────────────────────
          Row(
            children: [
              _ColorStatTile(
                value: savedVal,
                label: 'Saved',
                icon: Icons.bookmark_rounded,
                accent: c.accent,
                dimColor: c.accentDim,
                c: c,
              ),
              const SizedBox(width: 10),
              _ColorStatTile(
                value: weekVal,
                label: 'This week',
                icon: Icons.trending_up_rounded,
                accent: c.green,
                dimColor: c.greenDim,
                c: c,
              ),
              const SizedBox(width: 10),
              _ColorStatTile(
                value: streakVal,
                label: 'Streak 🔥',
                icon: Icons.local_fire_department_rounded,
                accent: c.amber,
                dimColor: c.amberDim,
                c: c,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Reading insights card ──────────────────────
          _InsightsCard(weekCount: weekInt, dailyCounts: dailyCountsVal, c: c, theme: theme),

          const SizedBox(height: 24),

          // ── Section: Library ───────────────────────────
          _SectionLabel(label: 'LIBRARY', c: c, theme: theme),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.folder_outlined,
            iconColor: c.accent,
            label: 'Categories',
            subtitle: '$tagsVal categories',
            c: c,
            theme: theme,
            trailing: Icon(Icons.chevron_right_rounded,
                size: 18, color: c.textHint),
            onTap: () => context.go('/categories'),
          ),

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.folder_copy_outlined,
            iconColor: c.purple,
            label: 'Collections',
            subtitle: '$collVal collections',
            c: c,
            theme: theme,
            trailing: Icon(Icons.chevron_right_rounded,
                size: 18, color: c.textHint),
            onTap: () => context.go('/collections'),
          ),

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.add_circle_outline_rounded,
            iconColor: c.green,
            label: 'New Category',
            subtitle: 'Organise links by topic',
            c: c,
            theme: theme,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddCategorySheet(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Section: Data ──────────────────────────────
          _SectionLabel(label: 'DATA', c: c, theme: theme),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.ios_share_rounded,
            iconColor: c.green,
            label: 'Export as JSON',
            subtitle: 'Share all links as JSON file',
            c: c,
            theme: theme,
            onTap: () async {
              final isar = await ref.read(isarProvider.future);
              if (!context.mounted) return;
              try {
                await ExportService.instance.exportAsJson(isar);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.table_chart_outlined,
            iconColor: c.amber,
            label: 'Export as CSV',
            subtitle: 'Share all links as spreadsheet',
            c: c,
            theme: theme,
            onTap: () async {
              final isar = await ref.read(isarProvider.future);
              if (!context.mounted) return;
              try {
                await ExportService.instance.exportAsCsv(isar);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.health_and_safety_outlined,
            iconColor: c.coral,
            label: 'Check Link Health',
            subtitle: 'Scan for broken or dead links',
            c: c,
            theme: theme,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final isar = await ref.read(isarProvider.future);
              messenger.showSnackBar(
                const SnackBar(content: Text('Checking links…')),
              );
              await LinkHealthService.instance.checkAll(isar);
              if (!context.mounted) return;
              messenger.clearSnackBars();
              messenger.showSnackBar(
                const SnackBar(
                    content:
                        Text('Link health check complete')),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Section: Preferences ───────────────────────
          _SectionLabel(
              label: 'PREFERENCES', c: c, theme: theme),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: effectiveDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            iconColor: c.amber,
            label: effectiveDark ? 'Light Mode' : 'Dark Mode',
            subtitle: effectiveDark
                ? 'Switch to light theme'
                : 'Switch to dark theme',
            c: c,
            theme: theme,
            trailing: Switch.adaptive(
              value: effectiveDark,
              onChanged: (_) =>
                  ref.read(themeProvider.notifier).toggleTheme(),
              activeThumbColor: c.accent,
              activeTrackColor: c.accentDim,
            ),
            onTap: () =>
                ref.read(themeProvider.notifier).toggleTheme(),
          ),

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: c.purple,
            label: 'Daily Reminders',
            subtitle: notifEnabled
                ? 'Fires daily at ${reminderTod.format(context)}'
                : 'Turn on to get daily reminders',
            c: c,
            theme: theme,
            trailing: Switch.adaptive(
              value: notifEnabled,
              onChanged: (val) =>
                  ref.read(_notifEnabledProvider.notifier).toggle(val),
              activeThumbColor: c.accent,
              activeTrackColor: c.accentDim,
            ),
            onTap: () => ref
                .read(_notifEnabledProvider.notifier)
                .toggle(!notifEnabled),
          ),

          if (notifEnabled) ...[
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.schedule_rounded,
              iconColor: c.accent,
              label: 'Reminder Time',
              subtitle: reminderTod.format(context),
              c: c,
              theme: theme,
              trailing: Icon(Icons.chevron_right_rounded,
                  size: 18, color: c.textHint),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: reminderTod,
                );
                if (picked == null) return;
                await ref
                    .read(_reminderTimeProvider.notifier)
                    .update(picked.hour, picked.minute);
              },
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.send_rounded,
              iconColor: c.green,
              label: 'Send Test Notification',
              subtitle: 'Fires in 5 seconds',
              c: c,
              theme: theme,
              trailing: Icon(Icons.chevron_right_rounded,
                  size: 18, color: c.textHint),
              onTap: () async {
                await NotificationService.instance.sendTestNotification();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification fires in 5 seconds'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          // ── Section: About ─────────────────────────────
          _SectionLabel(label: 'ABOUT', c: c, theme: theme),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: c.purple,
            label: 'Recallr',
            subtitle: 'Version 1.0.0',
            c: c,
            theme: theme,
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              'THE KINETIC ARCHITECT',
              style: theme.labelSmall!.copyWith(
                color: c.textHint,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Colored Stat Tile ─────────────────────────────────────────────────────────

class _ColorStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accent;
  final Color dimColor;
  final AppColorScheme c;

  const _ColorStatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.dimColor,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(alpha: 0.20),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: dimColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: accent),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: theme.labelSmall!
                  .copyWith(color: c.textHint, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Insights Card ─────────────────────────────────────────────────────────────

class _InsightsCard extends StatelessWidget {
  final int weekCount;
  final List<int> dailyCounts;
  final AppColorScheme c;
  final TextTheme theme;

  const _InsightsCard({
    required this.weekCount,
    required this.dailyCounts,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final today = DateTime.now().weekday - 1;
    final maxCount = dailyCounts.isEmpty ? 1 : dailyCounts.reduce(max);
    final pattern = dailyCounts
        .map((c) => maxCount == 0 ? 0.0 : c / maxCount)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c.purpleDim,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.insights_rounded,
                    size: 16, color: c.purple),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved This Week',
                      style: theme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'This week',
                      style: theme.bodySmall!.copyWith(
                          color: c.textHint, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.greenDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded,
                        size: 12, color: c.green),
                    const SizedBox(width: 4),
                    Text(
                      '$weekCount saved',
                      style: theme.labelSmall!.copyWith(
                        color: c.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bars
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == today;
                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: Duration(
                              milliseconds: 400 + i * 60),
                          curve: Curves.easeOutCubic,
                          height: 44 * pattern[i] + 4,
                          decoration: BoxDecoration(
                            gradient: isToday
                                ? AppColors.brandGradient
                                : null,
                            color: isToday
                                ? null
                                : c.surfaceElevated,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: isToday
                                ? [
                                    BoxShadow(
                                      color: c.accent.withValues(
                                          alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 6),

          // Day labels
          Row(
            children: List.generate(7, (i) {
              final isToday = i == today;
              return Expanded(
                child: Center(
                  child: Text(
                    days[i],
                    style: theme.labelSmall!.copyWith(
                      color: isToday ? c.accent : c.textHint,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColorScheme c;
  final TextTheme theme;

  const _SectionLabel(
      {required this.label,
      required this.c,
      required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: theme.labelSmall!.copyWith(
          color: c.textHint,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final AppColorScheme c;
  final TextTheme theme;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: c.accent.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.bodySmall!.copyWith(
                            color: c.textHint, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
