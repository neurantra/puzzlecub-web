import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/session.dart';
import '../services/vault/vault_service.dart';
import 'art.dart';

class VaultSheet extends StatefulWidget {
  final GameSession game;
  final VaultService? vault;
  final int? shortfall;
  final String adLabel;
  final VoidCallback? reward;
  const VaultSheet({
    super.key,
    required this.game,
    this.vault,
    this.shortfall,
    required this.adLabel,
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
          'They will leave Fill the Jar and wait in your shared vault. Open the coin menu in PuzzleCub or Chaturang to collect them. Link that game using a code first.',
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
          'Coins already in Fill the Jar stay here. To use this shared vault again, get a new code from another linked game.',
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
    final canMove = !busy && v?.pending == false && !widget.game.solving;
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
            const Icon(
              Icons.savings_rounded,
              color: Color(0xffedab35),
              size: 44,
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
              '${widget.game.coins} coins in Fill the Jar',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: purple,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.shortfall == null
                  ? 'Fill a new jar for +${Economy.firstClear} coins. Replays add +${Economy.replay}. A little progress, a little treasure.'
                  : 'You need ${widget.shortfall} more coins. Collect coins from your shared vault or fill another jar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
                  const Icon(Icons.swap_horiz_rounded, color: purple),
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
                    : 'Link PuzzleCub or Chaturang to move coins between games.',
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
                    fontWeight: FontWeight.w900,
                    color: purple,
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
                'The vault moves coins between games. Collect coins before reinstalling; anonymous game links may be lost.',
                style: TextStyle(fontSize: 12),
              ),
              if (v.linked)
                TextButton(
                  onPressed: busy || v.pending ? null : _unlink,
                  child: const Text('Unlink Fill the Jar'),
                ),
            ] else if (v != null && !busy) ...[
              const SizedBox(height: 12),
              const Text(
                'Shared transfers are currently unavailable. Your Fill the Jar coins are still yours to play with.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () => v.refresh(),
                child: const Text('Check shared vault again'),
              ),
            ],
            if (!widget.game.adsRemoved) ...[
              const Divider(height: 28),
              FilledButton.icon(
                onPressed: busy ? null : widget.reward,
                icon: const Icon(Icons.play_circle_outline),
                label: Text('${widget.adLabel} · +${Economy.adCoins} coins'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Rewards are granted only after completion.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
