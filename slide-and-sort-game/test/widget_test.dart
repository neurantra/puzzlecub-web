import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrange_alphabets/main.dart';
import 'package:arrange_alphabets/services/preferences.dart';
import 'package:arrange_alphabets/ui/toy_box.dart';
import 'package:arrange_alphabets/ui/age.dart';
import 'package:arrange_alphabets/ui/celebration.dart';
import 'package:arrange_alphabets/game/solver.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<Preferences> prefs() async {
    SharedPreferences.setMockInitialValues({
      'ageDeclared': true,
      'sound': false,
      'reducedMotion': true,
    });
    return Preferences(await SharedPreferences.getInstance());
  }

  Future<void> capture(WidgetTester t, String name) async {
    await t.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/app-icon.png'),
        t.element(find.byType(MaterialApp).first),
      ),
    );
    await t.pump();
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory('docs/previews');
      await dir.create(recursive: true);
      await File(
        '${dir.path}/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans');
    loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'));
    loader.addFont(
      rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'),
    );
    loader.addFont(
      rootBundle.load('assets/fonts/PlusJakartaSans-ExtraBold.ttf'),
    );
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final (width, height, scale, numbers, sequential) in [
    (390.0, 844.0, 1.0, false, false),
    (390.0, 844.0, 1.0, true, false),
    (390.0, 844.0, 1.0, true, true),
    (320.0, 720.0, 1.4, false, false),
    (320.0, 720.0, 1.4, true, false),
    (320.0, 720.0, 1.4, true, true),
    (768.0, 1024.0, 1.0, false, false),
    (768.0, 1024.0, 1.0, true, false),
    (768.0, 1024.0, 1.0, true, true),
  ]) {
    testWidgets(
      'home and play fit $width at scale $scale numbers $numbers sequential $sequential',
      (t) async {
        t.view.physicalSize = Size(width, height);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: ArrangeAlphabetsApp(preferences: await prefs()),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        if (width == 390) {
          for (final label in [
            'Solo',
            'Pip the AI',
            'No timer',
            '5 minutes',
            'No limit',
            '150 moves',
          ]) {
            expect(find.text(label).hitTestable(), findsOneWidget);
          }
          final scroll = t
              .widget<SingleChildScrollView>(
                find.byType(SingleChildScrollView).first,
              )
              .controller!;
          await t.tap(find.text('More below'));
          await t.pumpAndSettle();
          expect(scroll.offset, greaterThan(0));
          scroll.jumpTo(0);
          await t.pumpAndSettle();
        }
        if (numbers) {
          await t.ensureVisible(find.text(sequential ? '1–29' : '1–9'));
          await t.tap(
            find.ancestor(
              of: find.text(sequential ? '1–29' : '1–9'),
              matching: find.byType(OutlinedButton),
            ),
          );
          await t.pumpAndSettle();
        }
        final choices = find.descendant(
          of: find.byKey(const ValueKey('puzzle-choice-row')),
          matching: find.byType(OutlinedButton),
        );
        expect(choices, findsNWidgets(3));
        final choiceTop = t.getTopLeft(choices.first).dy;
        for (var i = 0; i < 3; i++) {
          expect(t.getTopLeft(choices.at(i)).dy, choiceTop);
          expect(t.getSize(choices.at(i)).height, greaterThanOrEqualTo(48));
        }
        await capture(
          t,
          'home-${sequential
              ? 'sequential-'
              : numbers
              ? 'numbers-'
              : ''}${width.toInt()}',
        );
        await t.ensureVisible(find.text('Pip the AI'));
        await t.tap(find.text('Pip the AI'));
        await t.pump();
        await t.ensureVisible(find.text("Let's play"));
        await t.tap(find.text("Let's play"));
        await t.pumpAndSettle();
        expect(
          find.text(numbers ? 'Ready, set… 1, 2, 3!' : 'Ready, set… ABC!'),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
        expect(find.byType(LiveAiBoard), findsOneWidget);
        final before = t
            .widget<LiveAiBoard>(find.byType(LiveAiBoard))
            .board
            .tiles;
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(milliseconds: 300));
        final after = t
            .widget<LiveAiBoard>(find.byType(LiveAiBoard))
            .board
            .tiles;
        expect(after, isNot(equals(before)));
        expect(t.getSize(find.byType(LiveAiBoard)).width, 96);
        if (width == 390) {
          expect(t.getSize(find.byType(AlphabetBoard)).width, 350);
          expect(
            t.getBottomLeft(find.byType(AlphabetBoard)).dy,
            lessThan(height),
          );
        }
        await capture(
          t,
          'play-${sequential
              ? 'sequential-'
              : numbers
              ? 'numbers-'
              : ''}${width.toInt()}',
        );
        await t.tap(find.byTooltip('Pause'));
        await t.pump();
        expect(find.text('Your puzzle can wait.'), findsOneWidget);
        final pausedBoard = t
            .widget<LiveAiBoard>(find.byType(LiveAiBoard))
            .board
            .tiles;
        await t.pump(const Duration(seconds: 10));
        expect(
          t.widget<LiveAiBoard>(find.byType(LiveAiBoard)).board.tiles,
          pausedBoard,
        );
        await t.tap(find.text('Keep playing'));
        await t.pump();
        await t.ensureVisible(
          find.text(
            numbers ? 'Peek at the number guide' : 'Peek at the ABC guide',
          ),
        );
        await t.tap(
          find.text(
            numbers ? 'Peek at the number guide' : 'Peek at the ABC guide',
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.text(
            sequential
                ? 'Count your way from 1 to 29.'
                : numbers
                ? 'One more across. One more down.'
                : 'Every letter has a home',
          ),
          findsOneWidget,
        );
        await capture(
          t,
          'guide-${sequential
              ? 'sequential-'
              : numbers
              ? 'numbers-'
              : ''}${width.toInt()}',
        );
        await t.tap(find.text('Back to my puzzle'));
        await t.pumpAndSettle();
        await t.ensureVisible(find.byTooltip('Back to home'));
        await t.tap(find.byTooltip('Back to home'));
        await t.pumpAndSettle();
        await t.tap(find.text('Go home'));
        await t.pumpAndSettle();
        expect(find.text('Slide & Sort:'), findsOneWidget);
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      },
    );
  }
  testWidgets(
    'unknown player can choose protected play without an invented year',
    (t) async {
      SharedPreferences.setMockInitialValues({
        'sound': false,
        'reducedMotion': true,
      });
      final p = Preferences(await SharedPreferences.getInstance());
      await t.pumpWidget(ArrangeAlphabetsApp(preferences: p));
      await t.pumpAndSettle();
      expect(find.text('A little about you'), findsOneWidget);
      await t.tap(find.text('Play without sharing'));
      await t.pumpAndSettle();
      expect(p.year, isNull);
      expect(p.declared, isTrue);
      expect(p.protected, isTrue);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'age gate wrong, cancel, correct and save retry preserve progress',
    (t) async {
      SharedPreferences.setMockInitialValues({
        'birthYear': 2020,
        'ageDeclared': true,
        'wins': 6,
      });
      final storage = await SharedPreferences.getInstance();
      final p = Preferences(storage);
      final failing = _FailingStore({
        'flutter.birthYear': 2020,
        'flutter.ageDeclared': true,
        'flutter.wins': 6,
      });
      SharedPreferencesStorePlatform.instance = failing;
      await t.pumpWidget(
        MaterialApp(
          theme: toyTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => editAge(context, p),
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '0');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(find.text('Try that one again.'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(p.year, 2020);
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
      final prompt = t.widget<Text>(find.textContaining('what is')).data!;
      final numbers = RegExp(
        r'\d+',
      ).allMatches(prompt).map((m) => int.parse(m.group(0)!)).toList();
      await t.enterText(find.byType(TextField), '${numbers[0] * numbers[1]}');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '1980');
      failing.fail = true;
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(find.text('Could not save. Please try again.'), findsOneWidget);
      expect(p.year, 2020);
      expect(p.protected, isTrue);
      expect(p.wins, 6);
      failing.fail = false;
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect(p.year, 1980);
      expect(p.protected, isFalse);
      expect(p.wins, 6);
      expect(Preferences(storage).year, 1980);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
  for (final (reduced, numbers, sequential) in [
    (false, false, false),
    (true, false, false),
    (false, true, false),
    (true, true, false),
    (false, true, true),
    (true, true, true),
  ]) {
    testWidgets(
      'solved board stays full-size with frozen stats, reduced motion $reduced numbers $numbers sequential $sequential',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final preferences = await prefs();
        await t.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: ArrangeAlphabetsApp(preferences: preferences),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('PLAY MODE'), findsOneWidget);
        expect(find.text('PLAY WITH'), findsNothing);
        if (numbers) {
          await t.ensureVisible(find.text(sequential ? '1–29' : '1–9'));
          await t.tap(
            find.ancestor(
              of: find.text(sequential ? '1–29' : '1–9'),
              matching: find.byType(OutlinedButton),
            ),
          );
          await t.pump();
        }
        await t.ensureVisible(find.text('5 minutes'));
        await t.tap(find.text('5 minutes'));
        await t.pump();
        await t.tap(find.text("Let's play"));
        await t.pumpAndSettle();
        await preferences.setFlag('reducedMotion', reduced);
        await t.pump();
        expect(
          preferences.storage.getString('puzzleKind'),
          sequential
              ? 'sequential'
              : numbers
              ? 'numbers'
              : 'alphabets',
        );
        final boardFinder = find.byType(AlphabetBoard);
        final boardState = t.state(boardFinder);
        final boardSize = t.getSize(boardFinder);
        final initial = t.widget<AlphabetBoard>(boardFinder).board;
        for (final index in AlphaSolver(initial).solve()) {
          final current = t.widget<AlphabetBoard>(boardFinder).board;
          if (current.isSolved) break;
          final letter = current.tiles[index];
          final tile = find.descendant(
            of: find.byKey(ValueKey<String>(letter!)),
            matching: find.byType(ToyTile),
          );
          await t.ensureVisible(tile);
          await t.tap(tile);
          await t.pump(const Duration(milliseconds: 180));
        }
        expect(t.widget<AlphabetBoard>(boardFinder).board.isSolved, isTrue);
        expect(t.widget<AlphabetBoard>(boardFinder).onMove, isNull);
        expect(identical(t.state(boardFinder), boardState), isTrue);
        expect(t.getSize(boardFinder), boardSize);
        expect(boardSize.width, 350);
        expect(find.byType(CelebrationFlourish), findsOneWidget);
        expect(find.text('HOORAY! You did it!'), findsOneWidget);
        expect(find.text(numbers ? '29/29' : '24/24'), findsOneWidget);
        expect(find.text('Time left'), findsNothing);
        expect(find.text('Time'), findsOneWidget);
        expect(
          t.getTopLeft(find.text('Time')).dy,
          lessThan(t.getTopLeft(boardFinder).dy),
        );
        await t.pump(const Duration(milliseconds: 1800));
        expect(
          find.byKey(const ValueKey('hooray-parade')),
          reduced ? findsNothing : findsOneWidget,
        );
        await capture(
          t,
          '${sequential
              ? 'sequential-'
              : numbers
              ? 'numbers-'
              : ''}${reduced ? 'solved-still-390' : 'solved-390'}',
        );
        final clock = find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'^\d+:\d{2}$').hasMatch(w.data ?? ''),
        );
        final time = t.widget<Text>(clock).data;
        await t.pump(const Duration(seconds: 20));
        expect(t.widget<Text>(clock).data, time);
        expect(t.widget<AlphabetBoard>(boardFinder).board.isSolved, isTrue);
        expect(preferences.wins, 1);
        await t.tap(
          find.descendant(
            of: find.byKey(const ValueKey('X')),
            matching: find.byType(ToyTile),
          ),
        );
        await t.pump();
        expect(t.widget<AlphabetBoard>(boardFinder).board.isSolved, isTrue);
        await t.ensureVisible(find.text('Another happy shuffle'));
        await t.tap(find.text('Another happy shuffle'));
        await t.pump();
        expect(t.widget<AlphabetBoard>(boardFinder).board.isSolved, isFalse);
        expect(find.byType(CelebrationFlourish), findsNothing);
        expect(preferences.wins, 1);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pump();
      },
    );
  }
  testWidgets('render original app icon', (t) async {
    t.view.physicalSize = const Size(512, 512);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: toyTheme(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Material(
              color: cream,
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    Pip(size: 260),
                    SizedBox(height: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: ToyTile(letter: 'A')),
                          SizedBox(width: 12),
                          Expanded(child: ToyTile(letter: 'B')),
                          SizedBox(width: 12),
                          Expanded(child: ToyTile(letter: 'C')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await capture(t, 'icon');
  });
}

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore(super.data) : super.withData();
  bool fail = false;
  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      fail ? Future.value(false) : super.setValue(valueType, key, value);
}
