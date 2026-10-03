import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maze_words/ui/success_celebration.dart';

void main() {
  testWidgets('celebration settles and leaves review controls usable', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SuccessCelebration(),
              TextButton(
                onPressed: () => tapped = true,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Continue'));
    expect(tapped, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('!'), findsOneWidget);
  });

  testWidgets('reduced motion renders a still celebration', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: SuccessCelebration()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
