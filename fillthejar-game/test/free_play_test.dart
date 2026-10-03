import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/game/geometry.dart';
import 'package:fill_the_jar/game/session.dart';
import 'package:fill_the_jar/ui/game_screen.dart';
import 'package:fill_the_jar/ui/themes_sheet.dart';
import 'widget_test.dart' show session;

void main() {
  test('free play includes one picture and blocks coin/ad bypasses', () {
    final game = session(freePlayLimited: true)..coins = 10000;
    expect(game.ownedPictureThemes, {GameSession.freePictureId});
    expect(game.selectPictureTheme(GameSession.freePictureId), isTrue);
    expect(game.selectPictureTheme(null), isTrue);
    expect(game.unlockPicturePack('vehicles'), isFalse);
    expect(game.unlockPictureTheme('tiger'), isFalse);
    expect(game.unlockPictureTheme('tiger', rewarded: true), isFalse);
    game.ownedPicturePacks.add('vehicles');
    game.ownedPictureThemes.add('vintage-train');
    expect(game.selectPictureTheme('vintage-train'), isFalse);
    expect(game.coins, 10000);
  });

  test('level ten is replayable; later levels and samplers cannot load', () {
    final game = session(freePlayLimited: true)..unlocked = 10;
    game.load(game.levels[9]);
    game.board = solution(game.puzzle);
    game.checkComplete();
    expect(game.unlocked, 10);
    expect(game.atFreePlayLimit, isTrue);
    expect(game.startNewJourney(), isFalse);
    game.load(game.levels[10]);
    expect(game.puzzle.number, 10);
    game.load(game.previews.first);
    expect(game.puzzle.number, 10);
    game.load(game.levels.first);
    expect(game.puzzle.number, 1);
    expect(game.complete, isFalse);
  });

  test('saved paid content cannot resume, but earned records survive', () {
    final previous = session()
      ..coins = 500
      ..unlocked = 40;
    previous.unlockPicturePack('vehicles');
    previous.unlockPictureTheme('vintage-train', rewarded: true);
    previous.load(previous.levels[39]);
    previous.beginSolve();
    final free = session(freePlayLimited: true)..restore(previous.encode());
    expect(free.puzzle.number, 10);
    expect(free.solving, isFalse);
    expect(free.board, isEmpty);
    expect(free.activePictureTheme, isNull);
    expect(free.coins, previous.coins);
    expect(free.unlocked, 40);
    expect(free.ownedPictureThemes, contains('vintage-train'));
    expect(free.selectPictureTheme('vintage-train'), isFalse);
    final again = session(freePlayLimited: true)..restore(free.encode());
    expect(again.puzzle.number, 10);
    expect(again.selectPictureTheme(GameSession.freePictureId), isTrue);
  });

  testWidgets(
    'free picture browser previews paid packs without unlock actions',
    (tester) async {
      final game = session(freePlayLimited: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemesSheet(
              game: game,
              adLabel: 'View ad',
              adsAllowed: true,
              buy: (_) async => fail('No coin purchase in free play'),
              watch: (_) async =>
                  fail('No rewarded picture unlock in free play'),
              buyPack: (_) async => fail('No coin pack unlock in free play'),
            ),
          ),
        ),
      );
      final vehicles = find.byKey(const ValueKey('pack-vehicles'));
      await tester.ensureVisible(vehicles);
      await tester.tap(vehicles);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picture-vintage-train')));
      await tester.pumpAndSettle();
      expect(find.textContaining('purchases coming soon'), findsOneWidget);
      expect(find.textContaining('Unlock ·'), findsNothing);
      expect(find.textContaining('View ad'), findsNothing);
      expect(game.activePictureTheme, isNull);
    },
  );

  testWidgets(
    'finishing ten offers replay without advancing or showing an ad',
    (tester) async {
      final game = session(freePlayLimited: true)..unlocked = 10;
      game.load(game.levels[9]);
      game.board = solution(game.puzzle);
      game.checkComplete();
      await tester.pumpWidget(MaterialApp(home: GameScreen(session: game)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Free journey complete'));
      await tester.pumpAndSettle();
      expect(find.text('You filled all 10 free jars!'), findsOneWidget);
      expect(game.puzzle.number, 10);
      expect(game.interstitialProgress, 0);
      await tester.tap(find.text('Keep playing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play this jar again'));
      await tester.pumpAndSettle();
      expect(game.puzzle.number, 10);
      expect(game.complete, isFalse);
    },
  );
}
