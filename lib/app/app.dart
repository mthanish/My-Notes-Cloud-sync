import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class MiNotesApp extends ConsumerWidget {
  final GoRouter? router;
  const MiNotesApp({super.key, this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'My Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router ?? appRouter,
    );
  }
}
