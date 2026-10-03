import '../web_bridge.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/expedition.dart';
import '../geo/domain/geo_piece.dart';
import '../geo/domain/geo_region.dart';
import 'cartography.dart';
import 'expedition_setup.dart';
import 'theme.dart';
import 'map_banner.dart';
import 'full_atlas.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.round, required this.store});
  final Expedition round;
  final AtlasStore store;
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Expedition get r => widget.round;
  String get _invalidAttemptsLabel =>
      r.mistakes == 1 ? 'invalid attempt' : 'invalid attempts';
  MapPalette get _palette => MapPalette(night: widget.store.nightMap);
  late final AnimationController _pulse;
  late final Timer _ticker;
  Timer? _hintTimer;
  final _transform = TransformationController();
  final _boardKey = GlobalKey();
  final _tray = ScrollController();
  final _audio = AudioPlayer();
  bool _result = false, _finishing = false, _leaving = false;
  bool _savingExit = false, _restarting = false, _modePickerOpen = false;
  String? _saveError;
  bool _hintBusy = false;
  bool _trialPromptOpen = false;
  bool get _trialBlocked => !widget.store.commerce.canPlace(
    r.pack.region,
    r.placed.length,
    r.pack.pieces.length,
  );

  Future<void> _showTrialPrompt() async {
    if (_trialPromptOpen || !_trialBlocked || r.ended) return;
    _trialPromptOpen = true;
    r.pause();
    _hintTimer?.cancel();
    r.clearHint();
    await _save();
    if (!mounted) return;
    await showFullAtlas(
      context,
      widget.store.commerce,
      trialMap: r.pack.name,
      region: r.pack.region,
    );
    if (!mounted) return;
    _trialPromptOpen = false;
    if (!_trialBlocked) r.resume();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
      value: 1,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      r.tick();
      if (r.ended) {
        _finish();
      } else if (r.seconds % 5 == 0) {
        _save();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _restoreView();
      _save();
      if (_trialBlocked) _showTrialPrompt();
    });
  }

  void _captureView() {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final center = _transform.toScene(box.size.center(Offset.zero));
      final point = MapPainter(
        pack: r.pack,
      ).actualFit(box.size).toViewBox(center);
      r.mapZoom = _transform.value.getMaxScaleOnAxis();
      r.mapCenter = Offset(
        point.dx / r.pack.viewBox.width,
        point.dy / r.pack.viewBox.height,
      );
    }
    if (_tray.hasClients) r.trayOffset = _tray.offset;
  }

  void _restoreView() {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final savedCenter = r.mapCenter;
    final zoom = r.mapZoom;
    if (box != null && box.hasSize && savedCenter != null && zoom != null) {
      final point = Offset(
        savedCenter.dx * r.pack.viewBox.width,
        savedCenter.dy * r.pack.viewBox.height,
      );
      final scene = MapPainter(
        pack: r.pack,
      ).actualFit(box.size).toScreen(point);
      final center = box.size.center(Offset.zero);
      _transform.value = Matrix4.identity()
        ..translateByDouble(
          center.dx - scene.dx * zoom,
          center.dy - scene.dy * zoom,
          0,
          1,
        )
        ..scaleByDouble(zoom, zoom, 1, 1);
    }
    if (_tray.hasClients) {
      _tray.jumpTo(r.trayOffset.clamp(0.0, _tray.position.maxScrollExtent));
    }
  }

  Future<bool> _save() async {
    if (r.ended || _leaving || _restarting) return true;
    _captureView();
    try {
      await widget.store.save(r);
      if (mounted && _saveError != null) setState(() => _saveError = null);
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError = 'Progress could not be saved on this device.',
        );
      }
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !r.ended) {
      r.pause();
      _save();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.cancel();
    _hintTimer?.cancel();
    _pulse.dispose();
    _transform.dispose();
    _tray.dispose();
    _audio.dispose();
    r.dispose();
    super.dispose();
  }

  Future<void> _sound(bool correct) async {
    if (widget.store.haptics) {
      if (correct) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    if (widget.store.sound) {
      try {
        await _audio.play(
          AssetSource(correct ? 'sounds/correct.mp3' : 'sounds/wrong.mp3'),
          volume: .35,
        );
      } catch (_) {
        /* Sound is optional; placement remains available. */
      }
    }
  }

  void _placeLocal(Offset local, Size size) {
    if (_trialBlocked) {
      _showTrialPrompt();
      return;
    }
    if (!r.interactive) return;
    final painter = MapPainter(pack: r.pack);
    final point = painter.actualFit(size).toViewBox(local);
    final ok = r.place(point);
    _sound(ok);
    if (ok) {
      _hintTimer?.cancel();
      if (!MediaQuery.of(context).disableAnimations) {
        _pulse.forward(from: 0);
      } else {
        _pulse.value = 1;
      }
      if (_tray.hasClients) _tray.jumpTo(0);
      _save();
      if (r.complete) {
        _finish();
      } else if (_trialBlocked) {
        _showTrialPrompt();
      }
    }
  }

  // A tap inspects a placed piece before attempting a new placement. Drops
  // deliberately keep using _placeLocal so a wrong drop is still a mistake.
  void _tapMap(Offset local, Size size, {bool inspectOnly = false}) {
    if (r.paused) return;
    final fit = MapPainter(pack: r.pack).actualFit(size);
    if (!inspectOnly) {
      final zoom = _transform.value.getMaxScaleOnAxis();
      final small =
          MapPainter(pack: r.pack, zoom: zoom).smallPieces(size).toList()..sort(
            (a, b) => (fit.toScreen(a.target) - local).distanceSquared
                .compareTo((fit.toScreen(b.target) - local).distanceSquared),
          );
      if (small.isNotEmpty &&
          (fit.toScreen(small.first.target) - local).distance * zoom <= 22) {
        if (r.placed.contains(small.first.id)) {
          _showPieceInfo(small.first);
        } else {
          _focusPiece(small.first, size);
        }
        return;
      }
    }
    final piece = r.pack.pieceAt(fit.toViewBox(local));
    if (piece != null && r.placed.contains(piece.id)) {
      _showPieceInfo(piece);
      return;
    }
    if (!inspectOnly) _placeLocal(local, size);
  }

  void _focusPiece(GeoPiece piece, Size size) {
    final fit = MapPainter(pack: r.pack).actualFit(size);
    final extent = piece.bounds.longestSide * fit.scale;
    final zoom = (56 / extent).clamp(1.0, 12.0);
    final target = fit.toScreen(piece.target);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        size.width / 2 - target.dx * zoom,
        size.height / 2 - target.dy * zoom,
        0,
        1,
      )
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  void _showPieceInfo(GeoPiece piece) {
    if (r.paused || !r.placed.contains(piece.id)) return;
    showDialog<void>(
      context: context,
      barrierColor: ocean.withValues(alpha: .55),
      builder: (dialogContext) => Dialog(
        backgroundColor: paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Eyebrow('A little discovery')),
                    IconButton(
                      tooltip: 'Close place information',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded, color: muted),
                    ),
                  ],
                ),
                Center(
                  child: SizedBox(
                    width: 140,
                    height: 120,
                    child: CustomPaint(painter: PiecePainter(piece)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  piece.name,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                    color: ink,
                  ),
                ),
                if (piece.capital.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Eyebrow('Capital'),
                  const SizedBox(height: 5),
                  Text(
                    piece.capital,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: teal,
                    ),
                  ),
                ],
                if (piece.fact.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    piece.fact,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: ink,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _drop(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(global);
    if ((Offset.zero & box.size).contains(local)) _placeLocal(local, box.size);
  }

  Future<void> _finish() async {
    if (_finishing || _result) return;
    _finishing = true;
    try {
      await widget.store.finish(r);
    } catch (_) {
      _saveError = 'Your result could not be saved on this device.';
    }
    if (mounted) {
      setState(() => _result = true);
      if (widget.store.sound && r.complete) {
        try {
          await _audio.play(AssetSource('sounds/success.mp3'), volume: .35);
        } catch (_) {}
      }
    }
  }

  Future<void> _hint() async {
    if (_trialBlocked) {
      _showTrialPrompt();
      return;
    }
    if (_hintBusy || !r.interactive) return;
    if (!widget.store.commerce.adFree(r.pack.region) && r.hints > 0) {
      _hintBusy = true;
      r.pause();
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('A little help finding home'),
          content: const Text(
            'Watch an ad to reveal the right spot for this piece. Each hint costs 35 points. Full Atlas includes hints without ads.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'skip'),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'atlas'),
              child: const Text('Full Atlas'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'watch'),
              child: const Text('Watch ad · 1 hint'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      var earned = false;
      if (choice == 'atlas') {
        earned = await showFullAtlas(
          context,
          widget.store.commerce,
          region: r.pack.region,
        );
      } else if (choice == 'watch') {
        earned = await widget.store.ads.hintReward();
        if (!earned && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No hint earned. The ad may be unavailable or was closed early. Please try again later.',
              ),
            ),
          );
        }
      }
      if (!mounted) return;
      _hintBusy = false;
      r.resume();
      if (!earned) return;
    }
    _revealHint();
  }

  void _revealHint() {
    r.hint();
    _save();
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) r.clearHint();
    });
  }

  Future<void> _leave() async {
    if (_leaving || _savingExit || _restarting) return;
    setState(() => _savingExit = true);
    if (!r.ended && !await _save()) {
      if (mounted) setState(() => _savingExit = false);
      return;
    }
    if (r.complete) await betweenGames();
    _leaving = true;
    if (mounted) {
      setState(() {});
      Navigator.pop(context);
    }
  }

  Future<void> _changeMode() async {
    if (_modePickerOpen ||
        _restarting ||
        _savingExit ||
        r.ended ||
        r.dailyKey != null) {
      return;
    }
    _modePickerOpen = true;
    final choice = await showModalBottomSheet<({Trail trail, bool timed})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => ExpeditionSetup(
        region: r.pack.region,
        initialTrail: r.trail,
        initialTimed: r.timed,
        restarting: true,
        onStart: (trail, timed) =>
            Navigator.pop(sheetContext, (trail: trail, timed: timed)),
      ),
    );
    _modePickerOpen = false;
    if (!mounted || choice == null) return;
    setState(() => _restarting = true);
    final next = Expedition(
      pack: r.pack,
      trail: choice.trail,
      timed: choice.timed,
    );
    try {
      // Commit only after the player explicitly starts the new expedition.
      // Suppress the old round's autosave while replacing its save and route.
      await widget.store.save(next);
    } catch (_) {
      next.dispose();
      if (mounted) {
        setState(() {
          _restarting = false;
          _saveError =
              'The new expedition could not be saved. Please try again.';
        });
      }
      return;
    }
    if (!mounted) {
      next.dispose();
      return;
    }
    _leaving = true;
    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlayScreen(round: next, store: widget.store),
      ),
    );
  }

  void _pause() {
    if (!r.ended) {
      r.pause();
      _save();
    }
  }

  void _zoom(double factor) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final current = _transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, 12.0);
    if (next == 1) {
      _transform.value = Matrix4.identity();
      return;
    }
    final center = Offset(box.size.width / 2, box.size.height / 2);
    final scene = _transform.toScene(center);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        center.dx - scene.dx * next,
        center.dy - scene.dy * next,
        0,
        1,
      )
      ..scaleByDouble(next, next, 1, 1);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        if (r.ended) {
          _leave();
        } else {
          _pause();
        }
      }
    },
    child: Scaffold(
      backgroundColor: paper,
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([
          r,
          widget.store.ads,
          widget.store.commerce,
        ]),
        builder: (context, _) =>
            widget.store.ads.eligible &&
                !widget.store.commerce.adFree(r.pack.region) &&
                !r.paused &&
                !r.ended &&
                MediaQuery.sizeOf(context).height >= 650
            ? MapBanner(ads: widget.store.ads)
            : const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            r,
            widget.store,
            widget.store.commerce,
          ]),
          builder: (context, _) => Stack(
            children: [
              if (!_result)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      children: [
                        _header(),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final wide = c.maxWidth > 720;
                              if (wide) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    22,
                                    4,
                                    22,
                                    20,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: _board()),
                                      const SizedBox(width: 20),
                                      SizedBox(
                                        width: 260,
                                        child: Column(
                                          children: [
                                            _status(),
                                            Expanded(
                                              child: _pieces(vertical: true),
                                            ),
                                            _tools(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final compact = c.maxHeight < 570;
                              return Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: _board(),
                                    ),
                                  ),
                                  _status(compact: compact),
                                  SizedBox(
                                    height: compact ? 116 : 148,
                                    child: _pieces(),
                                  ),
                                  _tools(compact: compact),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_result) _resultView(),
              if (r.paused && !_result)
                Positioned.fill(
                  child: ColoredBox(
                    color: paper,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 350),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.nights_stay_outlined,
                                size: 62,
                                color: teal,
                              ),
                              const SizedBox(height: 24),
                              const Eyebrow('A moment to wander'),
                              const SizedBox(height: 12),
                              Text(
                                _trialBlocked
                                    ? 'More of the world awaits.'
                                    : 'Your world can wait.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 13),
                              Text(
                                _trialBlocked
                                    ? 'Your free map trial on this device is complete. Unlock Full Atlas to continue, or return to free Australia.'
                                    : 'Take a breath. Your pieces and your clock\nare right where you left them.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted,
                                  height: 1.6,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _restarting
                                      ? null
                                      : _trialBlocked
                                      ? _showTrialPrompt
                                      : r.resume,
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(
                                    _trialBlocked
                                        ? 'Unlock Full Atlas'
                                        : 'Back to exploring',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (r.dailyKey == null && !_trialBlocked)
                                TextButton.icon(
                                  onPressed: _restarting || _savingExit
                                      ? null
                                      : _changeMode,
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    size: 20,
                                  ),
                                  label: Text(
                                    _restarting
                                        ? 'Starting…'
                                        : 'Change play mode',
                                  ),
                                ),
                              if (_saveError != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    _saveError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              TextButton(
                                onPressed: _savingExit || _restarting
                                    ? null
                                    : _leave,
                                child: Text(
                                  _savingExit
                                      ? 'Saving…'
                                      : 'Save & return to atlas',
                                ),
                              ),
                            ],
                          ),
                        ),
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
  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 9, 14, 13),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Pause expedition',
              onPressed: _pause,
              icon: const Icon(Icons.arrow_back_rounded, color: ink, size: 23),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(
                    r.dailyKey == null ? 'Your expedition' : 'Daily discovery',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    geoRegionLabel(r.pack.region),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDDF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    '${r.score}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: teal,
                    ),
                  ),
                  const Eyebrow('Points'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Pause expedition',
              onPressed: _pause,
              icon: const Icon(Icons.pause_rounded, color: ink),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text(
                '${r.placed.length} of ${r.pack.pieces.length} placed',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: muted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: r.progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE1E6DB),
                    color: teal,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                r.timed ? Icons.timer_outlined : Icons.spa_outlined,
                size: 14,
                color: r.timed && r.remainingSeconds < 30
                    ? Colors.deepOrange
                    : muted,
              ),
              const SizedBox(width: 5),
              Text(
                r.timed ? _time(r.remainingSeconds) : 'No rush',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: r.timed && r.remainingSeconds < 30
                      ? Colors.deepOrange
                      : muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _board() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: _palette.gradient,
      border: Border.all(color: _palette.border),
      boxShadow: [
        BoxShadow(
          color: ocean.withValues(alpha: .18),
          offset: const Offset(0, 6),
          blurRadius: 15,
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, c) {
              final size = Size(c.maxWidth, c.maxHeight);
              final paint = AnimatedBuilder(
                animation: Listenable.merge([_pulse, _transform]),
                builder: (context, _) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      painter: MapPainter(
                        pack: r.pack,
                        zoom: _transform.value.getMaxScaleOnAxis(),
                        showSmallMarkers: true,
                        dark: widget.store.nightMap,
                        placed: Set.of(r.placed),
                        hintId: r.hintId,
                        lastId: r.lastPlaced?.id,
                        pulse: _pulse.value,
                        onPlaced: _showPieceInfo,
                        onTarget: (piece) {
                          final fit = MapPainter(pack: r.pack).actualFit(size);
                          _tapMap(fit.toScreen(piece.target), size);
                        },
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              );
              return InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 12,
                boundaryMargin: const EdgeInsets.all(80),
                child: SizedBox(
                  width: c.maxWidth,
                  height: c.maxHeight,
                  child: GestureDetector(
                    key: _boardKey,
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _tapMap(d.localPosition, size),
                    child: paint,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 15,
          top: 14,
          child: IgnorePointer(
            child: Row(
              children: [
                Icon(Icons.public, size: 13, color: _palette.caption),
                const SizedBox(width: 6),
                Text(
                  'THE ${geoRegionShortLabel(r.pack.region).toUpperCase()} COLLECTION',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: _palette.caption,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 10,
          bottom: 9,
          child: Container(
            decoration: BoxDecoration(
              color: _palette.controls,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mapButton(Icons.add_rounded, 'Zoom in', () => _zoom(1.5)),
                _mapButton(
                  Icons.remove_rounded,
                  'Zoom out',
                  () => _zoom(1 / 1.5),
                ),
                _mapButton(
                  Icons.center_focus_strong_outlined,
                  'Reset map view',
                  () => _transform.value = Matrix4.identity(),
                ),
                Container(width: 1, height: 20, color: _palette.border),
                _lightingButton(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _lightingButton() => _mapButton(
    widget.store.nightMap ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
    widget.store.nightMap ? 'Switch to daytime map' : 'Switch to nighttime map',
    () async {
      try {
        await widget.store.setting('nightMap', !widget.store.nightMap);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your map lighting preference could not be saved.'),
            ),
          );
        }
      }
    },
  );

  Widget _mapButton(IconData icon, String tooltip, VoidCallback callback) =>
      SizedBox(
        width: 43,
        height: 43,
        child: IconButton(
          tooltip: tooltip,
          onPressed: callback,
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: _palette.icon, size: 19),
        ),
      );
  Widget _status({bool compact = false}) => Padding(
    padding: EdgeInsets.fromLTRB(22, compact ? 10 : 15, 22, compact ? 6 : 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          r.lastPlaced == null
              ? Icons.touch_app_outlined
              : Icons.check_circle_rounded,
          color: teal,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 4),
                Text(
                  r.lastPlaced?.fact ??
                      'Tap a piece, then its home. Or hold and drag.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: muted,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
  Widget _pieces({bool vertical = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
        child: Row(
          children: [
            const Eyebrow('Your pieces'),
            const Spacer(),
            Text(
              '${r.remaining.length} to discover',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.separated(
          controller: _tray,
          scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: vertical ? 4 : 18,
            vertical: 3,
          ),
          itemCount: r.remaining.length,
          separatorBuilder: (_, _) => const SizedBox(width: 9, height: 9),
          itemBuilder: (context, i) =>
              _pieceCard(r.remaining[i], vertical: vertical),
        ),
      ),
    ],
  );
  Widget _pieceCard(GeoPiece piece, {required bool vertical}) {
    final selected = r.selectedId == piece.id;
    final shape = r.trail == Trail.shapes;
    final label = r.trail.card(piece);
    final card = AnimatedContainer(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 160),
      width: vertical ? null : (r.trail == Trail.clues ? 190 : 111),
      height: vertical ? 132 : null,
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE5ECDD) : const Color(0xFFFFFDF6),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: selected ? teal : line,
          width: selected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: .05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: shape
                ? CustomPaint(
                    painter: PiecePainter(piece, selected: selected),
                    child: const SizedBox.expand(),
                  )
                : Center(
                    child: r.trail == Trail.clues
                        ? Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          )
                        : Icon(
                            r.trail == Trail.capitals
                                ? Icons.location_city_rounded
                                : Icons.place_outlined,
                            color: pieceColor(piece.id),
                            size: 34,
                          ),
                  ),
          ),
          if (r.trail != Trail.clues)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: selected ? teal : ink,
                ),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      label:
          '${selected ? 'Selected. ' : ''}$label. Tap to select, then tap its place on the map.',
      button: true,
      selected: selected,
      child: LongPressDraggable<String>(
        data: piece.id,
        maxSimultaneousDrags: 1,
        delay: const Duration(milliseconds: 220),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Transform.translate(
          offset: const Offset(-47, -100),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: paper.withValues(alpha: .97),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: shape
                  ? CustomPaint(painter: PiecePainter(piece, selected: true))
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: .3, child: card),
        onDragStarted: () => r.select(piece.id),
        onDragEnd: (d) => _drop(d.offset),
        child: GestureDetector(onTap: () => r.select(piece.id), child: card),
      ),
    );
  }

  Widget _tools({bool compact = false}) => Padding(
    padding: EdgeInsets.fromLTRB(21, compact ? 5 : 10, 21, compact ? 5 : 12),
    child: Column(
      children: [
        if (_saveError != null)
          Text(
            _saveError!,
            style: const TextStyle(color: Colors.deepOrange, fontSize: 10),
          ),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: r.hintId == r.selectedId ? null : _hint,
                style: TextButton.styleFrom(
                  foregroundColor: teal,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.explore_outlined, size: 20),
                label: const Text(
                  'A little nudge',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Text(
              '${r.mistakes} $_invalidAttemptsLabel',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _resultView() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(26, 25, 26, 28),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AtlasMark(size: 28),
              const SizedBox(width: 8),
              const Text(
                'mapopia',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Eyebrow(
              r.complete
                  ? 'A new stamp in your story'
                  : 'Every journey teaches us something',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            r.complete ? 'Beautifully explored.' : 'Time for a fresh start.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: ink,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '${geoRegionLabel(r.pack.region)} · ${r.placed.length} places discovered',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 25),
          Container(
            height: 255,
            decoration: BoxDecoration(
              gradient: _palette.gradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: ocean.withValues(alpha: .16),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (d) =>
                            _tapMap(d.localPosition, size, inspectOnly: true),
                        child: CustomPaint(
                          painter: MapPainter(
                            pack: r.pack,
                            dark: widget.store.nightMap,
                            placed: Set.of(r.placed),
                            onPlaced: _showPieceInfo,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _palette.controls,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _palette.border),
                        ),
                        child: _lightingButton(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 21),
          if (r.complete)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < r.stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < r.stars ? const Color(0xFFC49B4C) : line,
                    size: i == 1 ? 47 : 37,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDDF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat('${r.score}', 'POINTS'),
                _stat('${r.mistakes}', _invalidAttemptsLabel.toUpperCase()),
                _stat(_time(r.seconds), 'EXPLORED'),
              ],
            ),
          ),
          const SizedBox(height: 21),
          Text(
            r.complete
                ? 'The world feels a little more familiar now.\nWhere will your curiosity take you next?'
                : 'You found ${r.placed.length} places. Try relaxed play for\na little more time to get to know this map.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 12, height: 1.7),
          ),
          const SizedBox(height: 25),
          if (_saveError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _saveError!,
                style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
              ),
            ),
          FilledButton.icon(
            onPressed: _leave,
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Back to the atlas'),
          ),
        ],
      ),
    ),
  );
  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          color: teal,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          letterSpacing: 1.2,
          color: muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
  String _time(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
