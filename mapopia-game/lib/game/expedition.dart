import '../web_bridge.dart';
import 'dart:convert';
import '../services/atlas_commerce.dart';
import '../services/atlas_ads.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../geo/data/geo_pack.dart';
import '../geo/domain/geo_piece.dart';
import '../geo/domain/geo_fit.dart';
import '../geo/domain/geo_region.dart';

enum Trail { shapes, names, capitals, clues }

extension TrailText on Trail {
  String get label => ['Shapes', 'Countries', 'Capitals', 'Clues'][index];
  String get description => [
    'Match each colorful shape to its place on the map.',
    'Read the place name. Find its home on the map.',
    'Know the capital? Place it in the right country or state.',
    'Solve a little geography riddle, then find its place.',
  ][index];
  String card(GeoPiece p) => switch (this) {
    Trail.shapes || Trail.names => p.name,
    Trail.capitals => p.capital.isEmpty ? p.name : p.capital,
    Trail.clues =>
      p.expertClue.isEmpty
          ? (p.capital.isEmpty ? p.name : 'Capital: ${p.capital}')
          : p.expertClue,
  };
}

class AtlasStore extends ChangeNotifier {
  AtlasStore(this.prefs, {AtlasBilling? billing}) : _billing = billing {
    try {
      records = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('records') ?? '{}') as Map,
      );
    } catch (_) {
      records = {};
    }
  }
  final AtlasBilling? _billing;
  late final commerce = AtlasCommerce(prefs, billing: _billing);
  late final ads = AtlasAds(commerce);
  final SharedPreferences prefs;
  late Map<String, dynamic> records;
  bool get sound => prefs.getBool('sound') ?? true;
  bool get haptics => prefs.getBool('haptics') ?? true;
  bool get nightMap => prefs.getBool('nightMap') ?? true;
  bool get reducedMotion => prefs.getBool('reducedMotion') ?? false;
  static String _saveKey(GeoRegion region, String? dailyKey) =>
      dailyKey == null ? region.name : '${region.name}:daily:$dailyKey';

  // Preserve the original single save until the first write of the new catalog.
  // Insertion order identifies the most recently visited expedition.
  Map<String, String> get _savedRounds {
    final catalog = prefs.getString('rounds');
    if (catalog != null) {
      try {
        return Map<String, String>.from(jsonDecode(catalog) as Map);
      } catch (_) {
        return {};
      }
    }
    final legacy = prefs.getString('round');
    if (legacy == null) return {};
    try {
      final j = jsonDecode(legacy) as Map<String, dynamic>;
      final region = GeoRegion.values.byName(j['region'] as String);
      return {_saveKey(region, j['daily'] as String?): legacy};
    } catch (_) {
      return {};
    }
  }

  String? get savedRound {
    final rounds = _savedRounds;
    return rounds.isEmpty ? null : rounds.values.last;
  }

  String? savedRoundFor(GeoRegion region, {String? dailyKey}) =>
      _savedRounds[_saveKey(region, dailyKey)];

  Future<void> _writeRounds(Map<String, String> rounds) async {
    if (!await prefs.setString('rounds', jsonEncode(rounds))) {
      throw StateError('Unable to save expeditions');
    }
    notifyListeners();
  }

  int get completedMaps => records.keys
      .where((k) => !k.startsWith('daily:'))
      .map((k) => k.split(':').first)
      .toSet()
      .length;
  int get expeditions => records.entries
      .where((e) => !e.key.startsWith('daily:'))
      .map((e) => e.value)
      .fold(0, (sum, r) => sum + ((r as Map)['plays'] as int? ?? 1));
  int stars(GeoRegion region) => records.entries
      .where((e) => e.key.startsWith('${region.name}:'))
      .fold(0, (v, e) => max(v, (e.value as Map)['stars'] as int? ?? 0));
  Future<void> setting(String key, bool value) async {
    await prefs.setBool(key, value);
    notifyListeners();
  }

  Future<void> save(Expedition round) async {
    await commerce.recordTrialProgress(
      round.pack.region,
      Set.of(round.placed),
      round.pack.pieces.length,
    );
    final rounds = _savedRounds;
    final key = _saveKey(round.pack.region, round.dailyKey);
    rounds.remove(key);
    rounds[key] = jsonEncode(round.toJson());
    await _writeRounds(rounds);
  }

  Future<void> clearRound({String? saved}) async {
    final rounds = _savedRounds;
    if (saved != null) {
      rounds.removeWhere((key, value) => value == saved);
    } else if (rounds.isNotEmpty) {
      rounds.remove(rounds.keys.last);
    }
    await _writeRounds(rounds);
  }

  Future<void> finish(Expedition r) async {
    final saved = savedRoundFor(r.pack.region, dailyKey: r.dailyKey);
    if (saved != null) await clearRound(saved: saved);
    if (!r.complete) return;
    final key = '${r.pack.region.name}:${r.trail.name}:${r.timed}';
    final old = records[key] as Map?;
    records[key] = {
      'score': max(r.score, old?['score'] as int? ?? 0),
      'stars': max(r.stars, old?['stars'] as int? ?? 0),
      'plays': (old?['plays'] as int? ?? 0) + 1,
      'region': r.pack.region.name,
      'date': DateTime.now().toIso8601String(),
    };
    if (r.dailyKey != null) {
      records['daily:${r.dailyKey}'] = {
        'region': r.pack.region.name,
        'completed': true,
      };
    }
    await prefs.setString('records', jsonEncode(records));
    notifyListeners();
  }
}

