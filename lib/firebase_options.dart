// GENERATED FILE — DO NOT EDIT MANUALLY.
// This is a placeholder. Run `flutterfire configure` to generate the real file.
//
// Steps:
// 1. Install Firebase CLI: npm install -g firebase-tools
// 2. Login: firebase login
// 3. Install FlutterFire CLI: dart pub global activate flutterfire_cli
// 4. Run: flutterfire configure --project=faktura-82ba8
//
// This will overwrite this file with the correct Firebase configuration.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace these with your actual Firebase project values

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDeO-1sxSnJYjXV8Tbs8pkF8e7LH4iUbmI',
    appId: '1:676752067338:android:31072609f3853aa43b08f3',
    messagingSenderId: '676752067338',
    projectId: 'faktura-82ba8',
    storageBucket: 'faktura-82ba8.firebasestorage.app',
  );

  // after running `flutterfire configure`

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: 'YOUR-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'faktura-82ba8',
    storageBucket: 'faktura-82ba8.firebasestorage.app',
    iosBundleId: 'com.example.fakturGen',
  );
}