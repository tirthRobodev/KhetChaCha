// File generated and configured for KhetChaCha Firebase integration
// based on android/app/google-services.json.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
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
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAt5P6K3nmQ9dG71B21fwcynqGQhSlxw88',
    appId: '1:342078322934:android:17882ed9e3b63e95ca14d7',
    messagingSenderId: '342078322934',
    projectId: 'khetchacha-d7afe',
    storageBucket: 'khetchacha-d7afe.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAt5P6K3nmQ9dG71B21fwcynqGQhSlxw88',
    appId: '1:342078322934:web:17882ed9e3b63e95ca14d7',
    messagingSenderId: '342078322934',
    projectId: 'khetchacha-d7afe',
    storageBucket: 'khetchacha-d7afe.firebasestorage.app',
    authDomain: 'khetchacha-d7afe.firebaseapp.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAt5P6K3nmQ9dG71B21fwcynqGQhSlxw88',
    appId: '1:342078322934:web:17882ed9e3b63e95ca14d7',
    messagingSenderId: '342078322934',
    projectId: 'khetchacha-d7afe',
    storageBucket: 'khetchacha-d7afe.firebasestorage.app',
  );
}
