import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/ui/jar_presentation.dart';

void main() {
  testWidgets(
    'finish waits for landing, survives rebuilds and resets on next level',
    (tester) async {
      var complete = false;
      var puzzle = 'one';
      var reveal = -1.0;
      Widget view({bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: JarPresentation(
            puzzleKey: puzzle,
            complete: complete,
            motion: true,
            builder: (_, value) {
              reveal = value;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      await tester.pumpWidget(view());
      await tester.pumpAndSettle();
      complete = true;
      await tester.pumpWidget(view());
      await tester.pump(const Duration(milliseconds: 320));
      expect(reveal, 0);
      await tester.pump(const Duration(milliseconds: 650));
      expect(reveal, inExclusiveRange(0, 1));
      final beforeRebuild = reveal;
      await tester.pumpWidget(view());
      expect(reveal, beforeRebuild);
      await tester.pumpAndSettle();
      expect(reveal, 1);
      await tester.pumpWidget(view());
      expect(reveal, 1);
      puzzle = 'two';
      complete = false;
      await tester.pumpWidget(view());
      expect(reveal, 0);
      complete = true;
      await tester.pumpWidget(view(reduced: true));
      expect(reveal, 1);
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('leaving mid-celebration disposes tickers safely', (
    tester,
  ) async {
    Widget view(bool complete) => MaterialApp(
      home: JarPresentation(
        puzzleKey: 'one',
        complete: complete,
        motion: true,
        builder: (_, _) => const SizedBox.expand(),
      ),
    );
    await tester.pumpWidget(view(false));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(view(true));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
