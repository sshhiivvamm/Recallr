import 'package:flutter/material.dart';
import '../../../theme/recallr_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: theme.titleMedium?.copyWith(color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.accent.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.accent.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: c.accent, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    'Your data stays on your device.',
                    style: theme.titleMedium?.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recallr is built with a local-first philosophy. '
                    'We do not collect, sell, or share your personal data.',
                    style: theme.bodySmall?.copyWith(
                        color: c.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _Section(
              title: '1. What We Collect',
              body:
                  'Recallr does not collect any personal information. All data you '
                  'create — saved links, notes, highlights, collections, and review '
                  'history — is stored exclusively on your device using a local database. '
                  'Nothing is transmitted to our servers.',
              c: c,
              theme: theme,
            ),

            _Section(
              title: '2. Links and Metadata',
              body:
                  'When you save a link, the app fetches publicly available metadata '
                  '(title, description, keywords, favicon) directly from the webpage '
                  'to populate the link card. This request goes from your device directly '
                  'to the destination website — Recallr servers are not involved.',
              c: c,
              theme: theme,
            ),

            _Section(
              title: '3. Local Storage',
              body:
                  'All app data is stored locally on your device:\n'
                  '• Links, notes, tags, and collections → local database\n'
                  '• App settings and preferences → device storage\n'
                  '• Automatic backups → local device storage only\n\n'
                  'Uninstalling the app permanently deletes all stored data.',
              c: c,
              theme: theme,
            ),

            _Section(
              title: '4. Notifications',
              body:
                  'Daily reminders are scheduled locally on your device using system '
                  'APIs. No notification data is sent to external servers. You can '
                  'disable notifications at any time from Settings → Notifications.',
              c: c,
              theme: theme,
            ),

            _Section(
              title: '5. Export',
              body:
                  'The export feature generates a JSON or CSV file from your local '
                  'data and shares it via your device\'s native share sheet. Recallr '
                  'does not upload your export to any cloud service.',
              c: c,
              theme: theme,
            ),

            _Section(
              title: '6. Third-Party Services',
              body:
                  'Recallr does not integrate with any third-party analytics, '
                  'advertising, or tracking services. No SDKs that collect behavioral '
                  'data are included in this app.',
              c: c,
              theme: theme,
            ),

            _Section(
              title: '7. Children\'s Privacy',
              body:
                  'Recallr is not directed at children under 13. Since no personal '
                  'data is collected from any user, children\'s privacy is inherently '
                  'protected.',
              c: c,
              theme: theme,
            ),

            _Section(
              title: '8. Changes to This Policy',
              body:
                  'If this Privacy Policy changes, the updated version will be '
                  'available within the app. Continued use after changes constitutes '
                  'acceptance of the updated policy.',
              c: c,
              theme: theme,
            ),

            _Section(
              title: '9. Contact',
              body: 'Questions or concerns? Reach us at:\nsupport@recallr.app',
              c: c,
              theme: theme,
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Last updated: June 2025\nEffective date: June 2025',
                style: theme.labelSmall?.copyWith(
                    color: c.textHint, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final AppColorScheme c;
  final TextTheme theme;

  const _Section({
    required this.title,
    required this.body,
    required this.c,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.titleSmall?.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.bodySmall?.copyWith(
              color: c.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
