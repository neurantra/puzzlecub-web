import '../web_bridge.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'geometry.dart';
import 'picture_theme.dart';

class Economy {
  static const starting = 60,
      hint = 10,
      solve = 50,
      dimension = 120,
      firstClear = 25,
      replay = 5,
      adCoins = 30;
}

class GameSession extends ChangeNotifier {
  final bool usesPaidPacks;
  Set<String> _paidAccess = {};
  bool get adsRemoved => _paidAccess.isNotEmpty;
  bool get freePlayLimited => usesPaidPacks && _paidAccess.isEmpty;
  bool hasPaidPack(String id) =>
      _paidAccess.contains('all') || _paidAccess.contains(id);
  bool ownsPicture(String id) {
    final theme = PictureTheme.find(id);
    if (theme == null) return false;
    return usesPaidPacks
        ? id == freePictureId || hasPaidPack(theme.packId)
        : ownedPictureThemes.contains(id) &&
              ownedPicturePacks.contains(theme.packId);
  }

  void updatePaidAccess(Set<String> access) {
    _paidAccess = access.intersection({
      'animals',
      'vehicles',
      'landscapes',
      'all',
    });
    if (activePictureTheme != null && !ownsPicture(activePictureTheme!)) {
      activePictureTheme = null;
    }
    if (!canPlay(puzzle)) {
      campaign = 0;
      solving = false;
      puzzle =
          levels[(math.min(unlocked, accessibleLevelCount) - 1).clamp(
            0,
            levels.length - 1,
          )];
      board = [];
      selected = null;
      hintedPlacement = null;
      complete = false;
      lastReward = 0;
    }
    // A player who finished the free campaign can continue immediately.
    if (!freePlayLimited &&
        levels.length > freeLevelLimit &&
        completed.contains(levels[freeLevelLimit - 1].key) &&
        unlocked <= freeLevelLimit) {
      unlocked = freeLevelLimit + 1;
    }
    notifyListeners();
  }

  static const freeLevelLimit = 10;
  static const freePictureId = 'woodland-fox';
  bool canPlay(Puzzle value) =>
      !freePlayLimited ||
      (value.preview == null &&
          value.number >= 1 &&
          value.number <= freeLevelLimit &&
          campaign == 0);
  bool canUsePicture(String? id) => id == null || ownsPicture(id);
  int get accessibleLevelCount =>
      freePlayLimited ? math.min(freeLevelLimit, levels.length) : levels.length;
  bool get atFreePlayLimit =>
      freePlayLimited && puzzle.number >= accessibleLevelCount;

  final Set<String> ownedPictureThemes = {};
  final Set<String> ownedPicturePacks = {};
  String? activePictureTheme;
  bool showPictureGuide = false;
  int hintCredits = 0;
  int interstitialProgress = 0;
  Piece? hintedPlacement;
  bool get pictureClues => PictureTheme.find(activePictureTheme) != null;
  PictureTheme? get pictureTheme => PictureTheme.find(activePictureTheme);
  final List<Puzzle> originalLevels, previews, legacyLevels;
  final List<List<Puzzle>> replayCampaigns;
  int campaign = 0, journey = 1;
  List<Puzzle> get levels =>
      campaign == 0 ? originalLevels : replayCampaigns[campaign - 1];
  late Puzzle puzzle;
  List<Piece> board = [];
  Piece? selected;
  double column = 0;
  int coins = Economy.starting, unlocked = 1, lastReward = 0;
  Set<String> completed = {};
  // Coins and transfer intents share one durable snapshot.
  List<Map<String, dynamic>> vaultTransfers = [];
  bool walletBusy = false, rewardBusy = false;
  bool motion = true,
      sound = true,
      haptics = true,
      dimensionUnlocked = false,
      dimension = false,
      complete = false,
      solving = false;
  String message = 'A little space. A perfect fit.';
  int page = 0;
  GameSession(
    this.originalLevels,
    this.previews, {
    bool freePlayLimited = true,
    this.legacyLevels = const [],
    this.replayCampaigns = const [],
  }) : usesPaidPacks = freePlayLimited {
    puzzle = levels.first;
    if (usesPaidPacks) {
      ownedPicturePacks.add('animals');
      ownedPictureThemes.add(freePictureId);
    }
  }
  bool startNewJourney({math.Random? random}) {
    if (freePlayLimited ||
        solving ||
        !complete ||
        puzzle.preview != null ||
        puzzle.number != levels.length ||
        replayCampaigns.isEmpty) {
      return false;
    }
    final choices = List.generate(replayCampaigns.length + 1, (i) => i)
      ..remove(campaign);
    campaign = choices[(random ?? math.Random()).nextInt(choices.length)];
    journey++;
    load(levels.first);
    message = 'A fresh journey. Familiar shapes, new possibilities.';
    notifyListeners();
    return true;
  }

