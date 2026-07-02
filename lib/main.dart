import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:recallr/app_routes.dart';
import 'package:recallr/theme/controller/theme_controller.dart';
import 'package:recallr/theme/recallr_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'core/database/isar_service.dart';
import 'core/services/backup_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/share_intent_service.dart';
import 'firebase_options.dart';

/// URL shared to launch the app — consumed by MainNavigation on first frame.
String? pendingSharedUrl;

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Start Firebase in background — never block runApp on it.
  // Crashlytics wires up once it resolves (see below).
  final firebaseFuture = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Only await what routing needs: onboarding flag + pending share URL.
  // Wall time = max(prefs, shareIntent) ≈ 20–50 ms on device.
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    ShareIntentService.getInitialUrl(),
  ]);

  onboardingDone =
      (results[0] as SharedPreferences).getBool('onboarding_done') ?? false;
  pendingSharedUrl = results[1] as String?;

  // Start Isar BEFORE runApp — it opens in ~100–150 ms while Flutter builds
  // the widget tree (~50–100 ms), so home screen providers often resolve
  // before the first watch fires, eliminating the skeleton flash.
  IsarService.instance.db.then((isar) {
    BackupService.instance.autoBackup(isar).ignore();
  }).ignore();
  NotificationService.instance.init().ignore();

  runApp(const ProviderScope(child: MyApp()));

  // Remove splash after the first rendered frame — avoids a white flash.
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => FlutterNativeSplash.remove(),
  );

  // Backup whenever the user backgrounds the app so no saves are ever lost.
  WidgetsBinding.instance.addObserver(_BackupOnPauseObserver());

  // Wire up Crashlytics once Firebase is ready (background).
  firebaseFuture.then((_) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }).ignore();
}

class _BackupOnPauseObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      IsarService.instance.db.then((isar) {
        BackupService.instance.autoBackup(isar).ignore();
      }).ignore();
    }
  }
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
