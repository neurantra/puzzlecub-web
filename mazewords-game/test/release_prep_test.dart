import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/main.dart';
import 'package:maze_words/services/app_links.dart';
import 'package:maze_words/services/game_services.dart';
import 'app_test.dart' show preload;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<PlayerStore> player() async {
    SharedPreferences.setMockInitialValues({});
    return PlayerStore(await SharedPreferences.getInstance());
  }

  Future<void> finish(PlayerStore s, {bool cleared = true, int? daily}) =>
      s.record(
        level: MazeLevel.easy,
        relaxed: true,
        score: 100,
        found: 3,
        cleared: cleared,
        daily: daily,
      );

  test(
    'only three cleared mazes make an ad break, persisted across restart',
    () async {
      final s = await player();
      await finish(s, cleared: false);
      expect(s.interstitialDue, false);
      await finish(s);
      expect(s.interstitialDue, false);
      await finish(s);
      expect(s.interstitialDue, false);
      await finish(s);
      final restored = PlayerStore(await SharedPreferences.getInstance());
      expect(restored.interstitialDue, true);
      await restored.consumeInterstitialBreak();
      expect(restored.interstitialDue, false);
      await finish(restored);
      expect(restored.interstitialDue, false);
      await finish(restored);
      expect(restored.interstitialDue, false);
      await finish(restored);
      expect(restored.interstitialDue, true);
    },
  );
  test('a daily replay does not advance ad cadence', () async {
    final s = await player();
    await finish(s, daily: 42);
    await finish(s, daily: 42);
    expect(s.solvedTrails, 1);
    expect(s.interstitialDue, false);
  });
  test('an unavailable ad skips its break without a backlog', () async {
    final s = await player();
    await finish(s);
    await finish(s);
    await finish(s);
    final services = GameServices(s);
    await services.afterRound();
    expect(s.interstitialDue, false);
    await services.afterRound();
    expect(s.solvedTrails, 3);
    services.dispose();
  });
  test('store destinations use each sibling package and Apple listing', () {
    expect(FamilyGame.fillthejar.ios, endsWith('6813074285'));
    expect(FamilyGame.fillthejar.android, endsWith('com.fillthejar.app'));
    expect(FamilyGame.puzzlecub.android, endsWith('com.sumquest.app'));
    expect(AppLinks.rating(TargetPlatform.iOS), isNull);
  });
  testWidgets('adult settings include legal, rating and all three siblings', (
    tester,
  ) async {
    await preload(tester);
    final s = await player();
    await s.set('onboarded', true);
    await s.set('adult', true);
    await tester.pumpWidget(MazeWordsApp(store: s));
    await tester.pumpAndSettle();
    for (final game in FamilyGame.values) {
      await tester.scrollUntilVisible(
        find.text('Play ${game.title}'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Play ${game.title}'), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.text('Settings'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    for (final label in [
      'Licenses',
      'Privacy',
      'Terms',
      'Contact',
      'Rate the app',
      'Play Puzzlecub',
      'Play Chaturang',
      'Play Fill the Jar',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    await tester.ensureVisible(find.text('Licenses'));
    await tester.tap(find.text('Licenses'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JMdict'));
    await tester.pumpAndSettle();
    expect(find.textContaining('James William Breen'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Rate the app'));
    await tester.tap(find.text('Rate the app'));
    await tester.pumpAndSettle();
    expect(find.text('Thanks for playing!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
