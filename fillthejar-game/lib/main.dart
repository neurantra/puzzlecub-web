import 'package:flutter/semantics.dart';
import 'dart:async';
import 'services/pack_purchases.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/geometry.dart';
import 'game/session.dart';
import 'services/services.dart';
import 'ui/game_screen.dart';
import 'ui/art.dart';
import 'services/audience.dart';
import 'ui/age_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  SharedPreferences.setPrefix('flutter.puzzlecub.fillthejar.');
  final data =
      jsonDecode(await rootBundle.loadString('assets/levels.json'))
          as Map<String, dynamic>;
  final levels = (data['levels'] as List)
      .map((j) => Puzzle.fromJson(Map<String, dynamic>.from(j)))
      .toList();
  final previews = (data['previews'] as List)
      .map((j) => Puzzle.fromJson(Map<String, dynamic>.from(j)))
      .toList();
  final session = GameSession(
    levels,
    previews,
    freePlayLimited: false,
    replayCampaigns: (data['replayCampaigns'] as List? ?? [])
        .map(
          (tour) => (tour as List)
              .map((j) => Puzzle.fromJson(Map<String, dynamic>.from(j)))
              .toList(),
        )
        .toList(),
    legacyLevels: (data['legacyLevels'] as List? ?? [])
        .map((j) => Puzzle.fromJson(Map<String, dynamic>.from(j)))
        .toList(),
  );
  if (kDebugMode && const bool.fromEnvironment('PICTURE_PROTOTYPE')) {
    runApp(
      JarApp(
        session: session,
        audience: Audience(1990), // Synthetic adult profile for test-ad review.
        picturePrototype: true,
      ),
    );
    return;
  }
  final store = SaveStore(await SharedPreferences.getInstance());
  session.restore(store.read());
  runApp(JarApp(session: session, store: store));
}

class JarApp extends StatefulWidget {
  final GameSession session;
  final PackPurchases? purchases;
  final SaveStore? store;
  final Audience? audience;
  final bool picturePrototype;
  const JarApp({
    super.key,
    required this.session,
    this.purchases,
    this.store,
    this.audience,
    this.picturePrototype = false,
  });
  @override
  State<JarApp> createState() => _JarAppState();
}

class _JarAppState extends State<JarApp> with WidgetsBindingObserver {
  int _audienceRevision = 0;
  late bool _online;
  late Audience audience;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audience =
        widget.audience ??
        (widget.store == null
            ? Audience(null)
            : Audience.read(widget.store!.prefs));
    _online = audience.externalServicesAllowed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.purchases?.dispose();
    super.dispose();
  }

  void _setAudience(Audience value) => setState(() {
    audience = value;
    _online = value.externalServicesAllowed;
    _audienceRevision++;
  });
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.purchases?.refresh());
    }
    if (state == AppLifecycleState.resumed &&
        _online != audience.externalServicesAllowed &&
        !widget.session.walletBusy &&
        widget.session.vaultTransfers.isEmpty &&
        !widget.session.solving &&
        !widget.session.rewardBusy) {
      _setAudience(audience);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fill the Jar',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        surface: const Color(0xfffffcff),
      ),
      scaffoldBackgroundColor: const Color(0xffdbf5f8),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    ),
    home: audience.answered
        ? GameScreen(
            key: ValueKey(_audienceRevision),
            onAudienceChanged: _setAudience,
            session: widget.session,
            purchases: widget.purchases,
            startPicturePrototype: widget.picturePrototype,
            store: widget.store,
            audience: audience,
          )
        : AgeScreen(store: widget.store, onSaved: _setAudience),
  );
}
