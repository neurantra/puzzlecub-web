import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/main.dart';
import 'package:fill_the_jar/services/audience.dart';
import 'package:fill_the_jar/ui/wooden_jar.dart';
import 'widget_test.dart' show session;

void main() {
  testWidgets('landing feedback fires after the slide, once across rebuilds', (
    tester,
  ) async {
    final game = session();
    var clicks = 0;
    Widget view() => MaterialApp(
      home: SizedBox(
        width: 300,
        height: 500,
        child: WoodenJar(
          puzzle: game.puzzle,
          board: List.of(game.board),
          ghost: null,
          motion: true,
          onLanded: () => clicks++,
        ),
      ),
    );
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(clicks, 0);
    game.select(game.puzzle.pieces.first);
    game.drop();
    await tester.pumpWidget(view());
    await tester.pump(const Duration(milliseconds: 160));
    expect(clicks, 0);
    await tester.pumpWidget(view());
    await tester.pump(const Duration(milliseconds: 170));
    expect(clicks, 1);
    await tester.pumpWidget(view());
    await tester.pumpAndSettle();
    expect(clicks, 1);
  });

  test('beveled outlines stay inside every campaign block', () {
    final game = session()..motion = false;
    for (final puzzle in [...game.levels, ...game.previews]) {
      for (final piece in puzzle.pieces) {
        final original = piece.points.map((p) => p * 60).toList();
        final path = Path()..addPolygon(original, true);
        for (final points in [original, original.reversed.toList()]) {
          final inset = insetWoodPolygon(points, 2.5);
          expect(inset.length, points.length);
          for (final point in inset) {
            expect(point.dx.isFinite && point.dy.isFinite, isTrue);
            expect(
              path.contains(point),
              isTrue,
              reason: '${puzzle.key}, piece ${piece.id}: $point',
            );
          }
        }
      }
    }
  });
  testWidgets('tilted board maps taps to pieces and switches back to classic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final messenger = tester.binding.defaultBinaryMessenger;
    for (final channel in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
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
    if (const bool.fromEnvironment('CAPTURE_WOOD')) {
      await tester.runAsync(() async {
        await WoodMaterial.load();
        final font = FontLoader('Roboto')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                File(
                  '/opt/homebrew/share/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
                ).readAsBytesSync(),
              ),
            ),
          );
        await font.load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
    }
    final game = session()..motion = false;
    final piece = game.puzzle.pieces.first;
    game.select(piece);
    game.aim(piece.x);
    expect(game.drop(), isTrue);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: JarApp(audience: Audience(1990), session: game),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WoodenJar), findsOneWidget);
    expect(find.byTooltip('3D studio'), findsNothing);
    final box = tester.renderObject<RenderBox>(find.byType(WoodenJar));
    final rect = WoodenJarPainter.bounds(box.size, game.puzzle);
    final placed = game.board.single;
    final center =
        placed.points.reduce((a, b) => a + b) / placed.points.length.toDouble();
    final point =
        rect.topLeft +
        (Offset(placed.x, placed.y) + center) * (rect.width / game.puzzle.w);
    await tester.tapAt(
      tester
          .renderObject<RenderBox>(find.byType(WoodenJar))
          .localToGlobal(point),
    );
    await tester.pumpAndSettle();
    expect(game.board, isEmpty);
    game.select(piece);
    await tester.pumpAndSettle();
    expect(game.availableLandings, isNotEmpty);
    // Drop at the corresponding transformed board location.
    await tester.tapAt(
      tester
          .renderObject<RenderBox>(find.byType(WoodenJar))
          .localToGlobal(point),
    );
    await tester.pumpAndSettle();
    expect(game.board.length, 1);
    if (const bool.fromEnvironment('CAPTURE_WOOD')) {
      game.load(game.levels[7]);
      for (final p in game.puzzle.pieces.take(3)) {
        game.board.add(p);
      }
      game.select(game.puzzle.pieces[3]);
      await tester.pumpAndSettle();
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../artifacts/wooden-jar.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    if (const bool.fromEnvironment('CAPTURE_WOOD')) {
      game.board = List.of(game.puzzle.pieces);
      game.selected = null;
      game.complete = true;
      game.toggleSound(false);
      await tester.pumpAndSettle();
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../artifacts/wooden-jar-filled.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Glass jar & wooden pieces'));
    await tester.pumpAndSettle();
    expect(find.byType(WoodenJar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
