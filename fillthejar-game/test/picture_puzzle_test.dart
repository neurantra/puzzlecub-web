import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/game/session.dart';
import 'package:fill_the_jar/game/geometry.dart';
import 'package:fill_the_jar/main.dart';
import 'package:fill_the_jar/services/audience.dart';
import 'package:fill_the_jar/ui/game_screen.dart';
import 'package:fill_the_jar/ui/picture_art.dart';
import 'package:fill_the_jar/ui/wooden_jar.dart';
import 'package:fill_the_jar/ui/themes_sheet.dart';
import 'package:fill_the_jar/game/picture_theme.dart';
import 'widget_test.dart' show session;

GameSession pictureGame() {
  final source = session().levels[7];
  return GameSession(
      [
        Puzzle(
          number: 1,
          title: 'Woodland fox',
          preview: 'picture-fox',
          w: source.w,
          h: source.h,
          pieces: source.pieces,
        ),
      ],
      [],
      freePlayLimited: false,
    )
    ..unlockPicturePack('animals')
    ..unlockPictureTheme('woodland-fox', rewarded: true)
    ..motion = false
    ..sound = false
    ..haptics = false;
}

void main() {
  test('every pack has ten distinct bundled artworks', () {
    final ids = <String>{};
    final assets = <String>{};
    for (final pack in PicturePack.catalog) {
      expect(
        pack.pictures.length,
        greaterThanOrEqualTo(10),
        reason: pack.title,
      );
      for (final picture in pack.pictures) {
        expect(ids.add(picture.id), isTrue);
        expect(assets.add(picture.asset), isTrue);
        expect(File(picture.asset).existsSync(), isTrue, reason: picture.asset);
      }
    }
  });

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

  testWidgets('pack grids preview and activate pictures on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = session()..coins = 300;
    if (const bool.fromEnvironment('CAPTURE_PICTURE')) {
      await tester.runAsync(() async {
        await (FontLoader('Roboto')..addFont(
              Future.value(
                ByteData.sublistView(
                  File(
                    '/opt/homebrew/share/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
                  ).readAsBytesSync(),
                ),
              ),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
    }
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SafeArea(
              child: ThemesSheet(
                game: game,
                adLabel: 'View ad',
                adsAllowed: true,
                buyPack: (pack) async {
                  game.unlockPicturePack(pack.id);
                },
                buy: (picture) async {
                  game.unlockPictureTheme(picture.id);
                },
                watch: (picture) async {
                  game.unlockPictureTheme(picture.id, rewarded: true);
                },
              ),
            ),
          ),
        ),
      ),
    );
    for (final pack in PicturePack.catalog) {
      final button = find.byKey(ValueKey('pack-${pack.id}'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      if (const bool.fromEnvironment('CAPTURE_PICTURE')) {
        await tester.runAsync(() async {
          for (final picture in pack.pictures) {
            await precacheImage(AssetImage(picture.asset), key.currentContext!);
          }
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '../artifacts/pack-${pack.id}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      final picture = pack.pictures.first;
      await tester.tap(find.byTooltip('Preview ${picture.title}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock · 60 coins'));
      await tester.pumpAndSettle();
      expect(game.activePictureTheme, picture.id);
      await tester.tap(find.byTooltip('Back to pictures'));
      await tester.pumpAndSettle();
      game.selectPictureTheme(null);
      await tester.tap(find.byKey(ValueKey('picture-${picture.id}')));
      await tester.pumpAndSettle();
      expect(game.activePictureTheme, picture.id);
      await tester.tap(find.byTooltip('Back to packs'));
      await tester.pumpAndSettle();
    }
    expect(game.coins, 30);
    expect(tester.takeException(), isNull);
  });

  test('picture themes keep identical shapes in the same pile', () {
    final game = pictureGame();
    expect(game.groups.length, lessThan(game.puzzle.pieces.length));
    expect(
      game.groups.map((g) => g.members.length).reduce((a, b) => a + b),
      game.puzzle.pieces.length,
    );
  });
  test(
    'swapped picture fragments still win when their shapes fill the jar',
    () {
      final game = pictureGame();
      final pieces = game.puzzle.pieces;
      final a = pieces.firstWhere(
        (p) => pieces.any((q) => q.id != p.id && q.pileKey == p.pileKey),
      );
      final b = pieces.firstWhere(
        (p) => p.id != a.id && p.pileKey == a.pileKey,
      );
      game.board = [
        for (final p in pieces)
          if (p.id == a.id)
            a.at(b.x, b.y)
          else if (p.id == b.id)
            b.at(a.x, a.y)
          else
            p,
      ];
      game.checkComplete();
      expect(game.complete, isTrue);
    },
  );
  testWidgets('coin theme purchase and guide work on the current campaign', (
    tester,
  ) async {
    if (const bool.fromEnvironment('CAPTURE_PICTURE')) {
      await tester.runAsync(() async {
        await PictureArt.load();
        await WoodMaterial.load();
      });
    }
    final original = session()..coins = 90;
    original.select(original.puzzle.pieces.first);
    original.drop();
    final board = List.of(original.board);
    await tester.pumpWidget(
      JarApp(session: original, audience: Audience(2020)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Picture Themes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pack-animals')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock pack · 30 coins').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('picture-woodland-fox')));
    await tester.pumpAndSettle();
    expect(find.textContaining('View ad'), findsNothing);
    await tester.ensureVisible(find.text('Unlock · 60 coins'));
    await tester.tap(find.text('Unlock · 60 coins'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock · 60 coins').last);
    await tester.pumpAndSettle();
    expect(original.pictureClues, isTrue);
    expect(original.coins, 0);
    expect(original.board, board);
    await tester.ensureVisible(find.text('Back to puzzle'));
    await tester.tap(find.text('Back to puzzle'));
    await tester.pumpAndSettle();
    final beforeReference = original.encode();
    expect(find.text('View picture'), findsNothing);
    expect(find.textContaining('GLASS JAR'), findsNothing);
    await tester.tap(find.byTooltip('Picture reference'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(WoodenJar),
      ),
      findsNothing,
    );
    await tester.tap(find.byTooltip('Close picture'));
    await tester.pumpAndSettle();
    expect(original.encode(), beforeReference);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Faint picture guide'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<WoodenJar>(find.byType(WoodenJar)).showReference,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('picture jar renders partial and completed fragments', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (const bool.fromEnvironment('CAPTURE_PICTURE')) {
      await tester.runAsync(() async {
        await PictureArt.load();
        await WoodMaterial.load();
        await (FontLoader('Roboto')..addFont(
              Future.value(
                ByteData.sublistView(
                  File(
                    '/opt/homebrew/share/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
                  ).readAsBytesSync(),
                ),
              ),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
    }
    final game = pictureGame();
    game.board = solution(game.puzzle).take(3).toList();
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: GameScreen(session: game),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      if (!const bool.fromEnvironment('CAPTURE_PICTURE')) return;
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../artifacts/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('fox-picture-partial');
    game.board = List.of(game.puzzle.pieces);
    game.checkComplete();
    game.refresh();
    await tester.pumpAndSettle();
    await capture('fox-picture-complete');
    expect(find.textContaining('A perfect little fit.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
