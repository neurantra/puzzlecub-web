import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/domain/maze_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlayerStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PlayerStore(await SharedPreferences.getInstance());
  });
  test('daily replay cannot mint additional coins', () async {
    expect(
      await store.record(
        level: MazeLevel.easy,
        relaxed: false,
        score: 100,
        found: 3,
        daily: 20260924,
      ),
      30,
    );
    expect(
      await store.record(
        level: MazeLevel.easy,
        relaxed: false,
        score: 200,
        found: 4,
        daily: 20260924,
      ),
      0,
    );
    expect(store.coins, 60);
    expect(store.best(MazeLevel.easy), 200);
  });
  test(
    'relaxed play has a separate best score and persists after restart',
    () async {
      await store.record(
        level: MazeLevel.easy,
        relaxed: true,
        score: 500,
        found: 5,
      );
      final reloaded = PlayerStore(await SharedPreferences.getInstance());
      expect(reloaded.best(MazeLevel.easy), 0);
      expect(reloaded.best(MazeLevel.easy, relaxed: true), 500);
      expect(reloaded.words, 5);
    },
  );
  test(
    'spending cannot produce a negative balance or accept negative cost',
    () async {
      expect(await store.spend(35), false);
      expect(await store.spend(-5), false);
      expect(await store.spend(5), true);
      expect(store.coins, 25);
    },
  );
  test('concurrent writes preserve the newest player state', () async {
    await Future.wait([
      store.reward(10),
      store.spend(5),
      store.set('sound', false),
    ]);
    final reloaded = PlayerStore(await SharedPreferences.getInstance());
    expect(reloaded.coins, 35);
    expect(reloaded.sound, false);
  });
}
