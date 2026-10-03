import 'package:flutter/semantics.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/preferences.dart';
import 'services/audio.dart';
import 'services/ads.dart';
import 'ui/home.dart';
import 'ui/toy_box.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  SharedPreferences.setPrefix('flutter.puzzlecub.slide-and-sort.');
  final preferences = Preferences(await SharedPreferences.getInstance());
  runApp(ArrangeAlphabetsApp(preferences: preferences));
}

class ArrangeAlphabetsApp extends StatefulWidget {
  const ArrangeAlphabetsApp({super.key, required this.preferences});
  final Preferences preferences;
  @override
  State<ArrangeAlphabetsApp> createState() => _ArrangeAlphabetsAppState();
}

class _ArrangeAlphabetsAppState extends State<ArrangeAlphabetsApp>
    with WidgetsBindingObserver {
  late final ads = GameAds(widget.preferences);
  final audio = GameAudio();
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.preferences.addListener(_audio);
  }

  void _audio() =>
      unawaited(audio.music(foreground && widget.preferences.music));
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    _audio();
    if (foreground) widget.preferences.refreshAudience();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.preferences.removeListener(_audio);
    audio.dispose();
    ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.preferences,
    builder: (context, _) => MaterialApp(
      title: 'Slide & Sort: ABCs & 123s',
      debugShowCheckedModeBanner: false,
      theme: toyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              widget.preferences.reducedMotion ||
              MediaQuery.disableAnimationsOf(context),
        ),
        child: child!,
      ),
      home: AlphabetHome(
        preferences: widget.preferences,
        audio: audio,
        ads: ads,
      ),
    ),
  );
}
