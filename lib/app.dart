import 'package:flutter/material.dart';
import 'package:pro_dine/core/theme/app_theme.dart';
import 'package:pro_dine/routing/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pro Dine',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}