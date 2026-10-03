import 'package:flutter/semantics.dart';
import 'web_bridge.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/expedition.dart';
import 'ui/home.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  SharedPreferences.setPrefix('flutter.puzzlecub.mapopia.');
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final store = AtlasStore(prefs);
  setWebAdsAllowed(true);
  runApp(MapopiaApp(store: store));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(() async {
      await store.commerce.initialize();
      await store.ads.initialize();
    }());
  });
}

class MapopiaApp extends StatelessWidget {
  const MapopiaApp({super.key, required this.store, this.today});
  final AtlasStore store;
  final DateTime? today;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      title: 'Mapopia',
      debugShowCheckedModeBanner: false,
      theme: atlasTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              store.reducedMotion || MediaQuery.of(context).disableAnimations,
        ),
        child: child!,
      ),
      home: AtlasHome(store: store, today: today),
    ),
  );
}
