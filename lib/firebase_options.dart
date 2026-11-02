// File generated for TugasKu Firebase configuration
// To connect to a live Firebase project, you can either:
// 1. Run: `flutterfire configure --project=<your-firebase-project-id>`
// 2. Or pass environment flags when running/building:
//    `flutter run --dart-define=FIREBASE_PROJECT_ID=my-project --dart-define=FIREBASE_API_KEY=AIza...`

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'tugasku-student-app',
  );
  static const String _apiKeyWeb = String.fromEnvironment(
    'FIREBASE_API_KEY_WEB',
    defaultValue: 'AIzaSyDemoTugaskuWebApiKey1234567890',
  );
  static const String _apiKeyAndroid = String.fromEnvironment(
    'FIREBASE_API_KEY_ANDROID',
    defaultValue: 'AIzaSyDemoTugaskuAndroidApiKey123456789',
  );
  static const String _apiKeyIos = String.fromEnvironment(
    'FIREBASE_API_KEY_IOS',
    defaultValue: 'AIzaSyDemoTugaskuIosApiKey123456789',
  );
  static const String _appIdWeb = String.fromEnvironment(
    'FIREBASE_APP_ID_WEB',
    defaultValue: '1:1234567890:web:abcdef123456',
  );
  static const String _appIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
    defaultValue: '1:1234567890:android:abcdef123456',
  );
  static const String _appIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
    defaultValue: '1:1234567890:ios:abcdef123456',
  );
  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '1234567890',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyALrnv5zRPBxOzSG8q7rU1hAGF9CWYp2RY',
    appId: '1:661282330868:web:36e9508f733e3fc28fa6a1',
    messagingSenderId: '661282330868',
    projectId: 'tugasku-student-app',
    authDomain: 'tugasku-student-app.firebaseapp.com',
    storageBucket: 'tugasku-student-app.firebasestorage.app',
    measurementId: 'G-0R45XCXSB7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBI3dIfbFvF7pvQooqPtWZomfOMkp5Jn6w',
    appId: '1:661282330868:android:a6534b2018a73b058fa6a1',
    messagingSenderId: '661282330868',
    projectId: 'tugasku-student-app',
    storageBucket: 'tugasku-student-app.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _apiKeyIos,
    appId: _appIdIos,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: '$_projectId.appspot.com',
    iosBundleId: 'com.tugasku.app.tugasku',
  );
}
