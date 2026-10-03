import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maze_words/data/player_store.dart';
import 'package:maze_words/services/vault/vault_service.dart';
import 'package:maze_words/ui/vault_sheet.dart';
import 'package:maze_words/ui/style.dart';
import 'vault_test.dart' show FakeVault;

void main() {
  Future<PlayerStore> player({bool adult = true}) async {
    SharedPreferences.setMockInitialValues({});
    final s = PlayerStore(await SharedPreferences.getInstance());
    await s.set('onboarded', true);
    await s.set('adult', adult);
    return s;
  }

  testWidgets('small-screen coin sheet links, collects, and confirms banking', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = await player();
    final remote = FakeVault();
    final vault = VaultService(s, remote);
    await tester.pumpWidget(
      MaterialApp(
        theme: mazeTheme(),
        home: Scaffold(
          body: VaultSheet(game: s, vault: vault),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('100 coins ready to collect'), findsOneWidget);
    await tester.ensureVisible(find.text('Transfer in · collect all'));
    await tester.tap(find.text('Transfer in · collect all'));
    await tester.pumpAndSettle();
    expect(s.coins, 130);
    expect(remote.coins, 0);
    await tester.ensureVisible(find.text('All · 130'));
    await tester.tap(find.text('All · 130'));
    await tester.pumpAndSettle();
    expect(find.text('Transfer 130 coins out?'), findsOneWidget);
    await tester.tap(find.text('Keep here'));
    await tester.pumpAndSettle();
    expect(s.coins, 130);
    await tester.tap(find.text('All · 130'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer out'));
    await tester.pumpAndSettle();
    expect(s.coins, 0);
    expect(remote.coins, 130);
    await tester.ensureVisible(find.text('Show a link code'));
    await tester.tap(find.text('Show a link code'));
    await tester.pumpAndSettle();
    expect(find.text('ABC234'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vault.dispose();
  });
  testWidgets('protected profile shows local coins without online controls', (
    tester,
  ) async {
    final s = await player(adult: false);
    await tester.pumpWidget(
      MaterialApp(
        theme: mazeTheme(),
        home: Scaffold(body: VaultSheet(game: s)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('30 coins in Maze Words'), findsOneWidget);
    expect(
      find.textContaining(
        'Shared coin transfers and link codes are unavailable for this age profile.',
      ),
      findsOneWidget,
    );
    expect(find.text('Neurantra shared vault'), findsNothing);
    expect(find.text('Show a link code'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('remote switch off leaves a clear local-wallet fallback', (
    tester,
  ) async {
    final s = await player();
    final remote = FakeVault()..live = false;
    final vault = VaultService(s, remote);
    await tester.pumpWidget(
      MaterialApp(
        theme: mazeTheme(),
        home: Scaffold(
          body: VaultSheet(game: s, vault: vault),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Shared transfers are currently unavailable'),
      findsOneWidget,
    );
    expect(find.text('Transfer in · collect all'), findsNothing);
    expect(find.text('Check shared vault again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    vault.dispose();
  });
}
