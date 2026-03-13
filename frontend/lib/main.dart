import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/themes/app_theme.dart';
import 'core/constants/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SpectrumApp()));
}

class SpectrumApp extends StatelessWidget {
  const SpectrumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}