// REPLACE THIS FILE — run 'flutterfire configure' against your own Firebase project.
//
// Install the CLI: dart pub global activate flutterfire_cli
// Then run:        flutterfire configure
//
// This stub exists only so the starter compiles. Calls to Firebase.initializeApp
// with these placeholder values WILL fail at runtime until you regenerate this
// file against your own Firebase project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.macOS:
        return _ios;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyAfdiGWqdtwfwrk_6MyuOrzu8wZVnRrEck',
    appId: '1:296005702366:ios:0777e0a2aff1121ab9a84f',
    messagingSenderId: '296005702366',
    projectId: 'chatapp-f5329',
    storageBucket: 'chatapp-f5329.firebasestorage.app',
    iosBundleId: 'dev.fathia.chatapp',
  );

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyAEfQIuz0XlPnh3Kfh5RDxVOR-fjoJSgCo',
    appId: '1:296005702366:android:3b2d184a7e781062b9a84f', // Standardizing this
    messagingSenderId: '296005702366',
    projectId: 'chatapp-f5329',
    storageBucket: 'chatapp-f5329.firebasestorage.app',
  );

  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: 'AIzaSyD7qGRK-ZkqIE3mYrkvvXUXCLpYJ7TiLOY',
    appId: '1:296005702366:web:0777e0a2aff1121ab9a84f',
    messagingSenderId: '296005702366',
    projectId: 'chatapp-f5329',
    storageBucket: 'chatapp-f5329.firebasestorage.app',
  );
}
