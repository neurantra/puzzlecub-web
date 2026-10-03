import 'package:maze_words/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/domain/hunt_options.dart';
import 'package:maze_words/domain/hunt.dart';
import 'package:maze_words/domain/maze_level.dart';
import 'package:maze_words/ui/hunt_setup.dart';
import 'package:maze_words/ui/hunt_screen.dart';
import 'hunt_test.dart' show fixture;
import 'app_test.dart' show preload;

void main() {
  test('tiers cap hard at five minutes and nine attempts; categories add', () {
    for (final level in MazeLevel.values) {
      for (var time = 0; time < 3; time++) {
        for (var attempts = 0; attempts < 3; attempts++) {
          final options = HuntOptions(timeTier: time, attemptTier: attempts);
          expect(options.cost, 30 * (time + attempts));
          expect(options.seconds(level), lessThanOrEqualTo(300));
          expect(
            options.attempts(level),
            level.invalidAttemptBudget + attempts * 2,
          );
        }
      }
    }
    const max = HuntOptions(timeTier: 2, attemptTier: 2);
    expect(max.seconds(MazeLevel.hard), 300);
    expect(max.attempts(MazeLevel.hard), 9);
    final hunt = Hunt(maze: fixture(), level: MazeLevel.hard, options: max);
    for (var i = 0; i < 9; i++) {
      hunt.start(0);
      hunt.step(1);
      hunt.submit();
      expect(hunt.finished, i == 8);
    }
    final scenic = Hunt(maze: fixture(), level: MazeLevel.hard, relaxed: true);
    for (var i = 0; i < 20; i++) {
      scenic.start(0);
      scenic.step(1);
      scenic.submit();
    }
    expect(scenic.finished, false);
  });
  test('rare and maze totals remain independent', () {
    final hunt = Hunt(maze: fixture(), level: MazeLevel.easy);
    hunt.start(2);
    hunt.step(1);
    hunt.step(0);
    hunt.submit();
    expect(hunt.commonFound, 0);
    expect(hunt.rareFound, 1);
    hunt.start(0);
    hunt.step(1);
    hunt.step(2);
    hunt.submit();
    expect(hunt.commonFound, 1);
    expect(hunt.rareFound, 1);
  });
  test(
    'durable purchase failure and pending vault cannot debit coins',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PlayerStore(prefs, persist: (_) async => false);
      await expectLater(store.purchaseHunt(30), throwsStateError);
      expect(store.coins, 30);
      final pending = PlayerStore(prefs);
      await pending.reward(100);
      await pending.beginTransfer({'id': 'test', 'amount': 10, 'kind': 'bank'});
      expect(await pending.purchaseHunt(30), false);
      expect(pending.coins, 120);
    },
  );
  testWidgets(
    'settings persist by difficulty, cost nothing, and paid start has no modal',
    (tester) async {
      await preload(tester);
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = PlayerStore(await SharedPreferences.getInstance());
      await store.setBirthYear(1990);
      await store.reward(100);
      await tester.pumpWidget(MazeWordsApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('settings-level-hard')),
      );
      await tester.tap(find.byKey(const ValueKey('settings-level-hard')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('time-tier-2')));
      await tester.tap(find.byKey(const ValueKey('time-tier-2')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('attempt-tier-2')));
      await tester.tap(find.byKey(const ValueKey('attempt-tier-2')));
      await tester.pumpAndSettle();
      expect(store.coins, 130);
      expect(PlayerStore(store.prefs).huntOptions(MazeLevel.hard).cost, 120);
      expect(store.huntOptions(MazeLevel.easy).cost, 0);
      Navigator.pop(tester.element(find.byType(HuntSettings)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Hard'));
      await tester.tap(find.text('Hard'));
      await tester.pump();
      await tester.ensureVisible(find.text('Start hunt · 120 coins'));
      await tester.tap(find.text('Start hunt · 120 coins'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(HuntScreen), findsOneWidget);
      expect(store.coins, 10);
      expect(find.text('5:00'), findsOneWidget);
      expect(find.text('9 mistakes left'), findsOneWidget);
      await tester.ensureVisible(find.text('End hunt'));
      await tester.tap(find.text('End hunt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End hunt').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Another little adventure · 120 coins'),
      );
      expect(store.rounds, 1);
      expect(store.coins, 10);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('insufficient funds do not start; scenic ignores paid choices', (
    tester,
  ) async {
    await preload(tester);
    SharedPreferences.setMockInitialValues({});
    final store = PlayerStore(await SharedPreferences.getInstance());
    await store.setHuntOptions(MazeLevel.easy, const HuntOptions(timeTier: 2));
    PreparedHunt? ready;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () async {
                    ready = await prepareHunt(
                      context,
                      store,
                      MazeLevel.easy,
                      relaxed: false,
                    );
                  },
                  child: const Text('Play'),
                ),
                TextButton(
                  onPressed: () async {
                    ready = await prepareHunt(
                      context,
                      store,
                      MazeLevel.easy,
                      relaxed: true,
                    );
                  },
                  child: const Text('Scenic'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(ready, isNull);
    expect(store.coins, 30);
    expect(find.textContaining('Not enough coins'), findsOneWidget);
    await tester.tap(find.text('Scenic'));
    await tester.pumpAndSettle();
    expect(ready!.options.cost, 0);
    expect(store.coins, 30);
    expect(store.huntOptions(MazeLevel.easy).cost, 60);
    await store.setHuntOptions(MazeLevel.easy, const HuntOptions());
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(ready!.options.cost, 0);
    expect(store.coins, 30);
  });
}
