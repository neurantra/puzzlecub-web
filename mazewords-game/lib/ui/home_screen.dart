import 'dart:async';
import 'licenses_screen.dart';
import 'language_store_screen.dart';
import '../services/purchases/revenuecat_gateway.dart';
import 'age_information.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'language_packs_screen.dart';
import '../domain/puzzle_language.dart';
import '../data/player_store.dart';
import '../domain/hunt.dart';
import '../domain/maze.dart';
import '../domain/maze_level.dart';
import '../services/game_services.dart';
import 'hunt_screen.dart';
import '../domain/maze_theme.dart';
import 'hunt_setup.dart';
import 'home_ad.dart';
import 'maze_board.dart';
import 'style.dart';
import 'coin_bag.dart';
import 'vault_sheet.dart';
import '../services/app_links.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, required this.services});
  final PlayerStore store;
  final GameServices services;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  MazeLevel _level = MazeLevel.easy;
  bool _relaxed = false;
  late Future<MazePack> _preview = widget.services.packs.load(
    widget.store.language,
    MazeLevel.easy,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.store.onboarded && mounted) await _welcome();
      await widget.services.configure();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        widget.services.refreshAudience().then((_) {
          if (mounted) setState(() {});
          return widget.services.recoverVault();
        }),
      );
    }
  }

  Future<void> _welcome() async {
    await showAgeInformation(
      context,
      required: true,
      save: widget.store.setBirthYear,
    );
  }

  Future<void> _ageInformation() async {
    if (widget.services.audienceChangeBusy ||
        widget.store.walletBusy ||
        widget.store.vaultTransfers.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Let the current ad or coin transfer finish before changing age information.',
          ),
        ),
      );
      return;
    }
    if (!await ageParentGate(context) || !mounted) return;
    final changed = await showAgeInformation(
      context,
      birthYear: widget.store.birthYear,
      save: (year) async {
        if (widget.services.audienceChangeBusy) throw StateError("Busy");
        await widget.store.setBirthYear(year);
      },
    );
    if (changed) {
      await widget.services.refreshAudience();
      if (mounted) setState(() {});
    }
  }

  Future<void> _languagePacks({bool update = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LanguagePacksScreen(
          store: widget.store,
          packs: widget.services.packs,
          updateOnOpen: update,
          purchases: RevenueCatGateway.enabled
              ? widget.services.purchases
              : null,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _preview = widget.services.packs.load(
          widget.store.language,
          MazeLevel.easy,
        );
      });
    }
  }

  bool _openingTrail = false;
  Future<void> _play({bool daily = false}) async {
    if (_openingTrail) return;
    _openingTrail = true;
    try {
      final seed = daily ? daySeed(DateTime.now()) : null;
      final level = daily ? MazeLevel.easy : _level;
      final relaxed = daily ? false : _relaxed;
      final prepared = await prepareHunt(
        context,
        widget.store,
        level,
        relaxed: relaxed,
        packs: widget.services.packs,
        purchases: RevenueCatGateway.enabled ? widget.services.purchases : null,
      );
      if (prepared == null || !mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HuntScreen(
            store: widget.store,
            services: widget.services,
            level: level,
            relaxed: relaxed,
            prepared: prepared,
            daily: seed,
          ),
        ),
      );
      if (mounted) {
        await widget.services.afterRound();
        if (mounted) setState(() {});
      }
    } finally {
      _openingTrail = false;
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) => Scaffold(
      bottomNavigationBar: widget.services.bannerReady
          ? HomeAd(services: widget.services)
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: teal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.route_rounded,
                              color: Color(0xFFEEE8C8),
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'maze words',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                                letterSpacing: -.8,
                              ),
                            ),
                          ),
                          _coinBadge(
                            widget.store.coins,
                            onTap: () => showCoinVault(
                              context,
                              widget.store,
                              widget.services,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Settings',
                            onPressed: _settings,
                            icon: const Icon(Icons.settings_rounded, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Eyebrow('A LITTLE WANDER. A WORD WONDER.'),
                      const SizedBox(height: 12),
                      const Text(
                        'Find your\nway with words.',
                        style: TextStyle(
                          fontSize: 43,
                          height: 1.06,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Run the maze. Find the words.',
                        style: TextStyle(color: muted, fontSize: 15),
                      ),
                      TextButton.icon(
                        onPressed: _languagePacks,
                        icon: const Icon(Icons.language, size: 18),
                        label: Text(
                          'Download languages · ${PuzzleLanguage.of(widget.store.language).name}',
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<MazePack>(
                        key: ValueKey(widget.store.language),
                        future: _preview,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Text(
                                    'This language pack is unavailable. Download it again or switch to English.',
                                  ),
                                  TextButton(
                                    onPressed: _languagePacks,
                                    child: const Text('Manage puzzle packs'),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const SizedBox(
                              height: 240,
                              child: Center(
                                child: Icon(Icons.route, size: 80, color: teal),
                              ),
                            );
                          }
                          final maze = snapshot.data!.mazes.first;
                          final path =
                              maze.commonPaths[maze.seedWord] ?? const <int>[];
                          return Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Transform.rotate(
                                  angle: -.055,
                                  child: MazeBoard(
                                    theme: widget.store.mazeTheme,
                                    maze: maze,
                                    path: path,
                                    interactive: false,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 9,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ink,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: ink.withValues(alpha: .16),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${maze.seedWord}  ✦  A path worth finding',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(child: Eyebrow('CHOOSE YOUR TRAIL')),
                          Text(
                            'Best  ${widget.store.best(_level, relaxed: _relaxed)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final level in MazeLevel.values)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: level == MazeLevel.hard ? 0 : 8,
                                ),
                                child: Semantics(
                                  selected: _level == level,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(17),
                                    onTap: () => setState(() => _level = level),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _level == level
                                            ? teal
                                            : const Color(0xFFEEEEE3),
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            switch (level) {
                                              MazeLevel.easy =>
                                                Icons.spa_outlined,
                                              MazeLevel.medium =>
                                                Icons.park_outlined,
                                              MazeLevel.hard =>
                                                Icons.landscape_outlined,
                                            },
                                            color: _level == level
                                                ? const Color(0xFFDFECCB)
                                                : muted,
                                          ),
                                          const SizedBox(height: 7),
                                          Text(
                                            level.label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: _level == level
                                                  ? Colors.white
                                                  : ink,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            switch (level) {
                                              MazeLevel.easy => '6 × 6',
                                              MazeLevel.medium => '7 × 7',
                                              MazeLevel.hard => '9 × 9',
                                            },
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _level == level
                                                  ? const Color(0xFFD3E4D0)
                                                  : muted,
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
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Take the scenic route',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: const Text(
                          'Relaxed play · no timer or attempt limit',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                        value: _relaxed,
                        onChanged: (v) => setState(() => _relaxed = v),
                      ),
                      if (!_relaxed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            widget.store.huntOptions(_level).summary(_level),
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                        ),
                      FilledButton(
                        onPressed: () => _play(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _relaxed ||
                                        widget.store.huntOptions(_level).cost ==
                                            0
                                    ? 'Let’s wander'
                                    : 'Start hunt · ${widget.store.huntOptions(_level).cost} coins',
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _play(daily: true),
                        borderRadius: BorderRadius.circular(24),
                        child: Surface(
                          color: const Color(0xFFE9EEDC),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.wb_sunny_outlined,
                                color: teal,
                                size: 29,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Eyebrow('THE DAILY DETOUR'),
                                    const SizedBox(height: 5),
                                    Text(
                                      widget.store.dailyDone(
                                            daySeed(DateTime.now()),
                                          )
                                          ? 'Today’s trail, revisited'
                                          : 'One maze. A fresh little challenge.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.store
                                          .huntOptions(MazeLevel.easy)
                                          .summary(MazeLevel.easy),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: muted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.store.dailyDone(
                                            daySeed(DateTime.now()),
                                          )
                                          ? 'Bonus collected · replay for fun'
                                          : 'Easy trail · +20 coins on completion',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward, size: 19),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 23),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stat('${widget.store.rounds}', 'TRAILS FINISHED'),
                          _stat('${widget.store.words}', 'WORDS FOUND'),
                          TextButton(
                            onPressed: () => showHowTo(context),
                            child: const Text(
                              'How to play',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: _settings,
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text('Settings'),
                      ),
                      if (widget.store.adult) ...[
                        const SizedBox(height: 12),
                        const Eyebrow('MORE FROM NEURANTRA'),
                        for (final game in FamilyGame.values)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.extension_outlined),
                            title: Text('Play ${game.title}'),
                            trailing: const Icon(Icons.open_in_new, size: 18),
                            onTap: () => _openApp(
                              context,
                              ios: game.ios,
                              android: game.android,
                            ),
                          ),
                      ],
                      if (widget.store.saveError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            widget.store.saveError!,
                            style: const TextStyle(color: Colors.red),
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

  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: const TextStyle(fontSize: 8, letterSpacing: 1, color: muted),
      ),
    ],
  );

  void _settings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: paper,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Make yourself at home.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close settings',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Age information'),
                  subtitle: Text(
                    widget.store.birthYear == null
                        ? 'Add a birth year · parent gate'
                        : 'Birth year: ${widget.store.birthYear} · parent gate',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _ageInformation();
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sounds'),
                  value: widget.store.sound,
                  onChanged: (v) => widget.store.set('sound', v),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gentle haptics'),
                  value: widget.store.haptics,
                  onChanged: (v) => widget.store.set('haptics', v),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Download languages'),
                  subtitle: Text(
                    '${PuzzleLanguage.of(widget.store.language).flag} ${PuzzleLanguage.of(widget.store.language).name}',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _languagePacks();
                  },
                ),
                if (RevenueCatGateway.enabled)
                  ListTile(
                    leading: const Icon(Icons.lock_open),
                    title: const Text('Unlock languages'),
                    subtitle: const Text('One-time purchases · no ads'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LanguageStoreScreen(
                            store: widget.store,
                            purchases: widget.services.purchases,
                          ),
                        ),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Update / refresh words'),
                  subtitle: const Text('Update your installed language packs'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _languagePacks(update: true);
                  },
                ),
                const Text(
                  'Maze appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                for (final theme in MazeTheme.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(switch (theme) {
                      MazeTheme.hedge => Icons.park_rounded,
                      MazeTheme.stone => Icons.landscape_rounded,
                      MazeTheme.glass => Icons.diamond_outlined,
                    }),
                    title: Text(theme.label),
                    subtitle: Text(theme.description),
                    trailing: widget.store.mazeTheme == theme
                        ? const Icon(Icons.check_circle, color: teal)
                        : null,
                    onTap: () => widget.store.set('mazeTheme', theme.name),
                  ),
                const Divider(),
                HuntSettings(store: widget.store, initialLevel: _level),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline),
                  title: const Text('How to play'),
                  onTap: () => showHowTo(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.savings_outlined),
                  title: const Text('Coin vault'),
                  onTap: () =>
                      showCoinVault(context, widget.store, widget.services),
                ),
                if (widget.services.rewardedReady)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('Watch an ad · +25 coins'),
                    onTap: () async {
                      final earned = await widget.services.bonusAd();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              earned
                                  ? '25 coins added.'
                                  : 'No ad available right now.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                if (widget.services.privacyRequired)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ad privacy choices'),
                    onTap: () async {
                      await widget.services.privacy();
                      if (mounted) setState(() {});
                    },
                  ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Licenses'),
                  subtitle: const Text(
                    'Language data and open-source software',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LicensesScreen(),
                      ),
                    );
                  },
                ),
                for (final entry in [
                  (Icons.privacy_tip_outlined, 'Privacy', AppLinks.privacy),
                  (Icons.description_outlined, 'Terms', AppLinks.terms),
                  (Icons.mail_outline, 'Contact', AppLinks.contact),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(entry.$1),
                    title: Text(entry.$2),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () =>
                        _openApp(context, ios: entry.$3, android: entry.$3),
                  ),
                if (widget.store.adult)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.star_outline_rounded),
                    title: const Text('Rate the app'),
                    onTap: () {
                      final url = kIsWeb
                          ? null
                          : AppLinks.rating(defaultTargetPlatform);
                      if (url == null) {
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Thanks for playing!'),
                            content: const Text(
                              'Store ratings will be available when Maze Words is published. For now, you can share feedback using Contact.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        _openApp(context, ios: url, android: url);
                      }
                    },
                  ),
                if (widget.store.adult) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  const Eyebrow('MORE FROM NEURANTRA'),
                  for (final game in FamilyGame.values)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.extension_outlined),
                      title: Text('Play ${game.title}'),
                      subtitle: Text(game.description),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _openApp(
                        context,
                        ios: game.ios,
                        android: game.android,
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Maze Words · 1.1.0\nRun the maze. Find the words.\n\nYour scores and coins are saved on this device.',
                  style: TextStyle(color: muted, fontSize: 11, height: 1.7),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _openApp(
    BuildContext context, {
    required String ios,
    required String android,
  }) async {
    if (!widget.store.adult) {
      final answer = TextEditingController();
      final allowed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('A grown-up’s help'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ask a grown-up: what is 7 × 8?'),
              TextField(
                controller: answer,
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, answer.text.trim() == '56'),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      // Dialog transitions may still reference the controller this frame.
      Future<void>.delayed(const Duration(seconds: 1), answer.dispose);
      if (allowed != true || !context.mounted) return;
    }
    try {
      final url = defaultTargetPlatform == TargetPlatform.android
          ? android
          : ios;
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('Unavailable');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link. Please try again.'),
          ),
        );
      }
    }
  }
}

Widget coinBadge(int coins, {VoidCallback? onTap}) =>
    _coinBadge(coins, onTap: onTap);
Widget _coinBadge(int coins, {VoidCallback? onTap}) =>
    CoinBag(coins: coins, onTap: onTap);

Future<void> showHowTo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Follow your curiosity.'),
    content: const SingleChildScrollView(
      child: Text(
        '1. Start anywhere and trace through open corridors. Walls block your path.\n\n2. Collect tiles in order: at least 3 for alphabet-based packs, or 2 for Tamil, Hindi, Bengali and Japanese. Vowel signs and letter clusters stay together on one tile. Lift your finger to submit.\n\n3. Retrace one step to undo a wrong turn. Find the common words to complete the maze; bonus words earn extra points.\n\nPrefer tapping? Choose Tap letters, then tap letter tiles in order. Green outlines show reachable next letters. Empty corridors connect automatically; walls and intervening letters cannot be skipped. Tap a selected letter to go back, or use Undo. Press Submit when ready. Hints cost 5 coins and reveal a starting letter.\n\nTimed trails have a clock and limited mistakes. Relaxed trails have neither, and keep their own best scores.',
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Got it'),
      ),
    ],
  ),
);
