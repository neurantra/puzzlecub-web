import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_info.dart';
import '../data/difficulty_preference.dart';
import '../data/stats_service.dart';
import '../engine/difficulty.dart';
import '../engine/pieces.dart';
import 'board_screen.dart';
import 'difficulty_pills.dart';
import 'online/online_lobby_screen.dart';
import 'theme.dart';
import 'court_backdrop.dart';

/// Top-of-screen choice in [CardPickScreen] when the online-multiplayer
/// feature flag is on. Gated entirely on [kOnlineMultiplayerEnabled];
/// the toggle UI is hidden and `vsAi` is the only reachable mode while
/// the flag is `false`.
enum _PickMode { vsAi, online }

/// Pre-game ceremony: two royal cards fly in from above, the player taps
/// one to reveal Side.white or Side.black, then we navigate to the
/// [BoardScreen] with the chosen [BoardScreen.humanSide].
///
/// Which card hides which side is randomized on every entry so the choice
/// is genuinely 50/50.
class CardPickScreen extends StatefulWidget {
  const CardPickScreen({super.key});

  @override
  State<CardPickScreen> createState() => _CardPickScreenState();
}

class _CardPickScreenState extends State<CardPickScreen>
    with TickerProviderStateMixin {
  /// Fly-in controller — drives both cards' entry from above.
  late final AnimationController _entryController;

  /// Shuffle controller — runs right after the fly-in. The two cards
  /// visibly swap places a few times to convey that which card hides
  /// which side is being randomized.
  late final AnimationController _shuffleController;

  /// Flip controller — driven only after the user taps a card. Lazily
  /// constructed so we don't burn ticks on an idle animation.
  AnimationController? _flipController;

  /// Per-card mapping of which Side is on the face. Shuffled on init.
  late final List<Side> _cardSides;

  /// 0 or 1 once the player has tapped; null while waiting.
  int? _tappedIndex;
  bool _reducedMotion = false;

  /// Pre-game choice: vs the AI (cards) or online (host/join room).
  /// Always starts in [_PickMode.vsAi]; the toggle that flips it is
  /// only rendered when [kOnlineMultiplayerEnabled] is true.
  _PickMode _mode = _PickMode.vsAi;

  @override
  void initState() {
    super.initState();
    final sides = [Side.white, Side.black]..shuffle(math.Random());
    _cardSides = sides;
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    // Fly the cards in, then shuffle them.
    _entryController.forward().whenComplete(() {
      if (mounted) _shuffleController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) {
      _entryController.stop();
      _shuffleController.stop();
      _entryController.value = 1;
      _shuffleController.value = 1;
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shuffleController.dispose();
    _flipController?.dispose();
    super.dispose();
  }

  void _onCardTap(int index) {
    if (_tappedIndex != null) return; // already picked
    if (_entryController.value < 1.0) return; // wait for entry to settle
    if (_shuffleController.value < 1.0) return; // wait for the shuffle
    setState(() => _tappedIndex = index);
    final flip = AnimationController(
      vsync: this,
      duration: _reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 600),
    );
    _flipController = flip;
    flip.forward().whenComplete(() async {
      // Brief pause so the revealed face is readable before we navigate.
      await Future<void>.delayed(
        _reducedMotion ? Duration.zero : const Duration(milliseconds: 700),
      );
      if (!mounted) return;
      final humanSide = _cardSides[index];
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => BoardScreen(humanSide: humanSide)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaturangTheme.deepMaroon,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Choose your side'),
      ),
      body: CourtBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/decorations/app_mark.png',
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Chaturang',
                      style: TextStyle(
                        fontFamily: 'RoyalSans',
                        color: ChaturangTheme.saffronLight,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _mode == _PickMode.vsAi
                      ? 'Pick a card to reveal your side'
                      : 'Play with a friend online',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'RoyalSans',
                    color: ChaturangTheme.secondaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (kOnlineMultiplayerEnabled) ...[
                  const SizedBox(height: 18),
                  _ModeToggle(
                    mode: _mode,
                    onChanged: _tappedIndex == null
                        ? (m) => setState(() => _mode = m)
                        : null,
                  ),
                ],
                if (_mode == _PickMode.vsAi)
                  _LevelChoice(enabled: _tappedIndex == null),
                const Spacer(flex: 3),
                Expanded(
                  flex: 8,
                  child: _mode == _PickMode.vsAi
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = ((constraints.maxWidth - 24) / 2)
                                .clamp(120.0, 170.0);
                            final cardHeight = cardWidth * 1.45;
                            final gap = cardWidth * 0.15;
                            final swapSpan = cardWidth + gap;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AnimatedCard(
                                  index: 0,
                                  width: cardWidth,
                                  height: cardHeight,
                                  entry: _entryController,
                                  shuffle: _shuffleController,
                                  swapSpan: swapSpan,
                                  flip: _flipController,
                                  isTapped: _tappedIndex == 0,
                                  isDimmed:
                                      _tappedIndex != null && _tappedIndex != 0,
                                  faceSide: _cardSides[0],
                                  onTap: () => _onCardTap(0),
                                ),
                                SizedBox(width: gap),
                                _AnimatedCard(
                                  index: 1,
                                  width: cardWidth,
                                  height: cardHeight,
                                  entry: _entryController,
                                  shuffle: _shuffleController,
                                  swapSpan: swapSpan,
                                  flip: _flipController,
                                  isTapped: _tappedIndex == 1,
                                  isDimmed:
                                      _tappedIndex != null && _tappedIndex != 1,
                                  faceSide: _cardSides[1],
                                  onTap: () => _onCardTap(1),
                                ),
                              ],
                            );
                          },
                        )
                      : const _OnlineActions(),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The AI level, offered before the first card is turned.
///
/// Only rendered once there is a choice to make — a player who has not yet
/// unlocked Medium sees nothing here, since a single pill would only ask a
/// question with one answer. Until then the level lives in Settings alone,
/// where the lock hints explain how to earn the next one.
///
/// This is why the choice is here and not only in Settings: when the AI
/// draws White it moves at once, so a level chosen after the board appears
/// is a level chosen after the first move.
class _LevelChoice extends StatelessWidget {
  const _LevelChoice({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StatsService.instance,
      builder: (context, _) {
        final stats = StatsService.instance.stats;
        final unlocked = Difficulty.values
            .where(
              (d) => d.isUnlockedBy(
                easyWins: stats.easyWins,
                mediumWins: stats.mediumWins,
              ),
            )
            .length;
        if (unlocked < 2) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: DifficultyPills(
              listenable: DifficultyPreference.instance,
              enabled: enabled,
            ),
          ),
        );
      },
    );
  }
}

