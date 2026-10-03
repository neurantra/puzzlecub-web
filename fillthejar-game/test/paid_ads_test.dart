import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/services/services.dart';
import 'package:fill_the_jar/services/audience.dart';
import 'package:fill_the_jar/ui/game_screen.dart';
import 'package:fill_the_jar/ui/vault_sheet.dart';
import 'widget_test.dart' show session;

void main() {
  test(
    'any paid pack blocks ad SDK eligibility and interstitial cadence',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final game = session(freePlayLimited: true);
      final ads = RewardAds(allowed: true, eligible: () => !game.adsRemoved);
      addTearDown(ads.dispose);
      game.complete = true;
      for (var i = 0; i < 3; i++) {
        expect(game.recordCompletedTransition(), isFalse);
      }
      expect(game.recordCompletedTransition(), isTrue);
      expect(ads.supported, isTrue);
      for (final pack in ['animals', 'vehicles', 'landscapes', 'all']) {
        game.updatePaidAccess({pack});
        game.selectPictureTheme(null);
        expect(game.adsRemoved, isTrue);
        expect(ads.supported, isFalse);
        expect(await ads.show(), RewardOutcome.unavailable);
        expect(game.recordCompletedTransition(), isFalse);
        expect(game.interstitialProgress, 0);
      }
      game.updatePaidAccess({});
      expect(ads.supported, isTrue);
      expect(game.adsRemoved, isFalse);
    },
  );
  testWidgets('paid plain wood hides banner, promotions and hint-ad offer', (
    tester,
  ) async {
    final game = session(freePlayLimited: true)..updatePaidAccess({'animals'});
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          session: game,
          audience: Audience(1990),
          banner: const Text('test-banner'),
          bannerSize: const Size(320, 50),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('test-banner'), findsNothing);
    expect(find.text('Play PuzzleCub'), findsNothing);
    await tester.tap(find.byTooltip('Hint · 10 coins'));
    await tester.pumpAndSettle();
    expect(find.textContaining('View ad'), findsNothing);
    expect(find.textContaining('Use 10 coins'), findsOneWidget);
  });
  testWidgets('paid vault has no rewarded-ad button', (tester) async {
    final game = session(freePlayLimited: true)..updatePaidAccess({'vehicles'});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VaultSheet(
            game: game,
            adLabel: 'View ad',
            reward: () => fail('paid ad'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('View ad'), findsNothing);
    expect(
      find.text('Rewards are granted only after completion.'),
      findsNothing,
    );
  });
}
