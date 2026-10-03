import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fill_the_jar/main.dart';
import 'package:fill_the_jar/services/audience.dart';
import 'package:fill_the_jar/services/services.dart';
import 'package:fill_the_jar/ui/game_screen.dart';
import 'widget_test.dart' show session;

void main() {
  test('unknown, invalid and boundary years remain protected', () {
    for (final year in [null, 1899, 2027, 2020, 2010]) {
      expect(
        Audience(
          year,
          currentYear: 2026,
          countryCode: 'DE',
        ).externalServicesAllowed,
        false,
      );
    }
    expect(
      Audience(
        2009,
        currentYear: 2026,
        countryCode: 'DE',
      ).externalServicesAllowed,
      true,
    );
    expect(
      Audience(
        2010,
        currentYear: 2027,
        countryCode: 'DE',
      ).externalServicesAllowed,
      true,
    );
  });
  test('protected ad service never calls a platform SDK', () async {
    final ads = RewardAds();
    expect(await ads.prepare(), false);
    expect(await ads.show(), RewardOutcome.unavailable);
    expect(await ads.privacyOptions(), false);
    expect(ads.simulatedPreview, false);
  });
  testWidgets(
    'first launch saves neutral declaration before showing game; restart retains it',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = SaveStore(prefs);
      final game = session();
      await tester.pumpWidget(JarApp(session: game, store: store));
      expect(find.byType(GameScreen), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
            .onPressed,
        isNull,
      );
      final selector = tester.widget<DropdownButtonFormField<int>>(
        find.byKey(const ValueKey('birth-year')),
      );
      expect(selector.initialValue, isNull);
      selector.onChanged!(DateTime.now().year - 8);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(prefs.getInt(Audience.key), DateTime.now().year - 8);
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Play PuzzleCub'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(JarApp(session: game, store: store));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to Fill the Jar'), findsNothing);
      expect(find.byType(GameScreen), findsOneWidget);
    },
  );
  testWidgets('protected drawer, wallet and studio offer no online actions', (
    tester,
  ) async {
    final game = session();
    await tester.pumpWidget(
      JarApp(session: game, audience: Audience(DateTime.now().year - 8)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Play PuzzleCub'), findsNothing);
    expect(find.text('Play Chaturang'), findsNothing);
    expect(find.text('Ad privacy choices'), findsNothing);
    expect(find.text('Rate the game'), findsNothing);
    await tester.tap(find.text('Coin vault'));
    await tester.pumpAndSettle();
    expect(find.text('Your coins'), findsOneWidget);
    expect(find.textContaining('View ad'), findsNothing);
    expect(find.textContaining('saved on this device'), findsOneWidget);
    Navigator.of(tester.element(find.text('Your coins'))).pop();
    await tester.pumpAndSettle();
    expect(find.byTooltip('3D studio'), findsNothing);
  });

  testWidgets(
    'settings correction updates eligibility without resetting progress',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        Audience.key: 1990,
        'jar.tutorial.seen.v1': true,
      });
      final store = SaveStore(await SharedPreferences.getInstance());
      final game = session();
      final coins = game.coins;
      await tester.pumpWidget(JarApp(session: game, store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Age information'));
      await tester.tap(find.text('Age information'));
      await tester.pumpAndSettle();
      final question = tester
          .widget<Text>(find.textContaining(RegExp(r'^\d+ × \d+ = \?$')))
          .data!;
      final parts = RegExp(
        r'\d+',
      ).allMatches(question).map((m) => int.parse(m.group(0)!)).toList();
      await tester.enterText(
        find.byKey(const ValueKey('parent-answer')),
        '${parts[0] * parts[1]}',
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const ValueKey('birth-year')),
          )
          .onChanged!(DateTime.now().year - 8);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(game.coins, coins);
      final screen = tester.widget<GameScreen>(find.byType(GameScreen));
      expect(identical(screen.session, game), true);
      expect(screen.audience!.externalServicesAllowed, false);
      expect(store.prefs.getInt(Audience.key), DateTime.now().year - 8);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
