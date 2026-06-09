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

final _notifEnabledProvider = StateNotifierProvider<_NotifNotifier, bool>(
  (ref) => _NotifNotifier(),
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
      final granted = await NotificationService.instance.requestPermissions();
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

    final savedVal = totalLinks.maybeWhen(data: (n) => '$n', orElse: () => '—');
    final tagsVal = tags.maybeWhen(data: (t) => '${t.length}', orElse: () => '—');
    final weekVal = thisWeek.maybeWhen(data: (n) => '$n', orElse: () => '—');
    final streakVal = streakAsync.maybeWhen(data: (n) => '$n', orElse: () => '—');
    final collVal = collectionsCount.maybeWhen(data: (n) => '$n', orElse: () => '—');

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

          // ── App identity card ──────────────────────────
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
              border: Border.all(color: c.accentBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    color: Colors.white,
                    size: 26,
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
                        style: theme.bodySmall!.copyWith(color: c.textHint),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.border, width: 0.5),
                  ),
                  child: Text(
                    'v1.0',
                    style: theme.labelSmall!.copyWith(color: c.textHint),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Stats row ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Row(
              children: [
                _StatPill(label: 'Saved', value: savedVal, c: c, theme: theme),
                _VerticalDivider(c: c),
                _StatPill(label: 'This week', value: weekVal, c: c, theme: theme),
                _VerticalDivider(c: c),
                _StatPill(label: 'Streak 🔥', value: streakVal, c: c, theme: theme),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section: Library ──────────────────────────
          _SectionLabel(label: 'LIBRARY', c: c, theme: theme),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.folder_outlined,
            iconColor: c.accent,
            label: 'Categories',
            subtitle: '$tagsVal categories',
            c: c,
            theme: theme,
            trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.textHint),
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
            trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.textHint),
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

          // ── Section: Data ─────────────────────────────
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
                const SnackBar(content: Text('Link health check complete')),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Section: Preferences ──────────────────────
          _SectionLabel(label: 'PREFERENCES', c: c, theme: theme),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            iconColor: c.amber,
            label: themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
            subtitle: themeMode == ThemeMode.dark
                ? 'Switch to light theme'
                : 'Switch to dark theme',
            c: c,
            theme: theme,
            trailing: Switch.adaptive(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(themeProvider.notifier).toggleTheme(),
              activeThumbColor: c.accent,
              activeTrackColor: c.accentDim,
            ),
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: c.purple,
            label: 'Daily Reminders',
            subtitle: 'Revisit forgotten links daily at 10 AM',
            c: c,
            theme: theme,
            trailing: Switch.adaptive(
              value: notifEnabled,
              onChanged: (val) => ref.read(_notifEnabledProvider.notifier).toggle(val),
              activeThumbColor: c.accent,
              activeTrackColor: c.accentDim,
            ),
            onTap: () => ref.read(_notifEnabledProvider.notifier).toggle(!notifEnabled),
          ),

          const SizedBox(height: 24),

          // ── Section: About ────────────────────────────
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

          // ── Footer ────────────────────────────────────
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label, value;
  final AppColorScheme c;
  final TextTheme theme;

  const _StatPill({
    required this.label,
    required this.value,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: theme.labelSmall!.copyWith(color: c.textHint)),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final AppColorScheme c;
  const _VerticalDivider({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 0.5, height: 28, color: c.border,
        margin: const EdgeInsets.symmetric(horizontal: 8));
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final AppColorScheme c;
  final TextTheme theme;

  const _SectionLabel(
      {required this.label, required this.c, required this.theme});

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        style: theme.bodySmall!
                            .copyWith(color: c.textHint, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
