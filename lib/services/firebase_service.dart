import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Returns true only if actual Firebase keys have been configured rather than placeholders
  static bool get isConfiguredWithRealKeys {
    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
      return !apiKey.contains('Placeholder') && apiKey.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> init() async {
    if (!isConfiguredWithRealKeys) {
      developer.log(
        'Firebase note: Placeholder keys detected. Running in clean offline-local mode.',
        name: 'FirebaseService',
      );
      _isInitialized = false;
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;
      developer.log('Firebase initialized successfully', name: 'FirebaseService');
    } catch (e) {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        developer.log('Firebase already initialized: $e', name: 'FirebaseService');
      } else {
        developer.log(
          'Firebase initialization note: Running in offline-resilient mode ($e)',
          name: 'FirebaseService',
        );
        _isInitialized = false;
      }
    }
  }
}
