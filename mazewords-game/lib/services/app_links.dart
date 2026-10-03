import 'package:flutter/foundation.dart';

class AppLinks {
  static const privacy = 'https://puzzlecub.com/privacy';
  static const terms = 'https://puzzlecub.com/terms';
  static const contact = 'https://neurantra.com/#contact';
  static const appleId = String.fromEnvironment('APPLE_APP_STORE_ID');
  static const storeRelease = bool.fromEnvironment('STORE_RELEASE');
  static String? rating(TargetPlatform platform) {
    if (!storeRelease) return null;
    if (platform == TargetPlatform.android) {
      return 'https://play.google.com/store/apps/details?id=com.mazewords.app';
    }
    if (platform == TargetPlatform.iOS && RegExp(r'^\d+$').hasMatch(appleId)) {
      return 'https://apps.apple.com/app/id$appleId?action=write-review';
    }
    return null;
  }
}

enum FamilyGame {
  puzzlecub(
    'Puzzlecub',
    'Bite-sized number puzzles',
    'https://apps.apple.com/app/id6768766852',
    'com.sumquest.app',
  ),
  chaturang(
    'Chaturang',
    'A new move on an ancient game',
    'https://apps.apple.com/app/id6770267722',
    'com.chaturang.app',
  ),
  fillthejar(
    'Fill the Jar',
    'A little space. A perfect fit.',
    'https://apps.apple.com/app/id6813074285',
    'com.fillthejar.app',
  );

  const FamilyGame(this.title, this.description, this.ios, this.package);
  final String title, description, ios, package;
  String get android =>
      'https://play.google.com/store/apps/details?id=$package';
}
