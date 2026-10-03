import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/game/geometry.dart';
import 'package:fill_the_jar/services/audience.dart';
import 'package:fill_the_jar/services/services.dart';
import 'package:fill_the_jar/ui/game_screen.dart';
import 'package:fill_the_jar/ui/picture_art.dart';
import 'package:fill_the_jar/ui/landing_arrows.dart';
import 'widget_test.dart' show session;

class FakeAds extends RewardAds {
  final Future<RewardOutcome> Function() result;
  int calls = 0;
  FakeAds(this.result) : super(allowed: true);
  @override
  bool get simulatedPreview => false;
  @override
  Future<RewardOutcome> show() {
    calls++;
    return result();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final id = (call.arguments as Map)['playerId'];
          messenger.setMockMethodCallHandler(
            MethodChannel('xyz.luan/audioplayers/events/$id'),
            (_) async => null,
          );
        }
        return null;
      },
    );
  });

  test('packs gate pictures, charge once, and persist across packs', () {
    final game = session()..coins = 29;
    expect(game.unlockPicturePack('animals'), isFalse);
    expect(game.unlockPictureTheme('tiger', rewarded: true), isFalse);
    expect(game.unlockPicturePack('missing'), isFalse);
    game.coins = 30;
    expect(game.unlockPicturePack('animals'), isTrue);
    expect(game.coins, 0);
    expect(game.ownedPictureThemes, isEmpty);
    expect(game.pictureClues, isFalse);
    expect(game.unlockPicturePack('animals'), isTrue);
    expect(game.coins, 0);
    expect(game.selectPictureTheme('tiger'), isFalse);
    expect(game.unlockPictureTheme('tiger', rewarded: true), isTrue);
    game.coins = 90;
    expect(game.unlockPicturePack('landscapes'), isTrue);
    expect(game.unlockPictureTheme('alpine-lake'), isTrue);
    expect(game.coins, 0);
    final restored = session()..restore(game.encode());
    expect(restored.ownedPicturePacks, {'animals', 'landscapes'});
    expect(restored.ownedPictureThemes, {'tiger', 'alpine-lake'});
    expect(restored.activePictureTheme, 'alpine-lake');
    expect(restored.selectPictureTheme('tiger'), isTrue);
    expect(restored.activePictureTheme, 'tiger');
  });

  test('theme purchase is affordable, permanent, idempotent and persisted', () {
    final game = session()
      ..unlockPicturePack('animals')
      ..coins = 59;
    expect(game.unlockPictureTheme('woodland-fox'), isFalse);
    expect(game.coins, 59);
    expect(game.unlockPictureTheme('unknown', rewarded: true), isFalse);
    game.coins = 60;
    expect(game.unlockPictureTheme('woodland-fox'), isTrue);
    expect(game.coins, 0);
    expect(game.unlockPictureTheme('woodland-fox'), isTrue);
    expect(game.coins, 0);
    game.showPictureGuide = true;
    game.earnHintCredit();
    game.load(game.levels[7]);
    final restored = session()..restore(game.encode());
    expect(restored.activePictureTheme, 'woodland-fox');
    expect(restored.ownedPictureThemes, {'woodland-fox'});
    expect(restored.showPictureGuide, isTrue);
    expect(restored.hintCredits, 1);
    restored.selectPictureTheme(null);
    expect(restored.pictureClues, isFalse);
    expect(restored.selectPictureTheme('woodland-fox'), isTrue);
    final old = jsonDecode(game.encode()) as Map<String, dynamic>;
    old.remove('ownedPictureThemes');
    old.remove('activePictureTheme');
    old.remove('hintCredits');
    final legacy = session()..restore(jsonEncode(old));
    expect(legacy.pictureClues, isFalse);
    expect(legacy.hintCredits, 0);
    expect(legacy.selectPictureTheme('woodland-fox'), isFalse);
  });

  test(
    'wallet/reward locks prevent theme spends and hint credits spend once',
    () {
      final game = session();
      game.walletBusy = true;
      expect(game.unlockPictureTheme('woodland-fox'), isFalse);
      game.walletBusy = false;
      game.rewardBusy = true;
      expect(game.unlockPictureTheme('woodland-fox'), isFalse);
      game.rewardBusy = false;
      game.earnHintCredit();
      expect(game.buyHint(useCredit: true), isTrue);
      expect(game.hintCredits, 0);
      expect(game.coins, 60);
      expect(game.hintedPlacement, isNotNull);
      expect(game.buyHint(useCredit: true), isFalse);
      game.rotate();
      expect(game.hintedPlacement, isNull);
    },
  );

  test('hints work after an interchangeable block is taken first', () {
    final game = session();
    game.load(game.levels[7]);
    final steps = solution(game.puzzle);
    final target = steps.firstWhere(
      (p) =>
          game.puzzle.pieces.any((q) => q.id != p.id && q.pileKey == p.pileKey),
    );
    final alternate = game.puzzle.pieces.firstWhere(
      (p) => p.id != target.id && p.pileKey == target.pileKey,
    );
    for (final p in steps) {
      game.board.add(p.id == target.id ? alternate.at(p.x, p.y) : p);
      if (p.id == target.id) break;
    }
    expect(nextHint(game.puzzle, game.board), isNotNull);
    expect(game.buyHint(), isTrue);
    while (!game.complete) {
      final hint = nextHint(game.puzzle, game.board);
      expect(hint, isNotNull);
      game.select(hint!);
      game.aim(hint.x, grab: 0);
      expect(game.drop(), isTrue);
    }
  });

  testWidgets(
    'same destination yields identical artwork for swapped and rotated squares',
    (tester) async {
      await tester.runAsync(() async {
        final old = PictureArt.image.value;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 40, 40),
          Paint()..color = Colors.red,
        );
        canvas.drawRect(
          const Rect.fromLTWH(20, 0, 20, 40),
          Paint()..color = Colors.blue,
        );
        final drawing = recorder.endRecording();
        final art = await drawing.toImage(40, 40);
        drawing.dispose();
        PictureArt.image.value = art;
        const a = Piece(
          id: 1,
          x: 0,
          y: 0,
          w: 1,
          h: 1,
          points: [Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(0, 1)],
        );
        final b = Piece(id: 2, x: 0, y: 0, w: 1, h: 1, points: a.points);
        final puzzle = Puzzle(number: 1, title: '', w: 2, h: 2, pieces: [a, b]);
        Future<List<int>> render(Piece p) async {
          final rec = ui.PictureRecorder();
          final c = Canvas(rec);
          final clip = Path()
            ..addPolygon(p.points.map((v) => v * 20).toList(), true);
          PictureArt.fragment(c, clip, p, puzzle, Offset.zero, 20);
          final picture = rec.endRecording();
          final img = await picture.toImage(20, 20);
          picture.dispose();
          final bytes = await img.toByteData();
          img.dispose();
          return bytes!.buffer.asUint8List().toList();
        }

        try {
          final first = await render(a);
          expect(await render(b.rotated()), first);
          expect(await render(b.at(1, 0)), isNot(first));
        } finally {
          PictureArt.image.value = old;
          art.dispose();
        }
      });
    },
  );

  for (final outcome in RewardOutcome.values) {
    testWidgets('theme ad $outcome only grants an earned reward', (
      tester,
    ) async {
      final game = session()
        ..unlockPicturePack('animals')
        ..coins = 0;
      final ads = FakeAds(() async => outcome);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            session: game,
            audience: Audience(1990),
            rewardAds: ads,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Picture Themes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pack-animals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picture-woodland-fox')));
      await tester.pumpAndSettle();
      final watch = find.text('View ad · unlock forever');
      await tester.ensureVisible(watch);
      await tester.tap(watch);
      await tester.pumpAndSettle();
      expect(ads.calls, 1);
      expect(game.pictureClues, outcome == RewardOutcome.earned);
      expect(game.coins, 0);
      expect(game.rewardBusy, isFalse);
    });
    testWidgets('hint ad $outcome only applies an earned hint', (tester) async {
      final game = session()
        ..unlockPicturePack('animals')
        ..coins = 0;
      final ads = FakeAds(() async => outcome);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            session: game,
            audience: Audience(1990),
            rewardAds: ads,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hint · 10 coins'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View ad · 1 hint'));
      await tester.pumpAndSettle();
      expect(game.selected != null, outcome == RewardOutcome.earned);
      expect(game.coins, 0);
      expect(game.hintCredits, 0);
      if (outcome == RewardOutcome.earned) {
        expect(
          tester.widget<LandingArrows>(find.byType(LandingArrows)).recommended,
          isNotNull,
        );
      }
    });
  }

  testWidgets(
    'closing store during an ad still grants one theme and prevents duplicate requests',
    (tester) async {
      final game = session()
        ..unlockPicturePack('animals')
        ..coins = 60;
      final done = Completer<RewardOutcome>();
      final ads = FakeAds(() => done.future);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            session: game,
            audience: Audience(1990),
            rewardAds: ads,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Picture Themes'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pack-animals')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picture-woodland-fox')));
      await tester.pumpAndSettle();
      final watch = find.text('View ad · unlock forever');
      await tester.ensureVisible(watch);
      await tester.tap(watch);
      await tester.pump();
      await tester.tap(watch);
      await tester.pump();
      expect(ads.calls, 1);
      Navigator.of(tester.element(watch)).pop();
      await tester.pump();
      done.complete(RewardOutcome.earned);
      await tester.pumpAndSettle();
      expect(game.ownedPictureThemes, {'woodland-fox'});
      expect(game.coins, 60);
      expect(game.rewardBusy, isFalse);
    },
  );
}
