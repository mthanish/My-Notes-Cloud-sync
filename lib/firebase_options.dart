// File generated for MI Notes Clone Firebase Configuration.
// Replace the values below with your Firebase Project configurations
// from Firebase Console -> Project Settings -> General -> Your apps.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String serverClientId =
      '745984617493-ef9gnc0hd0idqv1fkd13mtj9e6u88sqj.apps.googleusercontent.com';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBcWzG16yQ2zxnpKJihmpXe8jah-raV2yg',
    appId: '1:745984617493:android:f4b14a387149a58a30f21c',
    messagingSenderId: '745984617493',
    projectId: 'my-notes-fd8bf',
    authDomain: 'my-notes-fd8bf.firebaseapp.com',
    storageBucket: 'my-notes-fd8bf.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcWzG16yQ2zxnpKJihmpXe8jah-raV2yg',
    appId: '1:745984617493:android:f4b14a387149a58a30f21c',
    messagingSenderId: '745984617493',
    projectId: 'my-notes-fd8bf',
    storageBucket: 'my-notes-fd8bf.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBcWzG16yQ2zxnpKJihmpXe8jah-raV2yg',
    appId: '1:745984617493:android:f4b14a387149a58a30f21c',
    messagingSenderId: '745984617493',
    projectId: 'my-notes-fd8bf',
    storageBucket: 'my-notes-fd8bf.firebasestorage.app',
  );
}
