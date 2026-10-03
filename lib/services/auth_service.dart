import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import 'firebase_service.dart';
import 'firestore_service.dart';

class UserSession {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;

  const UserSession({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });
}

class FirebaseNotConfiguredException implements Exception {
  final String message;
  const FirebaseNotConfiguredException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final _sessionController = StreamController<UserSession?>.broadcast();
  UserSession? _currentSession;
  bool _googleSignInInitialized = false;

  Stream<UserSession?> get sessionStream => _sessionController.stream;
  UserSession? get currentSession => _currentSession;
  String get currentUid => _currentSession?.uid ?? 'guest_user';
  bool get isAuthenticated => _currentSession != null;

  AuthService();

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!kIsWeb && !_googleSignInInitialized) {
      try {
        await GoogleSignIn.instance.initialize(
          serverClientId: DefaultFirebaseOptions.serverClientId,
        );
        _googleSignInInitialized = true;
      } catch (e) {
        developer.log('Failed to initialize GoogleSignIn: $e', name: 'AuthService');
      }
    }
  }

  Future<void> init() async {
    await _ensureGoogleSignInInitialized();
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('cached_user_uid');

    if (FirebaseService.isConfiguredWithRealKeys && FirebaseService.isInitialized) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentSession = UserSession(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          isAnonymous: user.isAnonymous,
        );
      } else if (savedUid != null) {
        _currentSession = UserSession(
          uid: savedUid,
          email: prefs.getString('cached_user_email'),
          displayName: prefs.getString('cached_user_name'),
          photoUrl: prefs.getString('cached_user_photo'),
          isAnonymous: prefs.getBool('cached_user_is_anon') ?? false,
        );
      } else {
        _currentSession = null;
      }

      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _currentSession = UserSession(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoURL,
            isAnonymous: user.isAnonymous,
          );
        } else {
          if (!(_currentSession?.isAnonymous ?? false)) {
            _currentSession = null;
          }
        }
        _sessionController.add(_currentSession);
      });
    } else {
      // Local/offline mode: only load if user explicitly logged in or chose guest mode before
      if (savedUid != null) {
        _currentSession = UserSession(
          uid: savedUid,
          email: prefs.getString('cached_user_email'),
          displayName: prefs.getString('cached_user_name'),
          photoUrl: prefs.getString('cached_user_photo'),
          isAnonymous: prefs.getBool('cached_user_is_anon') ?? true,
        );
      } else {
        _currentSession = null;
      }
    }
    _sessionController.add(_currentSession);
  }

  /// Sign in with Google
  Future<UserSession?> signInWithGoogle() async {
    try {
      if (!FirebaseService.isConfiguredWithRealKeys || !FirebaseService.isInitialized) {
        throw const FirebaseNotConfiguredException(
          'Google Sign-In requires connecting your Firebase project. '
          'Please add google-services.json to android/app/ and configure SHA-1 in Firebase Console.',
        );
      }

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user != null) {
          _currentSession = UserSession(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );
          _sessionController.add(_currentSession);
          return _currentSession;
        }
      } else {
        await _ensureGoogleSignInInitialized();
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        if (googleAuth.idToken == null) {
          throw Exception('Google Sign-In failed: No ID token returned by Google Play Services.');
        }
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCredential.user;
        if (user != null) {
          _currentSession = UserSession(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_user_uid', user.uid);
          await prefs.setString('cached_user_email', user.email ?? '');
          await prefs.setString('cached_user_name', user.displayName ?? '');
          await prefs.setBool('cached_user_is_anon', false);

          final firestore = FirestoreService();
          unawaited(firestore.updateUserProfile(
            user.uid,
            email: user.email,
            displayName: user.displayName,
          ));

          _sessionController.add(_currentSession);
          return _currentSession;
        }
      }
    } catch (e) {
      developer.log('Error during Google Sign-In: $e', name: 'AuthService');
      rethrow;
    }
    return null;
  }

  /// Continue as Guest / Offline mode
  Future<UserSession> continueAsGuest({String? customName}) async {
    final name = (customName != null && customName.trim().isNotEmpty)
        ? customName.trim()
        : 'Guest User';

    if (FirebaseService.isConfiguredWithRealKeys && FirebaseService.isInitialized) {
      try {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        final user = userCredential.user!;
        _currentSession = UserSession(
          uid: user.uid,
          displayName: name,
          isAnonymous: true,
        );
      } catch (_) {
        _currentSession = UserSession(
          uid: 'offline_guest_${DateTime.now().millisecondsSinceEpoch}',
          displayName: name,
          isAnonymous: true,
        );
      }
    } else {
      _currentSession = UserSession(
        uid: 'offline_guest_${DateTime.now().millisecondsSinceEpoch}',
        displayName: name,
        isAnonymous: true,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user_uid', _currentSession!.uid);
    await prefs.setString('cached_user_name', _currentSession!.displayName ?? '');
    await prefs.setBool('cached_user_is_anon', true);

    _sessionController.add(_currentSession);
    return _currentSession!;
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      if (FirebaseService.isConfiguredWithRealKeys && FirebaseService.isInitialized) {
        await FirebaseAuth.instance.signOut();
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
    } catch (e) {
      developer.log('Error signing out: $e', name: 'AuthService');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_uid');
      await prefs.remove('cached_user_email');
      await prefs.remove('cached_user_name');
      await prefs.remove('cached_user_photo');
      await prefs.remove('cached_user_is_anon');

      _currentSession = null;
      _sessionController.add(null);
    }
  }

  void dispose() {
    _sessionController.close();
  }
}