/// Independent round state. Rendering and feedback never decide whether a
/// placement is correct. The same normalized geometry handles taps and drops.
class Expedition extends ChangeNotifier {
  Expedition({
    required this.pack,
    this.trail = Trail.shapes,
    this.timed = false,
    this.dailyKey,
    int? seed,
  }) {
    order = List.of(pack.pieces)..shuffle(Random(seed));
    selectedId = order.first.id;
    _watch.start();
  }
  final GeoPack pack;
  final Trail trail;
  final bool timed;
  final String? dailyKey;
  late List<GeoPiece> order;
  final Set<String> placed = {};
  late String selectedId;
  int mistakes = 0;
  int hints = 0;
  int _savedSeconds = 0;
  double? mapZoom;
  Offset? mapCenter;
  double trayOffset = 0;
  final Stopwatch _watch = Stopwatch();
  bool paused = false;
  bool ended = false;
  GeoPiece? lastPlaced;
  String? hintId;
  String message = 'A whole world, one piece at a time.';
  int get seconds => _savedSeconds + _watch.elapsed.inSeconds;
  int get allowance => pack.pieces.length * 20 + 30;
  int get remainingSeconds => max(0, allowance - seconds);
  bool get complete => placed.length == pack.pieces.length;
  bool get expired => timed && remainingSeconds == 0;
  GeoPiece get selected => pack.pieces.firstWhere((p) => p.id == selectedId);
  List<GeoPiece> get remaining =>
      order.where((p) => !placed.contains(p.id)).toList();
  double get progress => placed.length / pack.pieces.length;
  int get accuracy => placed.isEmpty && mistakes == 0
      ? 100
      : (100 * placed.length / max(1, placed.length + mistakes)).round();
  int get stars => accuracy >= 90 && hints == 0
      ? 3
      : accuracy >= 70 && hints <= 3
      ? 2
      : 1;
  int get score => max(
    0,
    placed.length * 100 +
        (complete ? 500 : 0) -
        mistakes * 20 -
        hints * 35 +
        (complete && timed ? remainingSeconds * 2 : 0),
  );
  bool get interactive => !paused && !ended && !complete && !expired;
  void select(String id) {
    if (!interactive ||
        placed.contains(id) ||
        !pack.pieces.any((p) => p.id == id)) {
      return;
    }
    selectedId = id;
    hintId = null;
    notifyListeners();
  }

  bool accepts(GeoPiece piece, Offset point) {
    final hit = pack.pieceAt(point);
    final path = GeoFit(
      scale: 1,
      origin: Offset.zero,
      viewBox: pack.viewBox,
    ).screenPath(piece);
    if (path.contains(point)) {
      // Shared borders remain forgiving; an enclosed region owns its interior.
      if (hit != null &&
          hit.id != piece.id &&
          piece.bounds.contains(hit.bounds.topLeft) &&
          piece.bounds.contains(hit.bounds.bottomRight)) {
        return false;
      }
      return true;
    }
    if (hit != null) return false;
    // Coastline grace applies only outside all regions.
    for (final ring in piece.rings) {
      for (var i = 0; i < ring.length; i++) {
        final a = ring[i], b = ring[(i + 1) % ring.length];
        final ab = b - a;
        final length = ab.distanceSquared;
        final t = length == 0
            ? 0.0
            : (((point - a).dx * ab.dx + (point - a).dy * ab.dy) / length)
                  .clamp(0.0, 1.0);
        if ((point - (a + ab * t)).distance <= 8) return true;
      }
    }
    return false;
  }

