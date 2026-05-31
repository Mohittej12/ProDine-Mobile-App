import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pro_dine/core/theme/app_theme.dart';
import 'package:pro_dine/routing/app_router.dart';
import 'package:pro_dine/core/services/providers/employee_auth_provider.dart';
import 'package:pro_dine/core/services/providers/auth_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeAuthProvider()),
      ],
      child: MaterialApp.router(
        title: 'Pro Dine',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
