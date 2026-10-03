import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../game/expedition.dart';
import '../geo/data/geo_pack.dart';
import '../geo/domain/geo_region.dart';
import 'cartography.dart';
import 'destinations.dart';
import 'expedition_setup.dart';
import 'play.dart';
import 'theme.dart';
import 'full_atlas.dart';
import '../services/atlas_commerce.dart';
import '../services/family_games.dart';
import 'package:url_launcher/url_launcher.dart';

class AtlasHome extends StatefulWidget {
  const AtlasHome({super.key, required this.store, this.today});
  final AtlasStore store;
  final DateTime? today;
  @override
  State<AtlasHome> createState() => _AtlasHomeState();
}

class _AtlasHomeState extends State<AtlasHome> {
  int _tab = 0, _filter = 0;
  bool _opening = false;
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<bool> _access(GeoRegion region) async =>
      widget.store.commerce.canOpen(region) ||
      await showFullAtlas(context, widget.store.commerce, region: region);

  Future<void> _openLink(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The link could not be opened. Please try again.'),
        ),
      );
    }
  }

  Future<void> _start(GeoRegion region, {bool daily = false}) async {
    if (_opening) return;
    if (!await _access(region) || !mounted) return;
    final saved = widget.store.savedRoundFor(
      region,
      dailyKey: daily ? dateKey(widget.today ?? DateTime.now()) : null,
    );
    if (saved != null) {
      await _resume(saved: saved);
      return;
    }
    if (daily) {
      await _launch(region, Trail.shapes, false, daily: true);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => ExpeditionSetup(
        region: region,
        onStart: (trail, timed) {
          Navigator.pop(sheetContext);
          _launch(region, trail, timed);
        },
      ),
    );
  }

  Future<void> _launch(
    GeoRegion region,
    Trail trail,
    bool timed, {
    bool daily = false,
  }) async {
    setState(() => _opening = true);
    try {
      final pack = await GeoPack.load(region);
      if (!mounted) return;
      final now = (widget.today ?? DateTime.now());
      final r = Expedition(
        pack: pack,
        trail: trail,
        timed: timed,
        dailyKey: daily ? dateKey(now) : null,
        seed: daily ? dailySeed(now) : null,
      );
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PlayScreen(round: r, store: widget.store),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This map couldn’t open. Please try again.'),
          ),
        );
      }
    }
    if (mounted) setState(() => _opening = false);
  }

  Future<void> _resume({String? saved}) async {
    final raw = saved ?? widget.store.savedRound;
    if (_opening || raw == null) return;
    setState(() => _opening = true);
    try {
      final round = await Expedition.restore(raw);
      if (!mounted) {
        round.dispose();
        return;
      }
      if (!await _access(round.pack.region) || !mounted) {
        round.dispose();
        if (mounted) setState(() => _opening = false);
        return;
      }
      round.resume();
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PlayScreen(round: round, store: widget.store),
        ),
      );
    } catch (_) {
      await widget.store.clearRound(saved: raw);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'That expedition could not be restored. Your journal is safe.',
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _opening = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.store,
      widget.store.commerce,
      widget.store.ads,
    ]),
    builder: (context, _) => Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1020),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                  child: Row(
                    children: [
                      const AtlasMark(size: 38),
                      const SizedBox(width: 10),
                      const Text(
                        'mapopia',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          color: ink,
                        ),
                      ),
                      const Spacer(),
                      Pill(
                        '${widget.store.completedMaps} / 18',
                        icon: Icons.auto_awesome_outlined,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'How to play',
                        onPressed: _howTo,
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          color: muted,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tab == 0
                      ? _explore()
                      : _tab == 1
                      ? _journal()
                      : _settings(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFDDE9DC),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'My journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    ),
  );
  Widget _explore() {
    final regions = destinations
        .where(
          (r) =>
              (_filter == 0 ||
                  (_filter == 1
                      ? continents.contains(r)
                      : !continents.contains(r))) &&
              geoRegionLabel(
                r,
              ).toLowerCase().contains(_search.text.toLowerCase()),
        )
        .toList();
    final daily = dailyRegion(widget.today ?? DateTime.now());
    final doneDaily = widget.store.records.containsKey(
      'daily:${dateKey((widget.today ?? DateTime.now()))}',
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: 5),
              const Eyebrow('A little curiosity. A whole world.'),
              const SizedBox(height: 8),
              const Text(
                'Where to today?',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.6,
                  color: ink,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Find your flow. Piece the world together.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 23),
              if (widget.store.savedRound != null) ...[
                Material(
                  color: const Color(0xFFE6EBDD),
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    leading: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: teal,
                    ),
                    title: const Text(
                      'Your adventure is waiting',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Continue your saved map',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded, size: 20),
                    onTap: _opening ? null : _resume,
                  ),
                ),
                const SizedBox(height: 18),
              ],
              _hero(),
              const SizedBox(height: 18),
              Material(
                color: const Color(0xFFEEE8D8),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _opening ? null : () => _start(daily, daily: true),
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            doneDaily
                                ? Icons.check_rounded
                                : Icons.wb_sunny_outlined,
                            color: const Color(0xFF9C7134),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Eyebrow(
                                doneDaily
                                    ? 'Daily discovery · completed'
                                    : 'Daily discovery',
                                color: const Color(0xFF8A6838),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'A little trip to ${geoRegionLabel(daily)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: ink,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 29),
              const Row(
                children: [
                  Text(
                    'Pick your next adventure',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.65,
                      color: ink,
                    ),
                  ),
                  Spacer(),
                ],
              ),
              const SizedBox(height: 7),
              const Text(
                kIsWeb
                    ? 'All 18 maps are free. Pick a place and begin.'
                    : 'One free map trial. All of Australia is always free.',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Find a destination',
                  hintStyle: const TextStyle(fontSize: 13, color: muted),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: muted,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .65),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: List.generate(
                  3,
                  (i) => ChoiceChip(
                    label: Text(
                      ['All maps', 'Continents', 'Countries'][i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _filter == i ? Colors.white : muted,
                      ),
                    ),
                    selected: _filter == i,
                    showCheckmark: false,
                    selectedColor: teal,
                    backgroundColor: paper,
                    side: BorderSide(color: _filter == i ? teal : line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    onSelected: (_) => setState(() => _filter = i),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        if (regions.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No maps found. Try another destination.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.crossAxisExtent > 740
                  ? 4
                  : constraints.crossAxisExtent > 550
                  ? 3
                  : 2;
              return SliverGrid.builder(
                itemCount: regions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 202,
                ),
                itemBuilder: (context, i) => _regionCard(regions[i]),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_outline, size: 13, color: muted),
                SizedBox(width: 7),
                Text(
                  'Made for curious minds. Play at your own pace.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero() => Container(
    height: 308,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: ocean,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: ocean.withValues(alpha: .16),
          offset: const Offset(0, 10),
          blurRadius: 20,
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/art/atlas-island.png',
          fit: BoxFit.cover,
          alignment: const Alignment(.45, -.2),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .37, 1],
              colors: [Color(0x180B2934), Color(0x050B2934), Color(0xFF0B2934)],
            ),
          ),
        ),
        const Positioned(
          left: 18,
          top: 18,
          child: Pill(
            'THE WORLD IS YOUR PUZZLE',
            icon: Icons.auto_awesome,
            dark: true,
          ),
        ),
        Positioned(
          left: 21,
          right: 21,
          bottom: 19,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Small pieces.\nBig discoveries.',
                style: TextStyle(
                  fontSize: 27,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  color: paper,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                widget.store.commerce.fullAtlas
                    ? 'Your first stop: the colorful corners of Europe.'
                    : 'Choose one map to try. All of Australia is always free.',
                style: TextStyle(fontSize: 12, color: Color(0xFFC8D8D7)),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _opening
                      ? null
                      : () => _start(
                          widget.store.commerce.fullAtlas
                              ? GeoRegion.europe
                              : AtlasCommerce.freeMap,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEBC787),
                    foregroundColor: ink,
                    minimumSize: const Size(0, 47),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _opening
                            ? 'Opening your atlas…'
                            : widget.store.commerce.fullAtlas
                            ? 'Let’s explore Europe'
                            : 'Explore Australia · Free',
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _regionCard(GeoRegion r) => Material(
    color: Colors.white.withValues(alpha: .78),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: _opening ? null : () => _start(r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          pieceColor(r.name).withValues(alpha: .12),
                          const Color(0xFFF5F4EB),
                        ],
                      ),
                    ),
                    child: MapThumbnail(r),
                  ),
                ),
                if (!widget.store.commerce.allows(r))
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Pill(
                      widget.store.commerce.canOpen(r) ? '⅓ TRIAL' : 'UNLOCK',
                      icon: widget.store.commerce.canOpen(r)
                          ? Icons.explore_outlined
                          : Icons.lock_outline,
                    ),
                  ),
                if (!widget.store.commerce.fullAtlas &&
                    widget.store.commerce.unlocks.maps.contains(r))
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: Pill(
                      'OWNED · NO ADS',
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                if (widget.store.stars(r) > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.verified_rounded, color: teal, size: 19),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 10, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  geoRegionLabel(r),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<GeoPack>(
                        future: GeoPack.load(r),
                        builder: (context, s) => Text(
                          '${s.data?.pieces.length ?? geoRegionApproxPieces(r)} ${geoRegionPieceNounPlural(r)}',
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      ),
                    ),
                    const Icon(Icons.north_east, size: 14, color: teal),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _journal() => ListView(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
    children: [
      const Eyebrow('Little journeys. Lasting memories.'),
      const SizedBox(height: 10),
      const Text(
        'Your travel journal',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.3,
          color: ink,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        '${widget.store.completedMaps} of 18 maps explored · ${widget.store.expeditions} completed expeditions',
        style: const TextStyle(color: muted, fontSize: 12),
      ),
      const SizedBox(height: 24),
      if (widget.store.records.isEmpty)
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EBDD),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            children: [
              Icon(Icons.auto_stories_outlined, color: teal, size: 48),
              SizedBox(height: 16),
              Text(
                'Every map tells your story.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Finish an expedition to collect its stamp. Explore with fewer mistakes and hints to earn up to three stars.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: muted, height: 1.6),
              ),
            ],
          ),
        ),
      const SizedBox(height: 20),
      ...destinations.map((r) {
        final stars = widget.store.stars(r);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: stars > 0
                ? const Color(0xFFE7ECDE)
                : Colors.white.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(18),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 8,
              ),
              leading: SizedBox(
                width: 65,
                child: Opacity(
                  opacity: stars > 0 ? 1 : .42,
                  child: MapThumbnail(r, height: 60),
                ),
              ),
              title: Text(
                geoRegionLabel(r),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                stars > 0
                    ? 'A beautiful piece of your world'
                    : 'An adventure yet to begin',
                style: const TextStyle(fontSize: 12, color: muted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < stars
                        ? const Color(0xFFAA7B39)
                        : const Color(0xFFB7C2BB),
                    size: 17,
                  ),
                ),
              ),
              onTap: () => _start(r),
            ),
          ),
        );
      }),
    ],
  );
  Widget _settings() => ListView(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
    children: [
      const Eyebrow('Make yourself at home'),
      const SizedBox(height: 10),
      const Text(
        'Your kind of calm',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.3,
          color: ink,
        ),
      ),
      const SizedBox(height: 25),
      const Card(
        child: ListTile(
          leading: Icon(Icons.public),
          title: Text('Your atlas is open'),
          subtitle: Text('All 18 maps are free to play on PuzzleCub.'),
        ),
      ),
      _toggle(
        'Sound effects',
        'Little notes for little discoveries',
        Icons.music_note_outlined,
        widget.store.sound,
        (v) => widget.store.setting('sound', v),
      ),
      _toggle(
        'Haptic feedback',
        'Feel each piece settle into place',
        Icons.vibration_rounded,
        widget.store.haptics,
        (v) => widget.store.setting('haptics', v),
      ),
      _toggle(
        'Reduced motion',
        'Keep transitions and celebrations still',
        Icons.slow_motion_video_rounded,
        widget.store.reducedMotion,
        (v) => widget.store.setting('reducedMotion', v),
      ),
      const SizedBox(height: 20),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.help_outline, color: teal),
        title: const Text(
          'A little field guide',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: _howTo,
      ),
      if (widget.store.ads.privacyRequired)
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined, color: teal),
          title: const Text('Ad privacy choices'),
          onTap: widget.store.ads.privacy,
        ),
      ListTile(
        leading: const Icon(Icons.policy_outlined, color: teal),
        title: const Text('Privacy policy'),
        onTap: () => _openLink(Uri.parse('https://puzzlecub.com/privacy')),
      ),
      const Divider(),
      const SizedBox(height: 20),
      const Eyebrow('More from us'),
      const SizedBox(height: 10),
      ...FamilyGame.values.map(
        (game) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.extension_outlined, color: teal),
          title: Text(
            game.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            game.description,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _openLink(game.link(Theme.of(context).platform)),
        ),
      ),
      const Divider(),
      const SizedBox(height: 20),
      const Align(alignment: Alignment.centerLeft, child: AtlasMark(size: 52)),
      const SizedBox(height: 15),
      const Text(
        'Mapopia',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink),
      ),
      const SizedBox(height: 5),
      const Text(
        'Fit the pieces. Discover the world.',
        style: TextStyle(color: muted),
      ),
      const SizedBox(height: 22),
      const Text(
        'Your atlas stays with you. Progress and settings are saved on this device. Unlocked maps work offline. No account required.',
        style: TextStyle(color: muted, height: 1.7, fontSize: 12),
      ),
      const SizedBox(height: 14),
      const Text(
        'Map shapes: Natural Earth (public domain). Maps are simplified for play; small regions and territories may be omitted. Boundaries are for puzzle play, not political or navigation reference.',
        style: TextStyle(color: muted, height: 1.6, fontSize: 11),
      ),
      const SizedBox(height: 20),
      const Eyebrow('Version 1.0 · Made with curiosity'),
    ],
  );
  Widget _toggle(
    String title,
    String sub,
    IconData icon,
    bool value,
    ValueChanged<bool> changed,
  ) => SwitchListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 7),
    secondary: Icon(icon, color: teal),
    title: Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: muted)),
    value: value,
    onChanged: changed,
    activeThumbColor: teal,
  );
  void _howTo() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: paper,
    showDragHandle: true,
    builder: (_) => const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(26, 6, 26, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow('The Mapopia field guide'),
            SizedBox(height: 12),
            Text(
              'One piece at a time.',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            SizedBox(height: 18),
            Text(
              '1. Pick a piece\nTap a card in the tray, or hold it to lift it.\n\n2. Find its home\nTap the matching place on the map, or drag the piece there. Pinch or use + to zoom into tiny places.\n\n3. Make a discovery\nEvery correct placement reveals a name, a capital, and a little fact.\n\nNeed a nudge?\nThe compass hint lights up the right spot. Hints are free on the web. Each hint costs 35 points.\n\nCollect your stamp\nComplete a map to save it in your journal. Three stars: at least 90% accuracy, no hints. Two stars: at least 70% accuracy, up to three hints.\n\nYour pace, your place\nRelaxed play has no deadline. Timed expeditions give you 20 seconds per piece plus 30 seconds to settle in.',
              style: TextStyle(fontSize: 14, height: 1.65, color: muted),
            ),
          ],
        ),
      ),
    ),
  );
}
