import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

import 'ui/home.dart';
import 'ui/style.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  for (final name in ['ESDB', 'WordNet', 'wordfreq']) {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        name,
      ], await rootBundle.loadString('assets/licenses/$name.txt'));
    });
  }
  runApp(const AlphadokuApp());
}

class AlphadokuApp extends StatelessWidget {
  const AlphadokuApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Alphadoku: Letter Sudoku',
    debugShowCheckedModeBanner: false,
    theme: alphadokuTheme(),
    home: const HomeScreen(),
  );
}
