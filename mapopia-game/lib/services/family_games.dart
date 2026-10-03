import 'package:flutter/foundation.dart';

enum FamilyGame {
  puzzlecub(
    'Puzzlecub',
    'A collection of clever little puzzles',
    '6768766852',
    'com.sumquest.app',
  ),
  fillTheJar(
    'Fill the Jar',
    'A little space. A perfect fit.',
    '6813074285',
    'com.fillthejar.app',
  ),
  mazeWords(
    'Maze Words',
    'Run the maze. Find the words.',
    '6816219346',
    'com.mazewords.app',
  ),
  chaturang(
    'Chaturang',
    'A new move on an ancient game',
    '6770267722',
    'com.chaturang.app',
  );

  const FamilyGame(this.title, this.description, this.appleId, this.package);
  final String title, description, appleId, package;
  Uri link(TargetPlatform platform) => Uri.parse(
    platform == TargetPlatform.android
        ? 'https://play.google.com/store/apps/details?id=$package'
        : 'https://apps.apple.com/app/id$appleId',
  );
}
