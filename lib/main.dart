import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_providers.dart';
import 'theme/qt_theme.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: GstBillingApp(),
    ),
  );
}

class GstBillingApp extends ConsumerWidget {
  const GstBillingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkTheme = ref.watch(qtThemeModeProvider);

    return MaterialApp(
      title: 'Qt GST Billing Workbench',
      debugShowCheckedModeBanner: false,
      theme: QtTheme.getLightTheme(),
      darkTheme: QtTheme.getDarkTheme(),
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