  bool place(Offset point) {
    if (!interactive) return false;
    reportGameAction(false);
    if (!accepts(selected, point)) {
      mistakes++;
      message = 'Almost. Try another spot — you’ve got this.';
      notifyListeners();
      return false;
    }
    final piece = selected;
    placed.add(piece.id);
    lastPlaced = piece;
    hintId = null;
    message =
        '${piece.name} · ${piece.capital.isEmpty ? 'Beautifully placed' : piece.capital}';
    if (complete) {
      reportGameAction(true);
      ended = true;
      _watch.stop();
    } else {
      selectedId = remaining.first.id;
    }
    notifyListeners();
    return true;
  }

  void hint() {
    if (!interactive) return;
    if (hintId == selectedId) return;
    hints++;
    hintId = selectedId;
    message = 'Follow the golden glow. Hint: −35 points.';
    notifyListeners();
  }

  void clearHint() {
    hintId = null;
    notifyListeners();
  }

  void pause() {
    if (ended) return;
    paused = true;
    _watch.stop();
    notifyListeners();
  }

  void resume() {
    if (ended) return;
    paused = false;
    _watch.start();
    notifyListeners();
  }

  void tick() {
    if (!paused && !ended) {
      if (expired) {
        ended = true;
        _watch.stop();
      }
      notifyListeners();
    }
  }

  Map<String, dynamic> toJson() => {
    'region': pack.region.name,
    'trail': trail.name,
    'timed': timed,
    'daily': dailyKey,
    'order': order.map((p) => p.id).toList(),
    'placed': placed.toList(),
    'selected': selectedId,
    'mistakes': mistakes,
    'hints': hints,
    'seconds': seconds,
    'lastPlaced': lastPlaced?.id,
    if (mapZoom != null && mapCenter != null)
      'view': {
        'zoom': mapZoom,
        'center': [mapCenter!.dx, mapCenter!.dy],
        'tray': trayOffset,
      },
  };
  static Future<Expedition> restore(String raw) async {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final pack = await GeoPack.load(
      GeoRegion.values.byName(j['region'] as String),
    );
    final r = Expedition(
      pack: pack,
      trail: Trail.values.byName(j['trail'] as String),
      timed: j['timed'] as bool,
      dailyKey: j['daily'] as String?,
    );
    r.order = (j['order'] as List)
        .map((id) => pack.pieces.firstWhere((p) => p.id == id))
        .toList();
    r.placed.addAll((j['placed'] as List).cast<String>());
    r.selectedId = j['selected'] as String;
    r.mistakes = j['mistakes'] as int;
    r.hints = j['hints'] as int;
    r._savedSeconds = j['seconds'] as int;
    final lastId = j['lastPlaced'];
    for (final piece in pack.pieces) {
      if (piece.id == lastId && r.placed.contains(piece.id)) {
        r.lastPlaced = piece;
        r.message =
            '${piece.name} · ${piece.capital.isEmpty ? 'Beautifully placed' : piece.capital}';
        break;
      }
    }
    // Older saves have no view. Invalid view data must not discard gameplay.
    final view = j['view'];
    if (view is Map) {
      final zoom = view['zoom'];
      final center = view['center'];
      final tray = view['tray'];
      if (zoom is num &&
          zoom.isFinite &&
          zoom >= 1 &&
          zoom <= 12 &&
          center is List &&
          center.length == 2 &&
          center.every((v) => v is num && v.isFinite)) {
        r.mapZoom = zoom.toDouble();
        r.mapCenter = Offset(
          (center[0] as num).toDouble(),
          (center[1] as num).toDouble(),
        );
        if (tray is num && tray.isFinite && tray >= 0) {
          r.trayOffset = tray.toDouble();
        }
      }
    }
    r._watch.reset();
    r.pause();
    return r;
  }

  @override
  void dispose() {
    _watch.stop();
    super.dispose();
  }
}

String dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
int dailySeed(DateTime date) => date.year * 10000 + date.month * 100 + date.day;
GeoRegion dailyRegion(DateTime date) =>
    [
      GeoRegion.southAmerica,
      GeoRegion.australia,
      GeoRegion.uk,
      GeoRegion.germany,
      GeoRegion.europe,
      GeoRegion.canada,
      GeoRegion.oceania,
    ][DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).difference(DateTime.utc(2026)).inDays %
        7];
