import 'package:flutter/material.dart';
import 'package:recallr/app_routes.dart';
import 'package:recallr/theme/controller/theme_controller.dart';
import 'package:recallr/theme/recallr_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
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
