import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android system status & navigation bar styling matching dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize offline-first Hive local storage
  await LocalStorageService.init();

  // Purge any previously pre-loaded seed/screenshot notes from earlier runs
  final localStorage = LocalStorageService();
  await localStorage.purgeDemoSeedData();

  // Initialize Firebase (with resilient offline-first fallback)
  await FirebaseService.init();

  // Initialize AuthService
  final authService = AuthService();
  await authService.init();

  // Create router matching user's actual authentication status
  final router = createAppRouter(isAuthenticated: authService.isAuthenticated);

  runApp(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
      ],
      child: MiNotesApp(router: router),
    ),
  );
}
