import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'audio/audio_service.dart';
import 'app_info.dart';
import 'data/appearance_service.dart';
import 'data/difficulty_preference.dart';
import 'data/game_preferences.dart';
import 'data/stats_service.dart';
import 'engine/opening_book.dart';
import 'engine/tablebase.dart';
import 'ui/court_home.dart';
import 'ui/theme.dart';

/// Ambient KR-K tablebase. Initialized to null and set when background
/// generation finishes. UI code that owns an [AiPlayer] reads it through
/// a callback so the next AI move automatically picks it up.
final ValueNotifier<Tablebase?> tablebaseNotifier = ValueNotifier<Tablebase?>(
  null,
);

/// Ambient opening book, empty until the asset loads. Same lifecycle as the
/// tablebase: the AI reads it through a callback, so a slow load costs the
/// first move or two its head start rather than blocking startup.
final ValueNotifier<OpeningBook> openingBookNotifier =
    ValueNotifier<OpeningBook>(OpeningBook.empty);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore mute before audio loading or the first playable frame.
  await GamePreferences.soundEnabled.load();
  // Expose the board and card controls to keyboard/screen-reader users on web.
  SemanticsBinding.instance.ensureSemantics();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Plus Jakarta Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Cormorant Garamond',
    ], await rootBundle.loadString('assets/fonts/CormorantGaramond-OFL.txt'));
  });
  // Fire-and-forget audio asset preload. Per-sound load failures are
  // tolerated; play() falls back silently. See [AudioService].
  unawaited(AudioService.instance.load());
  // Fire-and-forget stats load from shared_preferences. The Stats modal
  // and recordGame hook tolerate uninitialized state (zero counters).
  unawaited(StatsService.instance.load());
  // Fire-and-forget AI-level load. Easy until it resolves, which is also
  // the right answer on a first launch; the card-pick screen re-renders
  // when it lands.
  unawaited(DifficultyPreference.instance.load());
  // Fire-and-forget appearance load (owned + equipped Store items). The
  // board tolerates uninitialized state: both getters fall back to the
  // free Classic set until this resolves, and BoardWidget listens for the
  // notification so it repaints once it does.
  unawaited(AppearanceService.instance.load());
  // Cached shared-vault kill switch. Local read, so the first frame already
  // knows whether to offer the feature; the network refresh happens later,
  // from the board screen. Fails closed — no cache means off.

  // Fire-and-forget bundle-version read for the About modal. Falls back to
  // the compile-time constants if the platform channel is unavailable.
  unawaited(AppInfo.load());
  // Web AI is executed in a browser worker; no Dart isolates are used.
  // Mobile KR-K tablebase generation (~1s
  // on a modern machine). Until it lands, AiPlayer falls back to normal
  // alpha-beta search.

  // Fire-and-forget opening-book load. A missing or corrupt book leaves the
  // engine searching from move one, which is exactly what it did before.
  unawaited(_loadOpeningBook());
  runApp(const ChaturangApp());
}

Future<void> _loadOpeningBook() async {
  try {
    final text = await rootBundle.loadString('assets/book/openings.txt');
    openingBookNotifier.value = OpeningBook.parse(text);
  } catch (e) {
    debugPrint('Opening book unavailable: $e');
  }
}

class ChaturangApp extends StatelessWidget {
  const ChaturangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chaturang',
      debugShowCheckedModeBanner: false,
      theme: ChaturangTheme.data(),
      home: const CourtHome(),
    );
  }
}
