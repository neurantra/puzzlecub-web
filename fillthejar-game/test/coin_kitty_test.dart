import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/ui/coin_kitty.dart';

void main() {
  testWidgets(
    'earned coins count up once; spends and reduced motion settle immediately',
    (tester) async {
      var balance = 60, chimes = 0, taps = 0;
      var reduced = false;
      Widget view() => MaterialApp(
        builder: (_, child) => Material(child: child),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Center(
            child: CoinKitty(
              coins: balance,
              motion: true,
              onTap: () => taps++,
              onDeposit: () => chimes++,
            ),
          ),
        ),
      );
      String value() =>
          tester.widget<Text>(find.byKey(const Key('coin-balance'))).data!;
      await tester.pumpWidget(view());
      expect(value(), '60');
      expect(chimes, 0);
      balance = 85;
      await tester.pumpWidget(view());
      expect(value(), '60');
      expect(find.text('+25'), findsOneWidget);
      for (var i = 0; i < 11; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(int.parse(value()), inExclusiveRange(60, 85));
      final mid = value();
      await tester.pumpWidget(view());
      expect(value(), mid);
      await tester.pumpAndSettle();
      expect(value(), '85');
      expect(chimes, 3);
      await tester.pumpWidget(view());
      await tester.pumpAndSettle();
      expect(chimes, 3);
      await tester.tap(find.byType(CoinKitty));
      expect(taps, 1);
      balance = 75;
      await tester.pumpWidget(view());
      expect(value(), '75');
      expect(find.text('+25'), findsNothing);
      reduced = true;
      balance = 100;
      await tester.pumpWidget(view());
      await tester.pumpAndSettle();
      expect(value(), '100');
      expect(chimes, 3);
    },
  );

  testWidgets(
    'a second award and interrupted deposit converge to authoritative balance',
    (tester) async {
      var balance = 100;
      Widget view() => MaterialApp(
        builder: (_, child) => Material(child: child),
        home: Center(
          child: CoinKitty(coins: balance, motion: true, onTap: () {}),
        ),
      );
      String value() =>
          tester.widget<Text>(find.byKey(const Key('coin-balance'))).data!;
      await tester.pumpWidget(view());
      balance = 125;
      await tester.pumpWidget(view());
      await tester.pump(const Duration(milliseconds: 1000));
      final mid = value();
      balance = 150;
      await tester.pumpWidget(view());
      expect(value(), mid);
      await tester.pumpAndSettle();
      expect(value(), '150');
      balance = 175;
      await tester.pumpWidget(view());
      await tester.pump(const Duration(milliseconds: 800));
      balance = 165;
      await tester.pumpWidget(view());
      await tester.pumpAndSettle();
      expect(value(), '165');
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
