import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:arrange_alphabets/main.dart';
import 'package:arrange_alphabets/services/preferences.dart';
import 'package:arrange_alphabets/services/family_games.dart';

class FakeLauncher extends UrlLauncherPlatform {
  final List<String> opened = [];
  @override
  LinkDelegate? get linkDelegate => null;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return true;
  }
}

void main() {
  test('family store links use correct platform IDs', () {
    expect(
      FamilyGame.mapopia.link(TargetPlatform.iOS).toString(),
      'https://apps.apple.com/app/id6816405706',
    );
    for (final game in FamilyGame.values) {
      expect(
        game.link(TargetPlatform.android).queryParameters['id'],
        game.package,
      );
      expect(game.link(TargetPlatform.iOS).path, '/app/id${game.appleId}');
    }
  });
  testWidgets(
    'menu information and footer promotions require gate before external launch',
    (t) async {
      SharedPreferences.setMockInitialValues({
        'ageDeclared': true,
        'sound': false,
        'reducedMotion': true,
      });
      final original = UrlLauncherPlatform.instance;
      final launcher = FakeLauncher();
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = original);
      await t.pumpWidget(
        ArrangeAlphabetsApp(
          preferences: Preferences(await SharedPreferences.getInstance()),
        ),
      );
      await t.pumpAndSettle();
      for (final section in ['About', 'Privacy', 'Terms']) {
        await t.tap(find.byTooltip('Menu'));
        await t.pumpAndSettle();
        await t.tap(find.text(section));
        await t.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(launcher.opened, isEmpty);
        await t.tap(find.text('Done'));
        await t.pumpAndSettle();
      }
      await t.tap(find.byTooltip('Menu'));
      await t.pumpAndSettle();
      await t.tap(find.text('Maze Words').last);
      await t.pumpAndSettle();
      expect(find.text('A little grown-up check'), findsOneWidget);
      await t.enterText(find.byType(TextField), '0');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(launcher.opened, isEmpty);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Fill the Jar'));
      await t.tap(find.text('Fill the Jar'));
      await t.pumpAndSettle();
      final question = t.widget<Text>(find.textContaining('what is')).data!;
      final values = RegExp(
        r'\d+',
      ).allMatches(question).map((m) => int.parse(m.group(0)!)).toList();
      await t.enterText(find.byType(TextField), '${values[0] * values[1]}');
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(launcher.opened.single, contains('com.fillthejar.app'));
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
}
