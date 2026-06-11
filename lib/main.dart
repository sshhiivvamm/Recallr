import 'package:flutter/material.dart';
import 'package:recallr/app_routes.dart';
import 'package:recallr/theme/controller/theme_controller.dart';
import 'package:recallr/theme/recallr_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/notification_service.dart';
import 'core/services/share_intent_service.dart';

/// URL shared to launch the app — consumed by MainNavigation on first frame.
String? pendingSharedUrl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final prefs = await SharedPreferences.getInstance();
  onboardingDone = prefs.getBool('onboarding_done') ?? false;
  // Grab any URL that launched the app via share intent
  pendingSharedUrl = await ShareIntentService.getInitialUrl();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: "Recallr",

      routerConfig: ReNav.router,

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),

      themeMode: themeMode,

      debugShowCheckedModeBanner: false,
    );
  }
}
