import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/main.dart';
import 'app_test.dart' show preload;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maze_words/services/audience.dart';
import 'package:maze_words/ui/age_information.dart';

void main() {
  test('locale policy, unknown and birthday boundaries', () {
    for (final country in ['US', 'DE']) {
      for (final year in [null, 1899, 2027, 2020]) {
        expect(
          Audience(
            year,
            currentYear: 2026,
            countryCode: country,
          ).externalServicesAllowed,
          false,
        );
      }
    }
    expect(
      Audience(
        2013,
        currentYear: 2026,
        countryCode: 'US',
      ).externalServicesAllowed,
      false,
    );
    expect(
      Audience(
        2012,
        currentYear: 2026,
        countryCode: 'US',
      ).externalServicesAllowed,
      true,
    );
    expect(
      Audience(
        2010,
        currentYear: 2026,
        countryCode: 'DE',
      ).externalServicesAllowed,
      false,
    );
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
  testWidgets(
    'parent gate rejects wrong answer and cancel; correct answer opens editor',
    (tester) async {
      int? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  if (!await ageParentGate(context) || !context.mounted) return;
                  await showAgeInformation(
                    context,
                    birthYear: 1990,
                    save: (year) async {
                      saved = year;
                    },
                  );
                },
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('parent-answer')), '0');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Please try again.'), findsOneWidget);
      expect(find.byKey(const ValueKey('birth-year')), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(saved, isNull);
      await tester.tap(find.text('Edit'));
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
          .onChanged!(2000);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved, 2000);
    },
  );
  testWidgets('failed save stays open and can be retried', (tester) async {
    var fail = true;
    int? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAgeInformation(
                context,
                save: (year) async {
                  if (fail) throw StateError('disk');
                  saved = year;
                },
              ),
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    tester
        .widget<DropdownButtonFormField<int>>(
          find.byKey(const ValueKey('birth-year')),
        )
        .onChanged!(2000);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
    expect(saved, isNull);
    fail = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, 2000);
  });

  testWidgets(
    'settings correction updates eligibility without resetting progress',
    (tester) async {
      await preload(tester);
      SharedPreferences.setMockInitialValues({});
      final store = PlayerStore(await SharedPreferences.getInstance());
      await store.setBirthYear(1990);
      await store.reward(64);
      await tester.pumpWidget(MazeWordsApp(store: store));
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
      expect(store.adult, false);
      expect(store.coins, 94);
      expect(PlayerStore(store.prefs).birthYear, DateTime.now().year - 8);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
