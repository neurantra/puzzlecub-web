import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/player_store.dart';
import 'services/game_services.dart';
import 'ui/home_screen.dart';
import 'ui/style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  SharedPreferences.setPrefix('flutter.puzzlecub.mazewords.');
  final store = PlayerStore(await SharedPreferences.getInstance());
  runApp(MazeWordsApp(store: store));
}

class MazeWordsApp extends StatefulWidget {
  const MazeWordsApp({super.key, required this.store});
  final PlayerStore store;
  @override
  State<MazeWordsApp> createState() => _MazeWordsAppState();
}

class _MazeWordsAppState extends State<MazeWordsApp> {
  late final services = GameServices(widget.store);
  @override
  void dispose() {
    services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Maze Words',
    debugShowCheckedModeBanner: false,
    theme: mazeTheme(),
    home: HomeScreen(store: widget.store, services: services),
  );
}