  List<Pile> get groups => piles(puzzle, board);

  /// Count completed campaign transitions, never level-picker visits.
  bool recordCompletedTransition() {
    if (adsRemoved || !complete || puzzle.preview != null) return false;
    interstitialProgress = (interstitialProgress + 1) % 4;
    notifyListeners();
    return interstitialProgress == 0;
  }

  bool unlockPicturePack(String id) {
    if (usesPaidPacks) return id == 'animals' || hasPaidPack(id);
    final pack = PicturePack.find(id);
    if (pack == null || walletBusy || rewardBusy) return false;
    if (ownedPicturePacks.contains(id)) return true;
    if (coins < pack.coins) return false;
    coins -= pack.coins;
    ownedPicturePacks.add(id);
    notifyListeners();
    return true;
  }

  bool unlockPictureTheme(String id, {bool rewarded = false}) {
    if (usesPaidPacks) return selectPictureTheme(id);
    final theme = PictureTheme.find(id);
    if (theme == null ||
        !ownedPicturePacks.contains(theme.packId) ||
        walletBusy ||
        rewardBusy) {
      return false;
    }
    if (!ownedPictureThemes.contains(id)) {
      if (!rewarded && coins < theme.coins) return false;
      if (!rewarded) coins -= theme.coins;
      ownedPictureThemes.add(id);
    }
    activePictureTheme = id;
    notifyListeners();
    return true;
  }

  bool selectPictureTheme(String? id) {
    if (walletBusy || rewardBusy || !canUsePicture(id)) return false;
    if (id != null && !ownsPicture(id)) {
      return false;
    }
    activePictureTheme = id;
    notifyListeners();
    return true;
  }

  void earnHintCredit() {
    hintCredits++;
    notifyListeners();
  }

  double get fill =>
      board.fold<double>(0, (s, p) => s + p.area) / (puzzle.w * puzzle.h);
  Piece? get ghost => selected == null
      ? null
      : landing(board, selected!, column, puzzle.w, puzzle.h);

  /// All reachable positions in the selected orientation, using the same
  /// half-cell grid and gravity calculation as actual drops.
  List<Piece> get availableLandings {
    final piece = selected;
    if (piece == null || complete || solving) return [];
    return [
      for (double x = 0; x <= puzzle.w - piece.w + epsilon; x += .5)
        ?landing(board, piece, x, puzzle.w, puzzle.h),
    ];
  }

  void load(Puzzle next) {
    if (solving || rewardBusy || !canPlay(next)) return;
    puzzle = next;
    board = [];
    selected = null;
    hintedPlacement = null;
    column = 0;
    page = 0;
    complete = false;
    lastReward = 0;
    message = 'Good things come in pieces.';
    notifyListeners();
  }

  void select(Piece p) {
    if (complete || solving || rewardBusy) return;
    if (selected?.id != p.id) {
      selected = p;
      hintedPlacement = null;
    }
    column = column.clamp(0, (puzzle.w - selected!.w).clamp(0, puzzle.w));
    message = 'Aim, then drop. Every piece belongs.';
    notifyListeners();
  }

