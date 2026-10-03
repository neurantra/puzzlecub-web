import '../data/game_access.dart';
import 'package:flutter/material.dart';

import '../data/ads_service.dart';
import '../data/appearance_service.dart';
import '../data/cross_promo.dart';
import '../data/stats_service.dart';
import '../data/vault_availability.dart';
import '../engine/pieces.dart';
import '../engine/board.dart';
import 'ornamented_board.dart';
import 'appearance.dart';
import 'board_tile.dart';
import 'puzzlecub_modal.dart';
import 'theme.dart';
import 'vault_modal.dart';

/// The Store: spend coins on appearance items.
///
/// Two independent axes — piece sets and board surfaces — so an equipped
/// combination is the player's own. Rendering is driven off the catalogs in
/// `appearance.dart`; adding a SKU there adds a row here with no UI work.
Future<void> showStoreSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ChaturangTheme.deepMaroon,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => const _StoreSheet(),
  );
}

class _StoreSheet extends StatelessWidget {
  const _StoreSheet();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: ListenableBuilder(
          // Rows depend on both ownership (AppearanceService) and the coin
          // balance (StatsService), so watch the pair.
          listenable: Listenable.merge([
            AppearanceService.instance,
            StatsService.instance,
            VaultAvailability.instance,
          ]),
          builder: (context, _) {
            final coins = StatsService.instance.coins;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const _DragHandle(),
                const SizedBox(height: 12),
                _Header(coins: coins),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // Above the catalog on purpose. Buried under two
                      // scrolling sections, the cross-game coin transfer —
                      // the whole point of the PuzzleCub tie-in — was
                      // something a player had to go looking for.
                      // Absent, not disabled, when the feature is off. A
                      // visible-but-dead vault lets a player bank coins
                      // into somewhere the other game cannot reach.
                      if (VaultAvailability.instance.isLive) ...[
                        const _SectionLabel('Shared coins'),
                        const _VaultRow(),
                        const SizedBox(height: 18),
                      ],
                      const Text(
                        'Try each finish with your current board and both armies. Board tones automatically balance for clear pieces.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Piece finishes'),
                      for (final set in kPieceSets)
                        _ItemRow(
                          item: set,
                          preview: _PairingPreview(
                            set: set,
                            surface: AppearanceService.instance.surface,
                          ),
                          coins: coins,
                        ),
                      const SizedBox(height: 18),
                      const _SectionLabel('Board finishes & patterns'),
                      for (final surface in kBoardSurfaces)
                        _ItemRow(
                          item: surface,
                          preview: _PairingPreview(
                            set: AppearanceService.instance.pieceSet,
                            surface: surface,
                          ),
                          coins: coins,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Entry point to the shared vault.
///
/// Lives in the Store because that is where coins already mean something to
/// the player. Phrased as moving coins between the two games rather than as
/// storing them anywhere — the vault is transit, and the copy has to keep
/// saying so.
class _VaultRow extends StatelessWidget {
  const _VaultRow();

  @override
  Widget build(BuildContext context) => Material(
    color: ChaturangTheme.charcoal.withValues(alpha: 0.35),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showVaultSheet(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.swap_horiz, color: ChaturangTheme.saffron),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transfer coins to/from vault',
                    style: const TextStyle(
                      color: ChaturangTheme.parchment,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Coins in vault work in ${CrossPromo.appName} too',
                    style: TextStyle(
                      color: ChaturangTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ChaturangTheme.parchment.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    final balance = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.monetization_on_outlined,
          size: 18,
          color: ChaturangTheme.saffronLight,
        ),
        const SizedBox(width: 6),
        Text(
          '$coins',
          style: TextStyle(
            fontFamily: 'RoyalSans',
            color: ChaturangTheme.parchment,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Store',
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: ChaturangTheme.saffronLight,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Tapping the balance opens the vault, as it does in PuzzleCub,
          // where the coin pill is the vault's front door. Only while the
          // feature is live: a tap target that does nothing is worse than
          // a plain number.
          if (VaultAvailability.instance.isLive)
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => showVaultSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: balance,
              ),
            )
          else
            balance,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: ChaturangTheme.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          fontFamily: 'RoyalSans',
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.preview,
    required this.coins,
  });

  final StoreItem item;
  final Widget preview;
  final int coins;

  Future<void> _buy(BuildContext context) async {
    final outcome = await AppearanceService.instance.purchase(item);
    if (!context.mounted) return;
    switch (outcome) {
      case PurchaseOutcome.purchased:
      case PurchaseOutcome.alreadyOwned:
        // Equip straight away — buying something and then having to tap
        // again to see it is a pointless extra step.
        await AppearanceService.instance.equip(item);
      case PurchaseOutcome.notEnoughCoins:
        // Two routes out rather than one: the rewarded ad, and PuzzleCub.
        // A message that merely names a way to get coins, with no way to act
        // on it from the sheet the player is already in, is a dead end.
        final route = await showPuzzleCubSheet(
          context,
          itemName: item.name,
          price: item.price,
          balance: coins,
          adReward: coinsForRewardedAd,
          allowAds: GameAccess.instance.coinAdsAllowed,
        );
        if (!context.mounted) return;
        switch (route) {
          case CoinRoute.watchAd:
            // AdsService credits on completion; the sheet listens to
            // StatsService, so the balance and the Buy buttons update on
            // their own. The player re-taps Buy when ready to spend — the
            // same deliberate second step the Hint flow uses.
            await AdsService.instance.requestRewarded();
          case CoinRoute.visitedPuzzleCub:
          case CoinRoute.dismissed:
            break;
        }
    }
  }

  void _previewPairing(BuildContext context) {
    final appearance = AppearanceService.instance;
    final pieces = item is PieceSet ? item as PieceSet : appearance.pieceSet;
    final surface = item is BoardSurface
        ? item as BoardSurface
        : appearance.surface;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ChaturangTheme.deepMaroon,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${pieces.name} · ${surface.name}',
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: MediaQuery.sizeOf(context).width * 1.04,
                  child: IgnorePointer(
                    child: OrnamentedBoard(
                      board: Board(),
                      previewPieces: pieces,
                      previewSurface: surface,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Board tones balanced for both armies.',
                    textAlign: TextAlign.center,
                  ),
                ),
                ListenableBuilder(
                  listenable: Listenable.merge([
                    appearance,
                    StatsService.instance,
                  ]),
                  builder: (context, _) => _Action(
                    equipped: appearance.isEquipped(item),
                    owned: appearance.owns(item),
                    affordable: StatsService.instance.coins >= item.price,
                    price: item.price,
                    onEquip: () => appearance.equip(item),
                    onBuy: () => _buy(context),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceService.instance;
    final owned = appearance.owns(item);
    final equipped = appearance.isEquipped(item);
    final affordable = coins >= item.price;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: equipped ? 0.28 : 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: equipped
                ? ChaturangTheme.saffron.withValues(alpha: 0.75)
                : ChaturangTheme.parchment.withValues(alpha: 0.12),
            width: equipped ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _previewPairing(context),
                  child: SizedBox(width: 64, height: 64, child: preview),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'RoyalSans',
                        color: ChaturangTheme.parchment,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _previewPairing(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 36),
                        alignment: Alignment.centerLeft,
                      ),
                      child: const Text('Preview together'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.blurb,
                      style: TextStyle(
                        color: ChaturangTheme.secondaryText,
                        fontSize: 12,
                        height: 1.3,
                        fontFamily: 'RoyalSans',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Action(
                equipped: equipped,
                owned: owned,
                affordable: affordable,
                price: item.price,
                onEquip: () => AppearanceService.instance.equip(item),
                onBuy: () => _buy(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.equipped,
    required this.owned,
    required this.affordable,
    required this.price,
    required this.onEquip,
    required this.onBuy,
  });

  final bool equipped;
  final bool owned;
  final bool affordable;
  final int price;
  final VoidCallback onEquip;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    if (equipped) {
      return Text(
        'Equipped',
        style: TextStyle(
          color: ChaturangTheme.saffronLight,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'RoyalSans',
        ),
      );
    }
    if (owned) {
      return TextButton(
        onPressed: onEquip,
        style: TextButton.styleFrom(
          foregroundColor: ChaturangTheme.saffronLight,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        child: const Text('Equip'),
      );
    }
    return FilledButton(
      onPressed: onBuy,
      style: FilledButton.styleFrom(
        backgroundColor: affordable
            ? ChaturangTheme.saffron
            : ChaturangTheme.saffron.withValues(alpha: 0.30),
        foregroundColor: affordable
            ? ChaturangTheme.deepMaroon
            : ChaturangTheme.primaryText,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_outlined, size: 14),
          const SizedBox(width: 4),
          Text('$price', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Both armies on the actual resolved surface, even before opening the preview.
class _PairingPreview extends StatelessWidget {
  const _PairingPreview({required this.set, required this.surface});
  final PieceSet set;
  final BoardSurface surface;
  @override
  Widget build(BuildContext context) {
    final resolved = surface.harmonizedFor(set);
    return Column(
      children: [
        for (var row = 0; row < 2; row++)
          Expanded(
            child: Row(
              children: [
                for (var col = 0; col < 2; col++)
                  Expanded(
                    child: BoardTile(
                      surface: resolved,
                      file: col,
                      rank: row,
                      child: ColorFiltered(
                        colorFilter:
                            set.filterFor(row == 0 ? Side.black : Side.white) ??
                            const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                        child: Image.asset(
                          set.sculptedAsset(
                            col == 0 ? PieceType.knight : PieceType.rook,
                            row == 0 ? Side.black : Side.white,
                          )!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: ChaturangTheme.parchment.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
