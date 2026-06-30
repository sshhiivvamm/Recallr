import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:recallr/app_routes.dart';
import 'package:recallr/theme/controller/theme_controller.dart';
import 'package:recallr/theme/recallr_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/isar_service.dart';
import 'core/services/backup_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/share_intent_service.dart';

/// URL shared to launch the app — consumed by MainNavigation on first frame.
String? pendingSharedUrl;

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash visible until we finish init work below.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Run in background — don't block runApp on timezone DB + channel init
  NotificationService.instance.init().ignore();
  final prefs = await SharedPreferences.getInstance();
  onboardingDone = prefs.getBool('onboarding_done') ?? false;
  pendingSharedUrl = await ShareIntentService.getInitialUrl();

  runApp(const ProviderScope(child: MyApp()));

  // Remove the native splash once the first Flutter frame is scheduled.
  FlutterNativeSplash.remove();

  // Trigger backup in background after app has started.
  IsarService.instance.db.then(
    (isar) => BackupService.instance.autoBackup(isar).ignore(),
  );
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
