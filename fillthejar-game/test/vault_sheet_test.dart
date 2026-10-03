import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/services/vault/vault_service.dart';
import 'package:fill_the_jar/ui/vault_sheet.dart';
import 'vault_test.dart' show fresh, FakeVault;

void main() {
  testWidgets(
    'linked wallet collects coins, shows code and fits a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final game = fresh();
      final remote = FakeVault();
      final vault = VaultService(game, remote, (_) async {});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VaultSheet(game: game, vault: vault, adLabel: 'Watch ad'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('100 coins ready to collect'), findsOneWidget);
      await tester.ensureVisible(find.text('Transfer in · collect all'));
      await tester.tap(find.text('Transfer in · collect all'));
      await tester.pumpAndSettle();
      expect(game.coins, 160);
      expect(remote.coins, 0);
      await tester.ensureVisible(find.text('Show a link code'));
      await tester.tap(find.text('Show a link code'));
      await tester.pumpAndSettle();
      expect(find.text('ABC234'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('disabled shared wallet still offers ordinary local rewards', (
    tester,
  ) async {
    final game = fresh();
    final remote = FakeVault()..live = false;
    final vault = VaultService(game, remote, (_) async {});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VaultSheet(
            game: game,
            vault: vault,
            adLabel: 'Watch ad',
            reward: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Transfer in · collect all'), findsNothing);
    expect(find.text('Watch ad · +30 coins'), findsOneWidget);
  });
}
