import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrange_alphabets/ui/celebration.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'hooray parade traverses once and respects reduced motion $reduced',
      (t) async {
        var taps = 0;
        await t.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Center(
                child: SizedBox(
                  width: 350,
                  height: 420,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => taps++,
                          child: const ColoredBox(color: Colors.white),
                        ),
                      ),
                      const Positioned.fill(child: CelebrationFlourish()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final parade = find.byKey(const ValueKey('hooray-parade'));
        if (reduced) {
          expect(parade, findsNothing);
        } else {
          final start = t.widget<Positioned>(parade).left!;
          await t.pump(const Duration(milliseconds: 1400));
          final middle = t.widget<Positioned>(parade).left!;
          final hop = t.widget<Positioned>(parade).top!;
          await t.pump(const Duration(milliseconds: 500));
          expect(t.widget<Positioned>(parade).left, greaterThan(middle));
          expect(middle, greaterThan(start));
          expect(t.widget<Positioned>(parade).top, isNot(hop));
          expect(find.text('HOORAY!'), findsOneWidget);
        }
        await t.tapAt(t.getCenter(find.byType(CelebrationFlourish)));
        expect(taps, 1);
        await t.pump(const Duration(seconds: 6));
        expect(parade, findsNothing);
        expect(find.byType(CelebrationFlourish), findsOneWidget);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}
