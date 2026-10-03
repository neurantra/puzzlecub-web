import 'package:flutter/material.dart';
import '../game/picture_theme.dart';
import '../game/session.dart';
import '../services/pack_purchases.dart';

class PurchaseThemesSheet extends StatefulWidget {
  final GameSession game;
  final PackPurchases purchases;
  const PurchaseThemesSheet({
    super.key,
    required this.game,
    required this.purchases,
  });
  @override
  State<PurchaseThemesSheet> createState() => _PurchaseThemesSheetState();
}

class _PurchaseThemesSheetState extends State<PurchaseThemesSheet> {
  PicturePack? pack;
  PictureTheme? picture;
  GameSession get game => widget.game;
  PackPurchases get store => widget.purchases;
  bool get busy =>
      store.busy ||
      store.loading ||
      game.rewardBusy ||
      game.walletBusy ||
      game.solving;

  Widget _buy(String id, String title) {
    if (game.hasPaidPack(id)) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text('✓ Purchased', textAlign: TextAlign.center),
      );
    }
    final price = store.prices[id];
    return FilledButton(
      key: ValueKey('buy-$id'),
      onPressed: busy || price == null ? null : () => store.buy(id),
      child: Text(price == null ? 'Currently unavailable' : '$title · $price'),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([game, store]),
    builder: (context, _) => SingleChildScrollView(
      key: ValueKey(picture?.id ?? pack?.id ?? 'paid-packs'),
      // Modal bottom sheets do not protect the bottom system navigation area.
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (pack != null)
                IconButton(
                  tooltip: 'Back to packs',
                  onPressed: () => setState(() {
                    if (picture != null) {
                      picture = null;
                    } else {
                      pack = null;
                    }
                  }),
                  icon: const Icon(Icons.arrow_back),
                ),
              Expanded(
                child: Text(
                  picture?.title ?? pack?.title ?? 'Picture Packs',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (store.loading || store.busy) const LinearProgressIndicator(),
          if (store.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                store.message!,
                key: const ValueKey('purchase-message'),
              ),
            ),
          if (pack == null) ...[
            const Text(
              'Every paid pack includes all 100 levels, every picture in that pack, and ad-free play. One purchase. No subscription.',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'All Packs · Lifetime Access',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All current pictures and every future pack. Yours to keep.',
                    ),
                    const SizedBox(height: 10),
                    _buy('all', 'Buy All Packs'),
                    if (!game.hasPaidPack('all') &&
                        [
                          'animals',
                          'vehicles',
                          'landscapes',
                        ].any(game.hasPaidPack))
                      const Text(
                        'The bundle is a separate purchase; earlier individual purchases are not credited.',
                      ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.texture),
              title: const Text('Plain wood'),
              subtitle: Text(
                game.freePlayLimited
                    ? 'Free · levels 1–10'
                    : 'All 100 levels available',
              ),
              trailing: game.activePictureTheme == null
                  ? const Icon(Icons.check_circle)
                  : null,
              onTap: busy ? null : () => game.selectPictureTheme(null),
            ),
            for (final p in PicturePack.catalog)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Image.asset(
                          p.cover,
                          width: 54,
                          height: 68,
                          fit: BoxFit.cover,
                          cacheWidth: 162,
                        ),
                        title: Text(p.title),
                        subtitle: Text(
                          '${p.pictures.length} pictures · all 100 levels',
                        ),
                        onTap: () => setState(() => pack = p),
                      ),
                      _buy(p.id, 'Buy ${p.title}'),
                      TextButton(
                        key: ValueKey('browse-${p.id}'),
                        onPressed: () => setState(() => pack = p),
                        child: const Text('Browse pictures'),
                      ),
                    ],
                  ),
                ),
              ),
            const Text(
              'Free play includes Sunshine Meadow, Woodland Fox, and levels 1–10. Individual packs include future pictures in that category; only All Packs includes future packs.',
            ),
          ] else if (picture != null) ...[
            Image.asset(picture!.asset, height: 280, fit: BoxFit.contain),
            const SizedBox(height: 12),
            if (game.ownsPicture(picture!.id))
              FilledButton(
                onPressed: busy
                    ? null
                    : () => game.selectPictureTheme(picture!.id),
                child: Text(
                  game.activePictureTheme == picture!.id
                      ? '✓ Active picture'
                      : 'Use picture',
                ),
              )
            else ...[
              Text(
                'Included in ${pack!.title}. Unlock every picture in this pack and all 100 levels.',
              ),
              _buy(pack!.id, 'Buy ${pack!.title}'),
            ],
          ] else ...[
            Text(
              game.hasPaidPack(pack!.id)
                  ? 'All pictures included. Tap to preview or activate.'
                  : 'Preview every picture. Woodland Fox is free; other pictures require their pack.',
            ),
            if (!game.hasPaidPack(pack!.id))
              _buy(pack!.id, 'Buy ${pack!.title}'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: .72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                for (final p in pack!.pictures)
                  Card(
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      key: ValueKey('paid-picture-${p.id}'),
                      onTap: () => setState(() => picture = p),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Image.asset(
                              p.asset,
                              fit: BoxFit.cover,
                              cacheWidth: 400,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${p.title}\n${game.activePictureTheme == p.id
                                  ? '✓ Active'
                                  : game.ownsPicture(p.id)
                                  ? 'Included'
                                  : 'Preview'}',
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('restore-purchases'),
            onPressed: busy ? null : store.restore,
            child: const Text('Restore Purchases'),
          ),
          TextButton(
            onPressed: busy ? null : store.refresh,
            child: const Text('Refresh store'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to puzzle'),
          ),
        ],
      ),
    ),
  );
}
