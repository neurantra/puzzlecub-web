import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public client configuration for Fill the Jar's own registrations in the
/// shared chaturang project. A vault ID, unlike these keys, is private.
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
    appId: '1:240784786332:ios:72e071ad2d47cb7c613e59',
    messagingSenderId: '240784786332',
    projectId: 'chaturang',
    databaseURL: 'https://chaturang-default-rtdb.firebaseio.com',
    storageBucket: 'chaturang.firebasestorage.app',
    iosBundleId: 'com.fillthejar.app',
  );
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyA7UX6dWG9LZZ0TuT8HE0uU3lJaGmoEp1g',
    appId: '1:240784786332:android:c375d87a490d07f7613e59',
    messagingSenderId: '240784786332',
    projectId: 'chaturang',
    databaseURL: 'https://chaturang-default-rtdb.firebaseio.com',
    storageBucket: 'chaturang.firebasestorage.app',
  );
}
