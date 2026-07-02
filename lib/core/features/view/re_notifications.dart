import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/recallr_colors.dart';
import '../../services/notification_service.dart';
import '../../repositrories/link_providers/recent_links_provider.dart';
import '../notifications/notification_providers.dart';

class ReNotifications extends ConsumerWidget {
  const ReNotifications({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;

    final notifEnabled = ref.watch(notifEnabledProvider);
    final reminderTod = ref.watch(reminderTimeProvider);
    final dueCount = ref.watch(reviewDueCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('NOTIFICATIONS', style: theme.headlineLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 4),

          _SectionLabel(label: 'REVIEW', c: c, theme: theme),
          const SizedBox(height: 8),
          _ReviewCard(dueCount: dueCount, c: c, theme: theme),

          const SizedBox(height: 24),

          _SectionLabel(label: 'REMINDERS', c: c, theme: theme),
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
                  ref.read(notifEnabledProvider.notifier).toggle(val),
              activeThumbColor: c.accent,
              activeTrackColor: c.accentDim,
            ),
            onTap: () => ref
                .read(notifEnabledProvider.notifier)
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
                    .read(reminderTimeProvider.notifier)
                    .update(picked.hour, picked.minute);
              },
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.send_rounded,
              iconColor: c.green,
              label: 'Send Test Notification',
              subtitle: 'Fires immediately',
              c: c,
              theme: theme,
              trailing: Icon(Icons.chevron_right_rounded,
                  size: 18, color: c.textHint),
              onTap: () async {
                await NotificationService.instance.sendTestNotification();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Review Card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final int dueCount;
  final AppColorScheme c;
  final TextTheme theme;

  const _ReviewCard(
      {required this.dueCount, required this.c, required this.theme});

  @override
  Widget build(BuildContext context) {
    final hasDue = dueCount > 0;
    return GestureDetector(
      onTap: hasDue ? () => context.push('/review') : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasDue
                ? [
                    c.purple.withValues(alpha: 0.14),
                    c.accent.withValues(alpha: 0.06),
                  ]
                : [c.surface, c.surface],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasDue
                ? c.purple.withValues(alpha: 0.30)
                : c.border,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasDue ? c.purpleDim : c.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.psychology_rounded,
                color: hasDue ? c.purple : c.textHint,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDue
                        ? '$dueCount ${dueCount == 1 ? 'link' : 'links'} ready for review'
                        : "You're all caught up",
                    style: theme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDue
                        ? 'Tap to open your review queue'
                        : 'No links waiting for review right now',
                    style: theme.bodySmall!.copyWith(color: c.textHint),
                  ),
                ],
              ),
            ),
            if (hasDue)
              Icon(Icons.arrow_forward_rounded, size: 16, color: c.purple),
          ],
        ),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
