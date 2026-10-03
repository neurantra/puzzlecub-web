import '../web_bridge.dart';
import '../services/pack_purchases.dart';
import 'purchase_themes_sheet.dart';
import '../services/interstitial_ads.dart';
import 'package:flutter/gestures.dart';
import 'tutorial.dart';
import 'age_information.dart';
import 'app_icon.dart';
import 'dart:async';
import '../services/audience.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import '../game/geometry.dart';
import '../game/session.dart';
import '../game/picture_theme.dart';
import 'themes_sheet.dart';
import '../services/services.dart';
import 'art.dart';
import 'wooden_jar.dart';
import 'jar_presentation.dart';
import 'coin_kitty.dart';
import 'landing_arrows.dart';
import 'picture_art.dart';
import 'scene_backdrop.dart';
import 'family_games.dart';
import 'vault_sheet.dart';
import '../services/vault/vault_service.dart';
import '../services/vault/firebase_vault.dart';

class GameScreen extends StatefulWidget {
  final GameSession session;
  final PackPurchases? purchases;
  final bool startPicturePrototype;
  final RewardAds? rewardAds;
  final Audience? audience;
  final ValueChanged<Audience>? onAudienceChanged;
  final SaveStore? store;
  // Supply the SDK-reported size only after a banner has loaded.
  final Widget? banner;
  final Size? bannerSize;
  const GameScreen({
    super.key,
    required this.session,
    this.purchases,
    this.startPicturePrototype = false,
    this.rewardAds,
    this.store,
    this.audience,
    this.onAudienceChanged,
    this.banner,
    this.bannerSize,
  }) : assert((banner == null) == (bannerSize == null));
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameSession get game => widget.session;
  final _sounds = Sounds();
  final _coinSounds = Sounds();
  late final RewardAds _ads;
  late final InterstitialAds _interstitials;
  bool _advancing = false;
  bool get _adsAllowed => !kIsWeb && _online && !game.adsRemoved;
  bool get _online => widget.audience?.externalServicesAllowed ?? false;
  final _jarKey = GlobalKey();
  int? _movingPiece;
  Offset _pieceGrab = Offset.zero;
  bool _boardDrag = false, _pieceMoved = false;
  bool _rewardBusy = false, _solveLoop = false;
  bool _wooden = true;
  final _trayScroll = ScrollController();
  final _trayAtBottom = ValueNotifier(false);
  int _trayColumns = 4;
  double _trayRowHeight = 82;
  bool _trayScrollable = false;
  VaultService? _sharedVault;
  @override
  void initState() {
    super.initState();
    setWebAdsAllowed(_online);
    unawaited(
      WoodMaterial.load().catchError((Object error) {
        debugPrint('Wood material unavailable: $error');
      }),
    );
    _loadThemeArt();
    _ads =
        widget.rewardAds ??
        RewardAds(allowed: _online, eligible: () => !game.adsRemoved);
    _interstitials = InterstitialAds(_ads);
    if (_adsAllowed) unawaited(_interstitials.preload());
    if (!kIsWeb && _online && widget.store != null) {
      _sharedVault = VaultService(
        game,
        FirebaseVault(widget.store!.prefs),
        widget.store!.persist,
      );
    }
    game.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.startPicturePrototype) {
        unawaited(_themes());
        return;
      }
      final prefs = widget.store?.prefs;
      if (prefs != null &&
          prefs.getBool(tutorialSeenKey) != true &&
          game.unlocked == 1 &&
          game.board.isEmpty &&
          game.completed.isEmpty &&
          game.puzzle.preview == null &&
          !game.solving) {
        unawaited(_firstTutorial());
      }
      if (game.solving) _animateSolve();
      if (game.vaultTransfers.isNotEmpty) unawaited(_sharedVault?.refresh());
    });
  }

  Future<void> _firstTutorial() async {
    await showTutorial(
      context,
      sound: game.sound,
      pictureAsset: game.pictureTheme?.asset ?? PictureArt.asset,
    );
    if (mounted) await widget.store?.prefs.setBool(tutorialSeenKey, true);
  }

  void _loadThemeArt() {
    if (game.pictureClues) {
      _wooden = true;
      unawaited(
        PictureArt.load(asset: game.pictureTheme!.asset).catchError((
          Object error,
        ) {
          debugPrint('Theme image unavailable: $error');
        }),
      );
    }
  }

  void _changed() {
    if (game.adsRemoved) _interstitials.clear();
    _loadThemeArt();
    if (!game.walletBusy) widget.store?.write(game.encode());
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        (_sharedVault?.live == true || game.vaultTransfers.isNotEmpty)) {
      unawaited(_sharedVault?.refresh());
    }
    if (state != AppLifecycleState.resumed && !game.walletBusy) {
      widget.store?.write(game.encode());
      widget.store?.flush();
    }
  }

  @override
  void dispose() {
    game.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    _interstitials.dispose();
    _ads.dispose();
    _sounds.dispose();
    _coinSounds.dispose();
    _trayScroll.dispose();
    _trayAtBottom.dispose();
    super.dispose();
  }

  void _sound(String effect) {
    unawaited(_sounds.play(effect, game.sound));
    if (game.haptics && !kIsWeb) HapticFeedback.selectionClick();
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _themes() async {
    unawaited(widget.purchases?.refresh());
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * .88,
        ),
        child: widget.purchases != null
            ? PurchaseThemesSheet(game: game, purchases: widget.purchases!)
            : ThemesSheet(
                game: game,
                adLabel: _adLabel,
                adsAllowed: _adsAllowed,
                buyPack: (pack) async {
                  if (!await _confirm(
                    'Open ${pack.title}?',
                    'Unlock this pack for ${pack.coins} coins. Pictures are purchased separately for 60 coins or one completed rewarded ad each.',
                    'Unlock pack · ${pack.coins} coins',
                  )) {
                    return;
                  }
                  if (!mounted) return;
                  if (game.unlockPicturePack(pack.id)) {
                    await widget.store?.flush();
                    if (mounted) _sound('coin');
                  }
                },
                buy: (theme) async {
                  if (!await _confirm(
                    'Unlock ${theme.title}?',
                    'Spend ${theme.coins} coins to keep this picture theme forever and use it on every level?',
                    'Unlock · ${theme.coins} coins',
                  )) {
                    return;
                  }
                  if (!mounted) return;
                  if (game.unlockPictureTheme(theme.id)) {
                    await widget.store?.flush();
                    if (mounted) _sound('coin');
                  }
                },
                watch: (theme) async {
                  await _reward(themeId: theme.id);
                },
              ),
      ),
    );
  }

  void _pictureReference() {
    final theme = game.pictureTheme;
    if (theme == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(ctx).height * .85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        theme.title,
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close picture',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    theme.asset,
                    fit: BoxFit.contain,
                    semanticLabel: '${theme.title}, full reference picture',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _load(Puzzle puzzle) {
    final current = [
      ...game.levels,
      ...game.previews,
    ].where((p) => p.key == puzzle.key);
    game.load(current.isEmpty ? puzzle : current.first);
    _scrollTrayTo(0);
  }

  void _scrollTrayTo(double offset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_trayScroll.hasClients) return;
      _trayScroll.jumpTo(
        offset.clamp(0.0, _trayScroll.position.maxScrollExtent),
      );
    });
  }

  void _reveal(int id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_trayScroll.hasClients) return;
      final index = game.groups.indexWhere(
        (g) => g.members.any((p) => p.id == id),
      );
      if (index < 0) return;
      final top = (index ~/ _trayColumns) * _trayRowHeight;
      final bottom = top + _trayRowHeight;
      final position = _trayScroll.position;
      final target = top < position.pixels
          ? top
          : bottom > position.pixels + position.viewportDimension
          ? bottom - position.viewportDimension
          : position.pixels;
      final offset = target.clamp(0.0, position.maxScrollExtent);
      if (game.motion && !MediaQuery.disableAnimationsOf(context)) {
        _trayScroll.animateTo(
          offset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _trayScroll.jumpTo(offset);
      }
    });
  }

  void _drop() {
    if (game.drop() && !_wooden) _sound(game.complete ? 'win' : 'drop');
  }

  void _remove(Piece p) {
    if (game.remove(p)) {
      _reveal(p.id);
      _sound('lift');
      setState(() {});
    }
  }

  Rect _jarBounds(Size size, Puzzle puzzle) => _wooden
      ? WoodenJarPainter.bounds(size, puzzle)
      : JarPainter.bounds(size, puzzle);

  void _aimGlobal(Offset global) {
    final box = _jarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final rect = _jarBounds(box.size, game.puzzle);
    final local = box.globalToLocal(global);
    game.aim((local.dx - rect.left) / (rect.width / game.puzzle.w));
  }

  Offset? _jarPoint(Offset global) {
    final box = _jarKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final rect = _jarBounds(box.size, game.puzzle);
    return (box.globalToLocal(global) - rect.topLeft) /
        (rect.width / game.puzzle.w);
  }

  void _startJarDrag(DragStartDetails details) {
    _movingPiece = null;
    _boardDrag = false;
    _pieceMoved = false;
    final point = _jarPoint(details.globalPosition);
    if (point == null) return;
    final hit = pieceAt(game.board, point);
    _boardDrag = hit != null;
    if (hit != null && canLift(game.board, hit)) {
      _movingPiece = hit.id;
      _pieceGrab = point - Offset(hit.x, hit.y);
    }
  }

  void _updateJarDrag(DragUpdateDetails details) {
    if (!_boardDrag) {
      _aimGlobal(details.globalPosition);
      return;
    }
    final point = _jarPoint(details.globalPosition);
    if (_movingPiece == null || point == null) return;
    final target = point - _pieceGrab;
    if (game.movePlacedPiece(
      _movingPiece!,
      Offset((target.dx * 2).round() / 2, (target.dy * 2).round() / 2),
    )) {
      _pieceMoved = true;
    }
  }

  void _endJarDrag({bool canceled = false}) {
    if (_boardDrag) {
      if (_pieceMoved) _sound(game.complete ? 'win' : 'click');
    } else if (!canceled) {
      _drop();
    }
    _movingPiece = null;
    _boardDrag = false;
    _pieceMoved = false;
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _hint() async {
    if (game.solving || game.complete || _rewardBusy || game.walletBusy) return;
    if (game.coins < Economy.hint && game.hintCredits == 0 && !_adsAllowed) {
      await _vault(shortfall: Economy.hint - game.coins);
      return;
    }
    final puzzleKey = game.puzzle.key;
    final reset = nextHint(game.puzzle, game.board) == null;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(reset ? 'Make a little room?' : 'A little nudge?'),
        content: Text(
          reset
              ? 'This arrangement needs a fresh start. Restart this jar and reveal a fitting piece?'
              : 'Reveal one piece and highlight exactly where it belongs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          if (_adsAllowed)
            TextButton.icon(
              onPressed: () => Navigator.pop(ctx, 'ad'),
              icon: const Icon(Icons.play_circle_outline),
              label: Text('$_adLabel · 1 hint'),
            ),
          if (game.hintCredits > 0)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'credit'),
              child: Text('Use saved hint (${game.hintCredits})'),
            )
          else
            FilledButton(
              onPressed: game.coins >= Economy.hint
                  ? () => Navigator.pop(ctx, 'coins')
                  : null,
              child: const Text('Use ${Economy.hint} coins'),
            ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'ad' && !await _reward(forHint: true)) return;
    if (!mounted ||
        game.puzzle.key != puzzleKey ||
        game.complete ||
        game.solving ||
        game.walletBusy) {
      return;
    }
    // A canceled or unavailable ad must never reset the board or consume coins.
    if (reset) _load(game.puzzle);
    if (game.buyHint(useCredit: choice != 'coins')) {
      _reveal(game.selected!.id);
      _sound('tap');
      setState(() {});
    }
  }

  Future<void> _solve() async {
    if (game.solving || game.complete || _rewardBusy) return;
    if (game.coins < Economy.solve) {
      await _vault(shortfall: Economy.solve - game.coins);
      return;
    }
    if (!await _confirm(
      'Every piece has a place.',
      'Auto-solve restarts this jar and drops every piece into its perfect spot. Cost: ${Economy.solve} coins.',
      'Solve · ${Economy.solve} coins',
    )) {
      return;
    }
    if (!mounted) return;
    if (game.beginSolve()) await _animateSolve();
  }

  Future<void> _animateSolve() async {
    if (_solveLoop) return;
    _solveLoop = true;
    try {
      final steps = solution(game.puzzle);
      for (final p in steps.skip(game.board.length)) {
        await Future<void>.delayed(const Duration(milliseconds: 360));
        if (!mounted) return;
        game.solveStep(p);
        if (!_wooden) _sound(game.complete ? 'win' : 'drop');
      }
    } finally {
      _solveLoop = false;
    }
  }

  Future<bool> _reward({String? themeId, bool forHint = false}) async {
    if (!_adsAllowed ||
        _rewardBusy ||
        game.rewardBusy ||
        game.walletBusy ||
        game.solving) {
      return false;
    }
    if (themeId != null &&
        (PictureTheme.find(themeId) == null ||
            !game.ownedPicturePacks.contains(
              PictureTheme.find(themeId)!.packId,
            ) ||
            game.ownedPictureThemes.contains(themeId))) {
      return false;
    }
    setState(() => _rewardBusy = game.rewardBusy = true);
    game.refresh();
    RewardOutcome result = RewardOutcome.unavailable;
    try {
      if (_ads.simulatedPreview) {
        final accepted = await _confirm(
          'Development preview',
          'No ad is played. Simulate a completed reward for ${themeId != null
              ? PictureTheme.find(themeId)!.title
              : forHint
              ? 'one hint'
              : 'the coin vault'}?',
          'Simulate earned reward',
        );
        result = accepted ? RewardOutcome.earned : RewardOutcome.closed;
      } else {
        result = await _ads.show();
      }
    } catch (_) {
      result = RewardOutcome.unavailable;
    } finally {
      _rewardBusy = game.rewardBusy = false;
      if (mounted) setState(() {});
      game.refresh();
    }
    if (result == RewardOutcome.earned) {
      if (themeId != null) {
        game.unlockPictureTheme(themeId, rewarded: true);
      } else if (forHint) {
        game.earnHintCredit();
      } else {
        game.earnedAd();
      }
      // Persist the reward even if the sheet or screen closed while the ad ran.
      await widget.store?.persist(game.encode());
      if (mounted) {
        _sound('coin');
        _notice(
          themeId != null
              ? '${PictureTheme.find(themeId)!.title} unlocked forever.'
              : forHint
              ? 'One hint earned.'
              : '+${Economy.adCoins} coins tucked into your vault.',
        );
      }
      return true;
    }
    if (mounted) {
      _notice(
        result == RewardOutcome.unavailable
            ? 'No ad is available right now. Nothing was spent. Try again later.'
            : 'Reward not completed. Nothing was spent.',
      );
    }
    return false;
  }

  String get _adLabel =>
      _ads.simulatedPreview ? 'Preview reward · no ad' : 'View ad';
  Future<void> _vault({int? shortfall}) async {
    if (kIsWeb || !_online) {
      _info(
        'Your coins',
        '${game.coins} coins saved on this device.\n\nFill new jars to earn ${Economy.firstClear} coins, or replay completed jars for ${Economy.replay}. Hints cost ${Economy.hint} and auto-solve costs ${Economy.solve}. Every puzzle can be solved without spending coins. Coins are earned through play and stay in this browser.',
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * .88,
        ),
        child: VaultSheet(
          game: game,
          vault: _sharedVault,
          shortfall: shortfall,
          adLabel: _adLabel,
          reward: !_adsAllowed || _rewardBusy || game.solving
              ? null
              : () {
                  Navigator.pop(ctx);
                  _reward();
                },
        ),
      ),
    );
  }

  void _info(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Lovely'),
          ),
        ],
      ),
    );
  }

  Future<void> _ageInformation() async {
    if (game.walletBusy ||
        game.vaultTransfers.isNotEmpty ||
        game.solving ||
        _rewardBusy ||
        _advancing) {
      _notice(
        'Let the current solve, ad, or coin transfer finish before changing age information.',
      );
      return;
    }
    if (!await ageParentGate(context) || !mounted) return;
    int? saved;
    final changed = await showAgeInformation(
      context,
      birthYear: widget.audience?.birthYear,
      save: (year) async {
        if (game.walletBusy ||
            game.vaultTransfers.isNotEmpty ||
            game.solving ||
            _rewardBusy ||
            _advancing) {
          throw StateError('Busy');
        }
        if (widget.store != null &&
            !await widget.store!.prefs.setInt(Audience.key, year)) {
          throw StateError('Save failed');
        }
        saved = year;
      },
    );
    if (changed && mounted) widget.onAudienceChanged?.call(Audience(saved));
  }

  void _settings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Make yourself at home.',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                if (widget.onAudienceChanged != null)
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Age information'),
                    subtitle: Text(
                      'Birth year: ${widget.audience?.birthYear ?? "Not provided"} · parent gate',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _ageInformation();
                    },
                  ),
                SwitchListTile(
                  title: const Text('Glass jar & wooden pieces'),
                  subtitle: const Text(
                    'An open glass vessel with tactile wooden blocks',
                  ),
                  value: _wooden,
                  onChanged: game.pictureClues
                      ? null
                      : (v) {
                          setState(() => _wooden = v);
                          update(() {});
                        },
                ),
                if (game.pictureClues)
                  SwitchListTile(
                    title: const Text('Faint picture guide'),
                    subtitle: const Text(
                      'Show the picture behind the empty spaces',
                    ),
                    value: game.showPictureGuide,
                    onChanged: (value) {
                      game.showPictureGuide = value;
                      game.refresh();
                      update(() {});
                    },
                  ),
                SwitchListTile(
                  title: const Text('Sound effects'),
                  subtitle: const Text('Little drops, lovely chimes'),
                  value: game.sound,
                  onChanged: (v) {
                    game.toggleSound(v);
                    update(() {});
                    if (v) _sound('tap');
                  },
                ),
                SwitchListTile(
                  title: const Text('Animated scenery'),
                  subtitle: const Text(
                    'Slow clouds, bubbles and twinkling stars',
                  ),
                  value: game.motion,
                  onChanged: (v) {
                    game.motion = v;
                    game.refresh();
                    update(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Gentle haptics'),
                  value: game.haptics,
                  onChanged: (v) {
                    game.toggleHaptics(v);
                    update(() {});
                  },
                ),
                if (_adsAllowed) ...[
                  const Divider(),
                  for (final family in FamilyGame.values)
                    ListTile(
                      leading: const Icon(Icons.extension_outlined),
                      title: Text('Play ${family.title}'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => openFamilyGame(ctx, family),
                    ),
                ],
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No clock. No pressure. Just the joy of fitting things together.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _levels() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              children: [
                const Text(
                  'Your little journey',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  game.freePlayLimited
                      ? 'Free play · levels 1–${game.accessibleLevelCount}'
                      : 'Campaign progress: level ${game.unlocked} of ${game.levels.length}',
                ),
                const SizedBox(height: 8),
                Text(
                  game.freePlayLimited
                      ? 'Sunshine Meadow is free. Complete each jar to unlock the next. Any paid pack unlocks all 100 levels and scenes.'
                      : 'New shapes arrive as you progress. Complete each jar to unlock the next level.',
                ),
                const SizedBox(height: 20),
                for (
                  int world = 0;
                  world < (game.freePlayLimited ? 1 : 4);
                  world++
                ) ...[
                  Text(
                    '${sceneNames[world]} · ${world * 25 + 1}–${game.freePlayLimited ? game.accessibleLevelCount : (world + 1) * 25}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: game.levels
                        .where(
                          (p) =>
                              sceneForLevel(p.number) == world &&
                              game.canPlay(p),
                        )
                        .map(
                          (p) => SizedBox(
                            width: 48,
                            height: 48,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: game.completed.contains(p.key)
                                    ? const Color(0xff45bba0)
                                    : purple,
                              ),
                              onPressed:
                                  p.number <= game.unlocked && !game.solving
                                  ? () {
                                      Navigator.pop(ctx);
                                      _load(p);
                                    }
                                  : null,
                              child: Text(
                                p.number <= game.unlocked ? '${p.number}' : '·',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rate() async {
    if (kIsWeb || !const bool.fromEnvironment('STORE_RELEASE')) {
      _info(
        'A little love goes a long way.',
        'Store ratings will be available once Fill the Jar is published on the App Store and Google Play. Thanks for helping shape this first version.',
      );
      return;
    }
    try {
      if (await InAppReview.instance.isAvailable()) {
        await InAppReview.instance.requestReview();
      } else {
        _notice('Store ratings are not available on this device right now.');
      }
    } catch (_) {
      _notice('Could not open store ratings right now.');
    }
  }

  Widget _drawer() => Drawer(
    child: SafeArea(
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JarAppIcon(size: 40),
                SizedBox(height: 10),
                Text(
                  'fill the jar',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                Text('Small pieces. Big satisfaction.'),
              ],
            ),
          ),
          _menu(Icons.map_rounded, 'Levels & scenes', _levels),
          _menu(Icons.image_rounded, 'Picture Themes', _themes),
          _menu(
            Icons.play_circle_outline,
            'Watch tutorial',
            () => showTutorial(
              context,
              sound: game.sound,
              pictureAsset: game.pictureTheme?.asset ?? PictureArt.asset,
            ),
          ),
          _menu(Icons.savings_rounded, 'Coin vault', () => _vault()),
          _menu(Icons.settings_rounded, 'Settings', _settings),
          _menu(Icons.restart_alt, 'Restart level', _restart),
          const Divider(),
          if (_adsAllowed)
            _menu(
              Icons.extension_rounded,
              'Play PuzzleCub',
              () => openFamilyGame(context, FamilyGame.puzzlecub),
            ),
          if (_adsAllowed)
            _menu(
              Icons.sports_esports_rounded,
              'Play Chaturang',
              () => openFamilyGame(context, FamilyGame.chaturang),
            ),
          if (_adsAllowed)
            _menu(
              Icons.route_rounded,
              'Play Maze Words',
              () => openFamilyGame(context, FamilyGame.mazewords),
            ),
          _menu(
            Icons.help_outline_rounded,
            'How to play',
            () => _info(
              'Everything fits.',
              'Choose a pile, aim, and drop. Only identical size, shape, and direction share a pile. Rotate the selected piece to find a fit.\n\nTap a placed piece to lift it out if its upward path is clear. Undo and restart are free.\n\nHints cost ${Economy.hint} coins. Auto-solve costs ${Economy.solve}. Each new jar earns ${Economy.firstClear}; replays earn ${Economy.replay}. ${_adsAllowed ? "Optional rewarded ads add ${Economy.adCoins} coins." : "Earn more coins by filling jars and replaying levels."}\n\nNo clock. No pressure.',
            ),
          ),
          const Divider(),
          _menu(
            Icons.info_outline_rounded,
            'About',
            () => _info(
              'Good things come in pieces.',
              'Fill the Jar: Shape Puzzle\nWeb edition\n\nA block, a few cuts, and a jar. Find a little room for every piece.\n\nMade by Neurantra.\n\n100 levels, four colorful worlds, and a little joy in every fit.',
            ),
          ),
          if (!kIsWeb && _online)
            _menu(Icons.star_outline_rounded, 'Rate the game', () => _rate()),
          _menu(
            Icons.privacy_tip_outlined,
            'Privacy',
            () => _info(
              'Your space, your choices.',
              'Progress, coins, and settings stay in this browser. All 100 levels are free. Earn coins by solving jars to unlock picture themes. There are no purchases or shared coin vaults on the web. Anonymous usage statistics help improve the games. Visit puzzlecub.com/privacy for details and your choices.',
            ),
          ),
          if (!kIsWeb && _online)
            _menu(
              Icons.manage_accounts_outlined,
              'Ad privacy choices',
              () async {
                if (!await _ads.privacyOptions()) {
                  _notice(
                    'No ad privacy form is required or available right now.',
                  );
                }
              },
            ),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'A little space. A perfect fit.',
              style: TextStyle(color: purple, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _menu(IconData icon, String label, VoidCallback action) => ListTile(
    leading: Icon(icon, color: purple),
    title: Text(label),
    onTap: () {
      Navigator.pop(context);
      action();
    },
  );
  @override
  Widget build(BuildContext context) {
    final scene = sceneForLevel(game.puzzle.number);
    return Scaffold(
      drawer: _drawer(),
      bottomNavigationBar: !_adsAllowed || widget.banner == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: widget.bannerSize!.height,
                  child: Center(
                    child: SizedBox.fromSize(
                      size: widget.bannerSize,
                      child: ClipRect(child: widget.banner!),
                    ),
                  ),
                ),
              ),
            ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _wooden && game.pictureClues
                ? WorkshopBackdrop(motion: game.motion)
                : SceneBackdrop(scene: scene, animated: game.motion),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                key: const ValueKey('home-scroll'),
                child: Column(
                  children: [
                    SizedBox(
                      height: constraints.maxHeight,
                      child: Column(
                        children: [
                          _topBar(scene),
                          _actions(),
                          _levelHeader(scene),
                          Expanded(child: _jar()),
                          if (!game.complete)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              child: Text(
                                game.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          if (game.complete) _completionBar() else _trayPanel(),
                          // Scaffold lays the banner out below this entire play area.
                        ],
                      ),
                    ),
                    if (_adsAllowed) const FamilyGames(),
                  ],
                ),
              ),
            ),
          ),
          if (_rewardBusy)
            Positioned.fill(
              child: ColoredBox(
                color: ink.withValues(alpha: .40),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Getting your reward ready…'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _restart() async {
    if (game.solving) return;
    if (game.board.isEmpty ||
        await _confirm(
          'Restart this level?',
          'Return every piece to its pile. Your coins stay the same.',
          'Restart',
        )) {
      _load(game.puzzle);
    }
  }

  Widget _topBar(int scene) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Row(
      children: [
        Builder(
          builder: (ctx) => IconButton(
            tooltip: 'Open menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        Semantics(
          label: 'Fill the Jar app icon',
          image: true,
          child: const JarAppIcon(size: 34),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                game.puzzle.preview != null
                    ? game.puzzle.title
                    : 'Level ${game.puzzle.number.toString().padLeft(2, '0')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                game.pictureTheme?.title ?? sceneNames[scene],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (game.pictureClues)
          IconButton(
            tooltip: 'Picture reference',
            onPressed: _pictureReference,
            icon: const Icon(Icons.image_outlined),
          ),
        CoinKitty(
          coins: game.coins,
          motion: game.motion,
          onTap: () => _vault(),
          onDeposit: () => unawaited(_coinSounds.play('coin', game.sound)),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: _settings,
          icon: const Icon(Icons.settings_rounded, size: 22),
        ),
      ],
    ),
  );

  Widget _levelHeader(int scene) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
    child: Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: game.fill,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: .65),
              color: purple,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${game.board.length}/${game.puzzle.pieces.length} · ${(game.fill * 100).round()}%',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _jar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    child: Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, c) => JarPresentation(
              puzzleKey: game.puzzle.key,
              complete: game.complete,
              motion: game.motion,
              builder: (context, reveal) => Transform(
                alignment: Alignment.center,
                transform: _wooden ? woodenCamera() : Matrix4.identity(),
                child: GestureDetector(
                  key: _jarKey,
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    if (game.solving || game.complete) return;
                    final r = _jarBounds(
                          Size(c.maxWidth, c.maxHeight),
                          game.puzzle,
                        ),
                        scale = r.width / game.puzzle.w,
                        point = (details.localPosition - r.topLeft) / scale;
                    final hit = pieceAt(game.board, point);
                    if (hit != null) {
                      _remove(hit);
                    } else {
                      game.aimAt(point);
                      _drop();
                    }
                  },
                  dragStartBehavior: DragStartBehavior.down,
                  onPanStart: _startJarDrag,
                  onPanUpdate: _updateJarDrag,
                  onPanEnd: (_) => _endJarDrag(),
                  onPanCancel: () => _endJarDrag(canceled: true),
                  child: Semantics(
                    label:
                        'Puzzle jar. Drag a clear piece sideways or down. Tap to lift it out.',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _wooden
                            ? WoodenJar(
                                puzzle: game.puzzle,
                                board: List.of(game.board),
                                ghost: null,
                                pictureClues: game.pictureClues,
                                reveal: reveal,
                                showReference: game.showPictureGuide,
                                onLanded: () =>
                                    _sound(game.complete ? 'win' : 'click'),
                                motion:
                                    game.motion &&
                                    !MediaQuery.disableAnimationsOf(context),
                              )
                            : CustomPaint(
                                painter: JarPainter(
                                  game.puzzle,
                                  List.of(game.board),
                                  null,
                                  game.dimension,
                                ),
                                size: Size.infinite,
                              ),
                        if (game.selected != null &&
                            !game.solving &&
                            !game.complete)
                          LandingArrows(
                            landings: game.availableLandings,
                            recommended: game.hintedPlacement,
                            bounds: _jarBounds(
                              Size(c.maxWidth, c.maxHeight),
                              game.puzzle,
                            ),
                            jarWidth: game.puzzle.w,
                            motion:
                                game.motion &&
                                !MediaQuery.disableAnimationsOf(context),
                            onChoose: (piece) {
                              game.aim(piece.x, grab: 0);
                              _drop();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Widget _trayPanel() => Container(
    margin: const EdgeInsets.fromLTRB(8, 2, 8, 0),
    padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: ink.withValues(alpha: .08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (ctx, c) {
        final columns = math.max(3, (c.maxWidth / 76).floor());
        // Give narrow shapes more vertical room without crowding short screens.
        final tileHeight = MediaQuery.sizeOf(ctx).height < 650 ? 71.0 : 79.0;
        final groups = game.groups;
        final rows = (groups.length / columns).ceil();
        _trayColumns = columns;
        _trayRowHeight = tileHeight + 3;
        _trayScrollable = rows > 2;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'YOUR LITTLE PIECE PILES',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                    ),
                  ),
                  if (_trayScrollable)
                    ValueListenableBuilder<bool>(
                      valueListenable: _trayAtBottom,
                      builder: (context, atBottom, _) {
                        return Semantics(
                          liveRegion: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                atBottom
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_up_rounded,
                                color: purple,
                                size: 20,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    atBottom
                                        ? 'Swipe down for earlier'
                                        : 'Swipe up for more',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: purple,
                                    ),
                                  ),
                                  const Text(
                                    'Hold a piece to drag',
                                    style: TextStyle(fontSize: 8, color: ink),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            SizedBox(
              height: math.min(2, rows) * _trayRowHeight + 4,
              child: NotificationListener<Notification>(
                onNotification: (notification) {
                  final ScrollMetrics? metrics =
                      notification is ScrollMetricsNotification
                      ? notification.metrics
                      : notification is ScrollNotification
                      ? notification.metrics
                      : null;
                  if (metrics != null) {
                    _trayAtBottom.value =
                        metrics.maxScrollExtent > 0 && metrics.extentAfter < 2;
                  }
                  return false;
                },
                child: Scrollbar(
                  controller: _trayScroll,
                  thumbVisibility: _trayScrollable,
                  thickness: 3,
                  radius: const Radius.circular(3),
                  child: GridView.builder(
                    key: const ValueKey('piece-tray-scroll'),
                    controller: _trayScroll,
                    primary: false,
                    physics: _trayScrollable
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      0,
                      3,
                      _trayScrollable ? 8 : 0,
                      3,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: tileHeight,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 5,
                    ),
                    itemCount: groups.length,
                    itemBuilder: (_, index) => _pile(groups[index]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _actions() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _action(
          Icons.undo_rounded,
          'Undo',
          game.board.isEmpty || game.solving
              ? null
              : () {
                  game.undo();
                  if (game.selected != null) _reveal(game.selected!.id);
                  _sound('lift');
                },
        ),
        _action(
          Icons.rotate_right_rounded,
          'Rotate',
          game.selected == null || game.solving ? null : game.rotate,
        ),
        _action(
          Icons.lightbulb_outline_rounded,
          'Hint · 10 coins',
          game.solving ? null : _hint,
          cost: 10,
        ),
        _action(
          Icons.auto_awesome,
          'Solve · 50 coins',
          game.solving ? null : _solve,
          cost: 50,
        ),
      ],
    ),
  );
  Widget _action(
    IconData icon,
    String label,
    VoidCallback? action, {
    int? cost,
  }) => Tooltip(
    message: label,
    child: Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          onPressed: action,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: .85),
            disabledBackgroundColor: Colors.white.withValues(alpha: .85),
            shape: const CircleBorder(),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 22),
              if (cost != null)
                Positioned(
                  right: -10,
                  bottom: -7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xffffefb4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$cost',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _pile(Pile pile) {
    final active = pile.available.any((p) => p.id == game.selected?.id),
        p = active
            ? pile.available.firstWhere((p) => p.id == game.selected!.id)
            : (pile.available.isNotEmpty
                  ? pile.available.first
                  : pile.members.first),
        enabled = pile.available.isNotEmpty && !game.solving;
    final card = Semantics(
      label:
          '${p.name} pile, ${pile.available.length} remaining, ${p.w.toStringAsFixed(1)} by ${p.h.toStringAsFixed(1)}',
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : .35,
        child: Material(
          color: active ? const Color(0xffebe2ff) : const Color(0xfff6f3fc),
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: enabled
                ? () {
                    game.select(p);
                    _sound('tap');
                  }
                : null,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: active ? purple : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 5,
                    right: 5,
                    top: 2,
                    bottom: 22,
                    child: CustomPaint(
                      painter: _wooden
                          ? WoodenPiecePainter(active ? game.selected! : p)
                          : PiecePainter(p, dimension: game.dimension),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '${pile.available.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 3,
                    child: Column(
                      children: [
                        Text(
                          p.name == 'Parallelogram' ? 'Slanted quad' : p.name,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_dim(p.w)} × ${_dim(p.h)}',
                          style: TextStyle(
                            fontSize: 7,
                            color: ink.withValues(alpha: .55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!enabled) return card;
    final makeDraggable = _trayScrollable
        ? LongPressDraggable<Piece>.new
        : Draggable<Piece>.new;
    return makeDraggable(
      data: p,
      dragAnchorStrategy: (_, _, _) => const Offset(28, 28),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: _wooden
                ? WoodenPiecePainter(active ? game.selected! : p)
                : PiecePainter(
                    active ? game.selected! : p,
                    dimension: game.dimension,
                  ),
          ),
        ),
      ),
      onDragStarted: () => game.select(p),
      onDragUpdate: (d) => _aimGlobal(d.globalPosition),
      onDragEnd: (d) {
        final box = _jarKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null &&
            _jarBounds(box.size, game.puzzle)
                .inflate(12)
                .contains(box.globalToLocal(d.offset + const Offset(28, 28)))) {
          _drop();
        }
      },
      child: card,
    );
  }

  String _dim(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  Future<void> _advanceAfterCompletion() async {
    if (_advancing || !game.complete || game.rewardBusy || game.walletBusy) {
      return;
    }
    if (game.atFreePlayLimit) {
      if (widget.purchases != null) {
        await _themes();
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('You filled all 10 free jars!'),
          content: const Text(
            'Play your favorites again, or preview the picture packs. Any paid pack will unlock all 100 levels. Purchases are coming soon.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep playing'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _advancing = true);
    await betweenGames();
    if (!mounted) return;
    final due = _adsAllowed && game.recordCompletedTransition();
    if (due) {
      game.rewardBusy = true;
      game.refresh();
      await widget.store?.flush();
      try {
        await _interstitials.showIfReady();
      } finally {
        game.rewardBusy = false;
      }
    }
    if (!mounted) return;
    if (game.startNewJourney()) {
      _scrollTrayTo(0);
    } else {
      final next = game.puzzle.preview != null
          ? game.levels[(game.unlocked - 1).clamp(0, game.levels.length - 1)]
          : game.levels[game.puzzle.number % game.levels.length];
      _load(next);
    }
    setState(() => _advancing = false);
    if (_adsAllowed) unawaited(_interstitials.preload());
  }

  Widget _completionBar() => Padding(
    key: const ValueKey('completion-bar'),
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'A perfect little fit.  +${game.lastReward} coins',
          style: const TextStyle(fontWeight: FontWeight.bold, color: ink),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _advancing ? null : _advanceAfterCompletion,
          child: Text(
            game.atFreePlayLimit
                ? (widget.purchases != null
                      ? 'Unlock all 100 levels'
                      : 'Free journey complete')
                : game.puzzle.preview == null &&
                      game.puzzle.number == game.levels.length
                ? 'Start a fresh journey >>'
                : 'Next >>',
          ),
        ),
        TextButton(
          onPressed: _advancing ? null : () => _load(game.puzzle),
          child: const Text('Play this jar again'),
        ),
      ],
    ),
  );
}
