import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';

/// MaterialApp.router wrapper for Firebase configuration.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'FireSight',
      theme: AppTheme.light,
    );
  }
}