  void aim(double x, {double grab = .5}) {
    if (selected == null || solving || complete || rewardBusy) return;
    column = aimColumn(x, selected!.w, puzzle.w, grab: grab);
    notifyListeners();
  }

  void aimAt(Offset point) {
    if (selected == null || solving || complete || rewardBusy) return;
    column = tapColumn(board, selected!, point, puzzle.w, puzzle.h);
    notifyListeners();
  }

  void rotate() {
    if (selected == null || solving || complete || rewardBusy) return;
    hintedPlacement = null;
    selected = selected!.rotated();
    column = column.clamp(0, (puzzle.w - selected!.w).clamp(0, puzzle.w));
    notifyListeners();
  }

  bool drop() {
    if (walletBusy || rewardBusy || solving || complete || selected == null) {
      return false;
    }
    final p = ghost;
    if (p == null) {
      message = 'No room here. Try another spot or rotate.';
      notifyListeners();
      return false;
    }
    board.add(p);
    selected = null;
    hintedPlacement = null;
    message = 'A little closer. Pick your next piece.';
    checkComplete();
    reportGameAction(complete);
    notifyListeners();
    return true;
  }

  bool remove(Piece p) {
    if (solving || complete || rewardBusy) return false;
    if (!canLift(board, p)) {
      message = 'A piece is in the way. Clear the top first.';
      notifyListeners();
      return false;
    }
    board.removeWhere((q) => q.id == p.id);
    selected = null;
    hintedPlacement = null;
    message = 'A little room to try again.';
    notifyListeners();
    return true;
  }

  bool movePlacedPiece(int id, Offset target) {
    if (walletBusy || rewardBusy || solving || complete) return false;
    final index = board.indexWhere((p) => p.id == id);
    if (index < 0) return false;
    final piece = board[index];
    if (!canLift(board, piece)) return false;
    final moved = slidePiece(board, piece, target, puzzle.w, puzzle.h);
    if ((Offset(moved.x, moved.y) - Offset(piece.x, piece.y)).distance <
        epsilon) {
      return false;
    }
    board = List.of(board)..[index] = moved;
    selected = null;
    hintedPlacement = null;
    message = 'A little slide. A new possibility.';
    checkComplete();
    reportGameAction(complete);
    notifyListeners();
    return true;
  }

  void undo() {
    if (solving || complete || rewardBusy || board.isEmpty) return;
    hintedPlacement = null;
    final p = board.removeLast();
    selected = p;
    column = p.x;
    message = 'One step back. Try a different fit.';
    notifyListeners();
  }

  void checkComplete() {
    if (complete || !solved(board, puzzle)) return;
    complete = true;
    lastReward = completed.add(puzzle.key)
        ? Economy.firstClear
        : Economy.replay;
    coins += lastReward;
    if (puzzle.preview == null && puzzle.number < accessibleLevelCount) {
      unlocked = unlocked > puzzle.number ? unlocked : puzzle.number + 1;
    }
    message = 'A perfect little fit.';
  }

  bool buyHint({bool useCredit = false}) {
    if (walletBusy ||
        rewardBusy ||
        solving ||
        complete ||
        (useCredit ? hintCredits < 1 : coins < Economy.hint)) {
      return false;
    }
    final p = nextHint(puzzle, board);
    if (p == null) {
      message = 'Undo or restart to make room for a hint. No coins spent.';
      notifyListeners();
      return false;
    }
    if (useCredit) {
      hintCredits--;
    } else {
      coins -= Economy.hint;
    }
    hintedPlacement = p;
    selected = p;
    column = p.x;
    message = 'Try this little piece right here.';
    notifyListeners();
    return true;
  }

  bool beginSolve() {
    if (walletBusy ||
        rewardBusy ||
        solving ||
        complete ||
        coins < Economy.solve) {
      return false;
    }
    coins -= Economy.solve;
    board = [];
    selected = null;
    hintedPlacement = null;
    solving = true;
    message = 'Finding a home for every piece…';
    notifyListeners();
    return true;
  }