/// One card: handles the fly-in transform, the shuffle swap, and the
/// 3D flip on tap.
///
/// Entry: starts above the viewport, drops to resting position with a
/// slight rotational sway and an ease-out-back overshoot. Cards stagger by
/// index so the second feels like it follows the first.
///
/// Shuffle: after entry, the two cards trade places [_shuffleSwaps] times
/// — card 0 arcs up, card 1 arcs down, so they pass without colliding.
/// The swap count is even, so each card finishes in its starting slot.
///
/// Flip: rotates on the Y-axis 0..π. Below π/2 the back is showing; past
/// π/2 the face is drawn (un-flipped so its content reads correctly).
class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({
    required this.index,
    required this.width,
    required this.height,
    required this.entry,
    required this.shuffle,
    required this.swapSpan,
    required this.flip,
    required this.isTapped,
    required this.isDimmed,
    required this.faceSide,
    required this.onTap,
  });

  final int index;
  final double width;
  final double height;
  final AnimationController entry;
  final AnimationController shuffle;
  final double swapSpan;
  final AnimationController? flip;
  final bool isTapped;
  final bool isDimmed;
  final Side faceSide;
  final VoidCallback onTap;

  /// Number of position-exchanges during the shuffle. Even so each card
  /// lands back in its original slot.
  static const int _shuffleSwaps = 4;

  /// Horizontal offset for the shuffle. Card 0 toggles 0 → swapSpan → 0
  /// → … across the swaps; card 1 is the mirror.
  double _shuffleDx(double t) {
    if (t <= 0) return 0;
    final scaled = t * _shuffleSwaps;
    final seg = scaled.floor().clamp(0, _shuffleSwaps - 1);
    final localT = Curves.easeInOut.transform(scaled - seg);
    final start = seg.isEven ? 0.0 : swapSpan;
    final end = seg.isEven ? swapSpan : 0.0;
    final dx = start + (end - start) * localT;
    return index == 0 ? dx : -dx;
  }

  /// Vertical arc for the shuffle so the two cards pass cleanly: card 0
  /// arcs up, card 1 arcs down, each peaking mid-swap.
  double _shuffleDy(double t) {
    if (t <= 0) return 0;
    final scaled = t * _shuffleSwaps;
    final seg = scaled.floor().clamp(0, _shuffleSwaps - 1);
    final localT = scaled - seg;
    final arc = math.sin(localT * math.pi) * (height * 0.22);
    return index == 0 ? -arc : arc;
  }

  @override
  Widget build(BuildContext context) {
    // Stagger: card 0 runs from 0%-75% of entry; card 1 runs from 25%-100%.
    final entryAnim = CurvedAnimation(
      parent: entry,
      curve: Interval(
        index == 0 ? 0.0 : 0.25,
        index == 0 ? 0.75 : 1.0,
        curve: Curves.easeOutBack,
      ),
    );
    return Listenable.merge([entry, shuffle, ?flip]).let(
      (listenable) => AnimatedBuilder(
        animation: listenable,
        builder: (context, _) {
          final entryT = entryAnim.value; // 0..1
          final flipT = isTapped ? (flip?.value ?? 0.0) : 0.0;
          final shuffleT = shuffle.value;
          final entryDy = (1 - entryT) * -height * 2.5; // start above screen
          final dx = _shuffleDx(shuffleT);
          final dy = entryDy + _shuffleDy(shuffleT);
          // Sway: tilt while flying, settle to upright. Card 0 tilts
          // slightly left, card 1 slightly right for visual variety.
          final swayDeg = (1 - entryT) * (index == 0 ? -8.0 : 8.0);
          final dimAlpha = isDimmed ? 0.35 : 1.0;
          return Opacity(
            opacity: dimAlpha,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: swayDeg * math.pi / 180,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateY(flipT * math.pi),
                  child: flipT < 0.5
                      ? _CardFace(
                          width: width,
                          height: height,
                          onTap: isTapped ? null : onTap,
                          child: const _CardBack(),
                        )
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child: _CardFace(
                            width: width,
                            height: height,
                            onTap: null,
                            child: _CardFront(side: faceSide),
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shared chrome around a card's content: rounded corners, soft drop
/// shadow, gold border. Whether the inside is "back" or "face" is the
/// caller's call.
class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.width,
    required this.height,
    required this.onTap,
    required this.child,
  });

  final double width;
  final double height;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Semantics(
        label: 'Choose royal card',
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ChaturangTheme.saffronLight, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Royal-themed card back: saffron radial gradient, inner ornate frame,
/// faint king silhouette as a watermark, "Chaturang" wordmark below.
class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [ChaturangTheme.saffron, ChaturangTheme.saffronDark],
          radius: 0.85,
          center: Alignment.center,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: ChaturangTheme.parchment.withValues(alpha: 0.65),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Watermark king silhouette behind the wordmark.
              Padding(
                padding: const EdgeInsets.all(18),
                child: Opacity(
                  opacity: 0.28,
                  child: SvgPicture.asset(
                    'assets/pieces/king.svg',
                    colorFilter: const ColorFilter.mode(
                      ChaturangTheme.parchment,
                      BlendMode.srcIn,
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Corner fleur ornaments.
              const Positioned(top: 6, left: 6, child: _CornerFleur()),
              const Positioned(
                top: 6,
                right: 6,
                child: _CornerFleur(flipH: true),
              ),
              const Positioned(
                bottom: 6,
                left: 6,
                child: _CornerFleur(flipV: true),
              ),
              const Positioned(
                bottom: 6,
                right: 6,
                child: _CornerFleur(flipH: true, flipV: true),
              ),
              // Centered wordmark.
              Text(
                'Chaturang',
                style: TextStyle(
                  fontFamily: 'RoyalSans',
                  color: ChaturangTheme.parchment,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  shadows: const [
                    Shadow(
                      color: Color(0x88000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small corner motif. Uses the star icon as a stand-in fleur — looks
/// passably royal at this size. Replace with a custom SVG once the
/// proper decoration art lands.
class _CornerFleur extends StatelessWidget {
  const _CornerFleur({this.flipH = false, this.flipV = false});

  final bool flipH;
  final bool flipV;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scaleByDouble(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0, 1.0, 1.0),
      child: Icon(
        Icons.auto_awesome,
        size: 14,
        color: ChaturangTheme.parchment.withValues(alpha: 0.80),
      ),
    );
  }
}

/// Revealed face: parchment background, king SVG in the chosen side's
/// color, and a label below ("WHITE" or "BLACK").
class _CardFront extends StatelessWidget {
  const _CardFront({required this.side});

  final Side side;

  @override
  Widget build(BuildContext context) {
    final pieceColor = side == Side.white
        ? ChaturangTheme.saffron
        : ChaturangTheme.terracotta;
    final label = side == Side.white ? 'WHITE' : 'BLACK';
    return Container(
      decoration: const BoxDecoration(color: ChaturangTheme.parchment),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SvgPicture.asset(
                'assets/pieces/king.svg',
                colorFilter: ColorFilter.mode(pieceColor, BlendMode.srcIn),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'RoyalSans',
                color: ChaturangTheme.charcoal,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T it) f) => f(this);
}

/// Themed pill toggle for the AI / Online mode choice. Two segments
/// inside a single rounded saffron-bordered pill; the selected segment
/// fills with saffron. Disabled (greyed) when [onChanged] is null —
/// e.g. once the player has tapped a card and we're mid-transition.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _PickMode mode;
  final ValueChanged<_PickMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: ChaturangTheme.saffronLight.withValues(alpha: 0.7),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _segment('vs AI', _PickMode.vsAi),
            _segment('Online', _PickMode.online),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, _PickMode value) {
    final selected = mode == value;
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ChaturangTheme.saffronLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'RoyalSans',
            color: selected
                ? ChaturangTheme.deepMaroon
                : ChaturangTheme.parchment,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Single "Play online" button shown when the user toggles to Online
/// mode. Opens the unified [OnlineLobbyScreen] which lets the player
/// host AND wait for joiners in the same place — no upfront commitment
/// to host-vs-join.
class _OnlineActions extends StatelessWidget {
  const _OnlineActions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: _OnlineButton(
          icon: Icons.public,
          label: 'Play online',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OnlineLobbyScreen()),
          ),
        ),
      ),
    );
  }
}

class _OnlineButton extends StatelessWidget {
  const _OnlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: ChaturangTheme.saffronLight),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'RoyalSans',
          color: ChaturangTheme.parchment,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: const BorderSide(color: ChaturangTheme.saffronLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
