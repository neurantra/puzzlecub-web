import '../web_bridge.dart';
import '../data/release_policy.dart';
import 'update_required.dart';
import 'dart:async';
import '../data/ads_service.dart';
import 'package:flutter/material.dart';
import '../app_info.dart';
import '../data/difficulty_preference.dart';
import '../data/game_access.dart';
import '../engine/difficulty.dart';
import 'card_pick_screen.dart';
import 'full_game_sheet.dart';
import 'online/online_lobby_screen.dart';
import 'rules_screen.dart';
import 'stats_modal.dart';
import 'settings_modal.dart';
import 'about_modal.dart';
import '../data/game_preferences.dart';
import 'theme.dart';
import 'more_games.dart';
import 'royal_film.dart';

class CourtHome extends StatefulWidget {
  const CourtHome({super.key});
  @override
  State<CourtHome> createState() => _CourtHomeState();
}

class _CourtHomeState extends State<CourtHome> with WidgetsBindingObserver {
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    ReleasePolicy.instance.addListener(_policyChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_initializeAds());
        unawaited(ReleasePolicy.instance.refresh());
      }
    });
    unawaited(GameAccess.instance.initialize());
    unawaited(DifficultyPreference.instance.load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_initializeAds());
      unawaited(ReleasePolicy.instance.refresh());
    }
  }

  Future<void> _initializeAds() async {
    await GameAccess.instance.initialize();
    if (mounted) await AdsService.instance.initialize();
  }

  void _policyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ReleasePolicy.instance.removeListener(_policyChanged);
    super.dispose();
  }

  Future<void> _play(bool online) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      if (!await checkGameAccess(context) || !mounted) return;
      await betweenGames();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              online ? const OnlineLobbyScreen() : const CardPickScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => ReleasePolicy.instance.blocked
      ? const UpdateRequired()
      : Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/decorations/royal_court.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(.25, 0),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66101E20),
                        Color(0x00101E20),
                        Color(0xEE101E20),
                        Color(0xFF101E20),
                      ],
                      stops: [0, .38, .72, 1],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: ChaturangTheme.saffronLight,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'THE ORIGINAL GAME OF KINGS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 2.3,
                                          color: ChaturangTheme.parchment,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Your record',
                                      onPressed: () => showStatsSheet(context),
                                      icon: const Icon(
                                        Icons.bar_chart_rounded,
                                        size: 22,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Settings and more',
                                      icon: const Icon(
                                        Icons.more_horiz_rounded,
                                      ),
                                      onSelected: (value) {
                                        if (value == 'Settings') {
                                          showSettingsSheet(
                                            context,
                                            difficulty:
                                                DifficultyPreference.instance,
                                            soundEnabled:
                                                GamePreferences.soundEnabled,
                                            timedMode:
                                                GamePreferences.timedMode,
                                            moveLimit:
                                                GamePreferences.moveLimit,
                                          );
                                        } else {
                                          showAboutSheet(context);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'Settings',
                                          child: Text('Settings'),
                                        ),
                                        PopupMenuItem(
                                          value: 'About',
                                          child: Text('About'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Chaturang',
                                  style: const TextStyle(
                                    fontFamily: 'CormorantGaramond',
                                    fontSize: 64,
                                    height: 1.05,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFFEED2),
                                    letterSpacing: -2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'An ancient board.\nAn entirely new rivalry.',
                                  style: TextStyle(
                                    fontSize: 17,
                                    height: 1.55,
                                    color: ChaturangTheme.primaryText,
                                  ),
                                ),
                                SizedBox(
                                  height: (constraints.maxHeight * .23).clamp(
                                    100.0,
                                    260.0,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 1,
                                      color: ChaturangTheme.saffronLight,
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'ENTER THE COURT',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 2.8,
                                          color: ChaturangTheme.saffronLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xED1D3031),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: const Color(0x557F958B),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.psychology_outlined,
                                            color: ChaturangTheme.saffronLight,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Challenge the court',
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'CormorantGaramond',
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.w600,
                                                    color: ChaturangTheme
                                                        .parchment,
                                                  ),
                                                ),
                                                const Text(
                                                  'A worthy rival. At your pace.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: ChaturangTheme
                                                        .secondaryText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      ValueListenableBuilder<Difficulty>(
                                        valueListenable:
                                            DifficultyPreference.instance,
                                        builder: (context, selected, _) => Row(
                                          children: [
                                            for (final level
                                                in Difficulty.values)
                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    right:
                                                        level == Difficulty.hard
                                                        ? 0
                                                        : 6,
                                                  ),
                                                  child: ChoiceChip(
                                                    label: SizedBox(
                                                      width: double.infinity,
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          level.label,
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                    showCheckmark: false,
                                                    selected: selected == level,
                                                    onSelected: _opening
                                                        ? null
                                                        : (_) =>
                                                              DifficultyPreference
                                                                      .instance
                                                                      .value =
                                                                  level,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      FilledButton(
                                        onPressed: _opening
                                            ? null
                                            : () => _play(false),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 13,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  'Play against AI',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (kOnlineMultiplayerEnabled) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: _opening
                                        ? null
                                        : () => _play(true),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 17,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.public, size: 20),
                                          SizedBox(width: 10),
                                          Flexible(
                                            child: Text(
                                              'Play with a friend',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'ONLINE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              letterSpacing: 1.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                ListenableBuilder(
                                  listenable: GameAccess.instance,
                                  builder: (context, _) => Text(
                                    'FREE TO PLAY · AGAINST AI',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: ChaturangTheme.secondaryText,
                                      letterSpacing: .3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => const RulesScreen(),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.menu_book_outlined,
                                        size: 17,
                                      ),
                                      label: const Text('Learn to play'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => showMoreGames(context),
                                      icon: const Icon(
                                        Icons.apps_rounded,
                                        size: 17,
                                      ),
                                      label: const Text('More games'),
                                    ),
                                  ],
                                ),
                                const RoyalFilmCard(),
                                const MoreGamesSection(),
                              ],
                            ),
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
}