  void solveStep(Piece p) {
    if (!solving) return;
    board.add(p);
    if (board.length == puzzle.pieces.length) {
      solving = false;
      checkComplete();
    }
    notifyListeners();
  }

  bool unlockDimension() {
    if (dimensionUnlocked) {
      dimension = !dimension;
      notifyListeners();
      return true;
    }
    if (walletBusy || coins < Economy.dimension) return false;
    coins -= Economy.dimension;
    dimensionUnlocked = true;
    dimension = true;
    notifyListeners();
    return true;
  }

  void earnedAd({bool forDimension = false}) {
    if (forDimension) {
      dimensionUnlocked = true;
      dimension = true;
    } else {
      coins += Economy.adCoins;
    }
    notifyListeners();
  }

  void toggleSound(bool value) {
    sound = value;
    notifyListeners();
  }

  void toggleHaptics(bool value) {
    haptics = value;
    notifyListeners();
  }

  void refresh() => notifyListeners();
  String encode() => jsonEncode({
    'version': 1,
    'interstitialProgress': interstitialProgress,
    'campaign': campaign,
    'journey': journey,
    'coins': coins,
    'ownedPicturePacks': ownedPicturePacks.toList(),
    'ownedPictureThemes': ownedPictureThemes.toList(),
    'activePictureTheme': activePictureTheme,
    'showPictureGuide': showPictureGuide,
    'hintCredits': hintCredits,
    'vaultTransfers': vaultTransfers,
    'unlocked': unlocked,
    'completed': completed.toList(),
    'sound': sound,
    'motion': motion,
    'haptics': haptics,
    'dimensionUnlocked': dimensionUnlocked,
    'dimension': dimension,
    'puzzle': puzzle.key,
    'puzzleRevision': puzzle.revision,
    'board': board.map((p) => p.toJson()).toList(),
    'complete': complete,
    'lastReward': lastReward,
    'solving': solving,
    'selected': selected?.toJson(),
    'column': column,
  });
  void restore(String? data) {
    if (data == null) return;
    try {
      final j = jsonDecode(data) as Map<String, dynamic>;
      if (j['version'] != 1) return;
      interstitialProgress = ((j['interstitialProgress'] as num?)?.toInt() ?? 0)
          .clamp(0, 3);
      campaign = ((j['campaign'] as int?) ?? 0).clamp(
        0,
        replayCampaigns.length,
      );
      journey = ((j['journey'] as int?) ?? 1).clamp(1, 1000000);
      coins = ((j['coins'] as num?)?.toInt() ?? Economy.starting).clamp(
        0,
        10000000,
      );
      ownedPicturePacks.clear();
      ownedPicturePacks.addAll(
        (j['ownedPicturePacks'] as List? ?? []).whereType<String>().where(
          (id) => PicturePack.find(id) != null,
        ),
      );
      ownedPictureThemes.clear();
      ownedPictureThemes.addAll(
        (j['ownedPictureThemes'] as List? ?? []).whereType<String>().where(
          (id) =>
              PictureTheme.find(id) != null &&
              ownedPicturePacks.contains(PictureTheme.find(id)!.packId),
        ),
      );
      if (usesPaidPacks) {
        ownedPicturePacks.add('animals');
        ownedPictureThemes.add(freePictureId);
      }
      final active = j['activePictureTheme'];
      activePictureTheme = active is String && canUsePicture(active)
          ? active
          : null;
      showPictureGuide = j['showPictureGuide'] == true;
      hintCredits = ((j['hintCredits'] as num?)?.toInt() ?? 0).clamp(
        0,
        1000000,
      );
      vaultTransfers = (j['vaultTransfers'] as List? ?? [])
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
      unlocked = ((j['unlocked'] as int?) ?? 1).clamp(1, levels.length);
      completed = (j['completed'] as List? ?? []).whereType<String>().toSet();
      if (!freePlayLimited &&
          levels.length > freeLevelLimit &&
          completed.contains(levels[freeLevelLimit - 1].key) &&
          unlocked <= freeLevelLimit) {
        unlocked = freeLevelLimit + 1;
      }
      sound = j['sound'] != false;
      motion = j['motion'] != false;
      haptics = j['haptics'] != false;
      dimensionUnlocked = j['dimensionUnlocked'] == true;
      dimension = dimensionUnlocked && j['dimension'] == true;
      final matches = [
        ...levels,
        ...previews,
      ].where((p) => p.key == j['puzzle']);
      if (matches.isNotEmpty) puzzle = matches.first;
      if (!canPlay(puzzle)) {
        // Preserve wallet/earned ownership/progress, but never resume paid
        // content (including a saved auto-solve) in the free setup build.
        campaign = 0;
        puzzle =
            levels[(math.min(unlocked, accessibleLevelCount) - 1).clamp(
              0,
              levels.length - 1,
            )];
        board = [];
        selected = null;
        hintedPlacement = null;
        complete = false;
        solving = false;
        lastReward = 0;
        return;
      }
      final savedRevision = (j['puzzleRevision'] as int?) ?? 1;
      if (savedRevision != puzzle.revision) {
        final inProgress =
            (j['board'] is List && (j['board'] as List).isNotEmpty) ||
            j['selected'] is Map ||
            j['solving'] == true;
        final legacy = legacyLevels.where(
          (p) => p.key == puzzle.key && p.revision == savedRevision,
        );
        if (inProgress && legacy.isNotEmpty) {
          puzzle = legacy.first;
        } else {
          // Wallet, unlocks and settings above are retained even if a removed
          // layout cannot be resumed. Never mix pieces from two revisions.
          j['board'] = [];
          j['selected'] = null;
          j['solving'] = false;
        }
      }

      final loaded = (j['board'] as List? ?? [])
          .map((p) => Piece.fromJson(Map<String, dynamic>.from(p)))
          .toList();
      bool valid = loaded.map((p) => p.id).toSet().length == loaded.length;
      for (final p in loaded) {
        final originals = puzzle.pieces.where((q) => q.id == p.id);
        if (originals.isEmpty) {
          valid = false;
          break;
        }
        var q = originals.first;
        bool matches = false;
        for (int i = 0; i < 4; i++) {
          if (q.pileKey == p.pileKey) matches = true;
          q = q.rotated();
        }
        if (!matches ||
            p.x < 0 ||
            p.y < 0 ||
            p.x + p.w > puzzle.w + epsilon ||
            p.y + p.h > puzzle.h + epsilon) {
          valid = false;
        }
        for (final other in loaded.where((q) => q.id != p.id)) {
          if (overlaps(p, other)) valid = false;
        }
      }
      if (valid) board = loaded;
      complete = solved(board, puzzle);
      lastReward = (j['lastReward'] as int?) ?? 0;
      // A paid solve interrupted by app suspension resumes at launch, without charging again.
      solving = valid && !complete && j['solving'] == true;
      if (!complete && !solving && j['selected'] is Map) {
        final saved = Piece.fromJson(Map<String, dynamic>.from(j['selected']));
        final original = puzzle.pieces.where((p) => p.id == saved.id);
        if (original.isNotEmpty && !board.any((p) => p.id == saved.id)) {
          var shape = original.first;
          for (int i = 0; i < 4; i++) {
            if (shape.pileKey == saved.pileKey) {
              selected = saved;
              column = ((j['column'] as num?)?.toDouble() ?? 0).clamp(
                0,
                (puzzle.w - saved.w).clamp(0, puzzle.w),
              );
              break;
            }
            shape = shape.rotated();
          }
        }
      }
    } catch (_) {
      message = 'Your jar is ready for a fresh start.';
    }
  }
}
