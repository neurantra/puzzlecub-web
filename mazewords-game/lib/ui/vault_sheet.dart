import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/player_store.dart';
import '../services/game_services.dart';
import 'coin_bag.dart';
import '../services/vault/vault_service.dart';
import 'style.dart';

class VaultSheet extends StatefulWidget {
  final PlayerStore game;
  final VaultService? vault;
  final int? shortfall;
  final String adLabel;
  final VoidCallback? reward;
  const VaultSheet({
    super.key,
    required this.game,
    this.vault,
    this.shortfall,
    this.adLabel = 'Watch an ad',
    this.reward,
  });
  @override
  State<VaultSheet> createState() => _VaultSheetState();
}

class _VaultSheetState extends State<VaultSheet> {
  final _code = TextEditingController();
  VaultService? get vault => widget.vault;
  @override
  void initState() {
    super.initState();
    vault?.addListener(_changed);
    widget.game.addListener(_changed);
    unawaited(vault?.refresh());
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    vault?.removeListener(_changed);
    widget.game.removeListener(_changed);
    _code.dispose();
    super.dispose();
  }

  Future<void> _bank(int amount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Transfer $amount coins out?'),
        content: const Text(
          'They will leave Maze Words and wait in your shared vault. Open the coin menu in Fill the Jar, Puzzlecub, or Chaturang to collect them. Link that game using a code first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep here'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Transfer out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await vault?.transfer(amount, bank: true);
  }

  Future<void> _unlink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink this game?'),
        content: const Text(
          'Coins already in Maze Words stay here. To use this shared vault again, get a new code from another linked game.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay linked'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (confirmed == true) await vault?.unlink();
  }

  @override
  Widget build(BuildContext context) {
    final v = vault;
    final busy = v?.busy == true;
    final canMove = !busy && v?.pending == false;
    final amounts = <int>{
      ...[
        10,
        25,
        50,
        100,
        250,
        500,
        1000,
      ].where((n) => n < widget.game.coins).toList().reversed.take(3),
      if (widget.game.coins > 0) widget.game.coins,
    }.toList()..sort();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: 60,
                height: 70,
                child: CustomPaint(
                  painter: CoinBagPainter(progress: 0, coins: 0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your little coin vault',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${widget.game.coins} coins in Maze Words',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: teal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.shortfall == null
                  ? 'Find words to earn coins. Hints cost 5 coins. Your trail progress stays on this device.'
                  : 'You need ${widget.shortfall} more coins. Find more words or collect coins from a linked game.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (v == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  !widget.game.adult
                      ? 'Shared coin transfers and link codes are unavailable for this age profile. A parent or grown-up can correct the birth year in Settings → Age information. You can still earn and use coins in Maze Words.'
                      : 'Shared transfers are not available on this device right now. You can still earn and use coins in Maze Words.',
                  textAlign: TextAlign.center,
                ),
              ),
            if (busy) const LinearProgressIndicator(),
            if (v?.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  v!.error!,
                  style: const TextStyle(color: Color(0xffa32839)),
                ),
              ),
            if (v?.pending == true)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'A transfer is pending. Refresh to finish it safely; it will not be counted twice.',
                ),
              ),
            if (v?.live == true) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: teal),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Neurantra shared vault',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh vault',
                    onPressed: busy ? null : () => v!.refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              Text(
                v!.linked
                    ? '${v.balance ?? '—'} coins ready to collect'
                    : 'Link Fill the Jar, Puzzlecub, or Chaturang to move coins between games.',
              ),
              if (v.linked) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: canMove && (v.balance ?? 0) > 0
                      ? () => v.transfer(v.balance!, bank: false)
                      : null,
                  icon: const Icon(Icons.south_west_rounded),
                  label: const Text('Transfer in · collect all'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Transfer out to the shared vault',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final amount in amounts)
                      OutlinedButton(
                        onPressed: canMove ? () => _bank(amount) : null,
                        child: Text(
                          amount == widget.game.coins
                              ? 'All · $amount'
                              : '$amount',
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Link your games',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Text(
                'Show a code here and enter it in the other game’s coin menu, or enter its code below.',
              ),
              OutlinedButton.icon(
                onPressed: busy || v.pending ? null : () => v.showCode(),
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Show a link code'),
              ),
              if (v.code != null) ...[
                SelectableText(
                  v.code!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w800,
                    color: teal,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: v.code!));
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy code · valid for 30 minutes'),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _code,
                      enabled: !busy && !v.pending,
                      maxLength: 6,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Code from another game',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: busy ? null : (value) => v.link(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: busy || v.pending
                        ? null
                        : () => v.link(_code.text),
                    child: const Text('Link'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Only coins move between games; scores and trail progress stay here. Keep another game linked before reinstalling, because this device’s anonymous link may be lost.',
                style: TextStyle(fontSize: 12),
              ),
              if (v.linked)
                TextButton(
                  onPressed: busy || v.pending ? null : _unlink,
                  child: const Text('Unlink Maze Words'),
                ),
            ] else if (v != null && !busy) ...[
              const SizedBox(height: 12),
              const Text(
                'Shared transfers are currently unavailable. Your Maze Words coins are still yours to play with.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => v.refresh(),
                child: const Text('Check shared vault again'),
              ),
            ],
            if (widget.reward != null) ...[
              const Divider(height: 28),
              FilledButton.icon(
                onPressed: busy ? null : widget.reward,
                icon: const Icon(Icons.play_circle_outline),
                label: Text('${widget.adLabel} · +25 coins'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showCoinVault(
  BuildContext context,
  PlayerStore store,
  GameServices services, {
  int? shortfall,
}) => kIsWeb ? showDialog<void>(context: context, builder: (context) => AlertDialog(
  title: const Text('Your coins'),
  content: Text('${store.coins} coins saved in this browser. Find words and complete mazes to earn more. Hints and optional hunt extras use earned coins. Every difficulty is free to play. There are no shared transfers or purchases on the web.'),
  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to play'))],
)) : showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: paper,
  builder: (_) =>
      VaultSheet(game: store, vault: services.vault, shortfall: shortfall),
);
