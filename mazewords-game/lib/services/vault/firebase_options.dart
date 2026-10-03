import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Maze Words' own public registrations in the shared Neurantra vault project.
/// Kept separate from the default mazewords-app Crashlytics project.
class VaultFirebaseOptions {
  static FirebaseOptions? get current {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => ios,
      TargetPlatform.android => android,
      _ => null,
    };
  }

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDZS_Y-j1GmR3W7HVdju0HYC9T5TvgqpcQ',
    appId: '1:240784786332:ios:3237679a9e9459c7613e59',
    messagingSenderId: '240784786332',
    projectId: 'chaturang',
    databaseURL: 'https://chaturang-default-rtdb.firebaseio.com',
    storageBucket: 'chaturang.firebasestorage.app',
    iosBundleId: 'com.mazewords.app',
  );
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyA7UX6dWG9LZZ0TuT8HE0uU3lJaGmoEp1g',
    appId: '1:240784786332:android:506b423f135e5dc2613e59',
    messagingSenderId: '240784786332',
    projectId: 'chaturang',
    databaseURL: 'https://chaturang-default-rtdb.firebaseio.com',
    storageBucket: 'chaturang.firebasestorage.app',
  );
}
