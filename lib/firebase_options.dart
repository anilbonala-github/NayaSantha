// Firebase configuration for NayaSantha (project nayasantha-c4c90).
// Hand-assembled from the console config files (google-services.json,
// GoogleService-Info.plist, web firebaseConfig). These are client-public
// identifiers — the sensitive server credential lives only in the backend's
// FIREBASE_CREDENTIALS_JSON, never here.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is only configured for Android, iOS and Web on NayaSantha.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDhL-S6zHiSGSTGErJaH-kIJQ3WsnX0zOo',
    appId: '1:518912994769:web:b03d6ed86a2cae9540c4f0',
    messagingSenderId: '518912994769',
    projectId: 'nayasantha-c4c90',
    authDomain: 'nayasantha-c4c90.firebaseapp.com',
    storageBucket: 'nayasantha-c4c90.firebasestorage.app',
    measurementId: 'G-RMDPDRG5RZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBP26eejXcsBr_l7BMfmXyaEEW7HWlHzEM',
    appId: '1:518912994769:android:f1e472f169da76c840c4f0',
    messagingSenderId: '518912994769',
    projectId: 'nayasantha-c4c90',
    storageBucket: 'nayasantha-c4c90.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBYp6GeC_Tk42XSex7Xfbu4yCjEs-EZ8Ag',
    appId: '1:518912994769:ios:9dc8de50e5ef9a3a40c4f0',
    messagingSenderId: '518912994769',
    projectId: 'nayasantha-c4c90',
    storageBucket: 'nayasantha-c4c90.firebasestorage.app',
    iosBundleId: 'com.nayasantha.app',
  );
}
