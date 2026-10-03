import 'package:flutter/material.dart';
import '../game/picture_theme.dart';
import '../game/session.dart';

class ThemesSheet extends StatefulWidget {
  final GameSession game;
  final String adLabel;
  final bool adsAllowed;
  final Future<void> Function(PictureTheme) buy, watch;
  final Future<void> Function(PicturePack) buyPack;
  const ThemesSheet({
    super.key,
    required this.game,
    required this.adLabel,
    required this.adsAllowed,
    required this.buy,
    required this.watch,
    required this.buyPack,
  });
  @override
  State<ThemesSheet> createState() => _ThemesSheetState();
}

class _ThemesSheetState extends State<ThemesSheet> {
  PicturePack? _pack;
  PictureTheme? _picture;
  GameSession get game => widget.game;
  bool get busy => game.rewardBusy || game.walletBusy;

  Future<void> _openPack(PicturePack pack) async {
    if (game.freePlayLimited) {
      setState(() => _pack = pack);
      return;
    }
    if (!game.ownedPicturePacks.contains(pack.id)) await widget.buyPack(pack);
    if (mounted && game.ownedPicturePacks.contains(pack.id)) {
      setState(() => _pack = pack);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: game,
    builder: (context, _) => SingleChildScrollView(
      key: ValueKey(_picture?.id ?? _pack?.id ?? 'packs'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (_pack != null)
                IconButton(
                  tooltip: _picture != null
                      ? 'Back to pictures'
                      : 'Back to packs',
                  onPressed: () => setState(() {
                    if (_picture != null) {
                      _picture = null;
                    } else {
                      _pack = null;
                    }
                  }),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Expanded(
                child: Text(
                  _picture?.title ?? _pack?.title ?? 'Picture Themes',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Icon(Icons.monetization_on_outlined, size: 18),
              const SizedBox(width: 4),
              Text(
                '${game.coins}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pack == null)
            ..._packs(context)
          else if (_picture != null)
            ..._detail(context, _picture!)
          else ...[
            Text(
              game.freePlayLimited
                  ? 'Woodland Fox is included free. Preview the other pictures here; pack purchases are coming soon.'
                  : 'Tap a picture to preview or activate it. Each picture unlocks permanently for 60 coins or one completed rewarded ad.',
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: constraints.maxWidth >= 550 ? 3 : 2,
                childAspectRatio: .72,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final picture in _pack!.pictures)
                    _tile(context, picture),
                ],
              ),
            ),
          ],
          if (game.rewardBusy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const Text('Waiting for your reward…', textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to puzzle'),
          ),
        ],
      ),
    ),
  );

  List<Widget> _packs(BuildContext context) => [
    Text(
      game.freePlayLimited
          ? 'Free play includes Sunshine Meadow, Woodland Fox, and levels 1–10. Pack purchases are coming soon.'
          : 'Open a pack for 30 coins, then unlock the pictures you like. Pictures cost 60 coins or one completed rewarded ad each.',
    ),
    const SizedBox(height: 6),
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.texture_rounded),
      title: const Text('Plain wood'),
      trailing: !game.pictureClues ? const Icon(Icons.check_circle) : null,
      onTap: busy ? null : () => game.selectPictureTheme(null),
    ),
    for (final pack in PicturePack.catalog)
      Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  pack.cover,
                  width: 90,
                  height: 120,
                  fit: BoxFit.cover,
                  cacheWidth: 270,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pack.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      game.freePlayLimited
                          ? '${pack.pictures.length} pictures'
                          : '${pack.pictures.length} pictures · sold separately',
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: ValueKey('pack-${pack.id}'),
                      onPressed:
                          busy ||
                              (!game.freePlayLimited &&
                                  !game.ownedPicturePacks.contains(pack.id) &&
                                  game.coins < pack.coins)
                          ? null
                          : () => _openPack(pack),
                      child: Text(
                        game.freePlayLimited
                            ? (pack.id == 'animals'
                                  ? 'Open pack · 1 free picture'
                                  : 'Preview pack')
                            : game.ownedPicturePacks.contains(pack.id)
                            ? 'Open pack'
                            : 'Unlock pack · ${pack.coins} coins',
                      ),
                    ),
                    if (!game.freePlayLimited &&
                        !game.ownedPicturePacks.contains(pack.id) &&
                        game.coins < pack.coins)
                      Text('${pack.coins - game.coins} more coins needed'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
  ];

  Widget _tile(BuildContext context, PictureTheme picture) {
    final owned =
        game.canUsePicture(picture.id) &&
        game.ownedPictureThemes.contains(picture.id);
    final active = game.activePictureTheme == picture.id;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        key: ValueKey('picture-${picture.id}'),
        onTap: busy
            ? null
            : () {
                if (owned) {
                  game.selectPictureTheme(picture.id);
                } else {
                  setState(() => _picture = picture);
                }
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    picture.asset,
                    fit: BoxFit.cover,
                    cacheWidth: 480,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      tooltip: 'Preview ${picture.title}',
                      iconSize: 18,
                      onPressed: () => setState(() => _picture = picture),
                      icon: const Icon(Icons.fullscreen),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    picture.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    active
                        ? '✓ Active'
                        : owned
                        ? 'Tap to activate'
                        : game.freePlayLimited
                        ? 'Included with paid pack'
                        : '${picture.coins} coins / ad',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _detail(BuildContext context, PictureTheme picture) => [
    ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(picture.asset, height: 280, fit: BoxFit.contain),
    ),
    const SizedBox(height: 14),
    Text(
      game.freePlayLimited
          ? (game.canUsePicture(picture.id)
                ? 'Free picture · play levels 1–10'
                : 'Included with a paid pack · purchases coming soon')
          : 'Permanent picture unlock · use on every level',
      textAlign: TextAlign.center,
    ),
    const SizedBox(height: 10),
    if (game.canUsePicture(picture.id) &&
        game.ownedPictureThemes.contains(picture.id))
      FilledButton.icon(
        onPressed: busy ? null : () => game.selectPictureTheme(picture.id),
        icon: Icon(
          game.activePictureTheme == picture.id
              ? Icons.check
              : Icons.image_outlined,
        ),
        label: Text(
          game.activePictureTheme == picture.id ? 'Active theme' : 'Use theme',
        ),
      )
    else if (!game.freePlayLimited) ...[
      FilledButton(
        onPressed: busy || game.coins < picture.coins
            ? null
            : () => widget.buy(picture),
        child: Text('Unlock · ${picture.coins} coins'),
      ),
      if (game.coins < picture.coins)
        Text(
          '${picture.coins - game.coins} more coins needed. Earn coins by filling jars.',
          textAlign: TextAlign.center,
        ),
      if (widget.adsAllowed)
        OutlinedButton.icon(
          onPressed: busy ? null : () => widget.watch(picture),
          icon: const Icon(Icons.play_circle_outline),
          label: Text('${widget.adLabel} · unlock forever'),
        ),
    ],
  ];
}
