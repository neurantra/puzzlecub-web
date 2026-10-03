import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';

/// Store destinations shared with the sibling apps' cross-promo catalogs.
enum StudioGame {
  fillTheJar(
    'Fill the Jar',
    'A little space. A perfect fit.',
    '6813074285',
    'com.fillthejar.app',
    Icons.water_drop_outlined,
  ),
  mapopia(
    'Mapopia',
    'Explore the world through geography puzzles.',
    '6816405706',
    'com.mapopia.app',
    Icons.public,
  ),
  mazeWords(
    'Maze Words',
    'Run the maze. Find the words.',
    '6816219346',
    'com.mazewords.app',
    Icons.route_outlined,
  ),
  puzzlecub(
    'PuzzleCub',
    'A collection of clever little puzzles.',
    '6768766852',
    'com.sumquest.app',
    Icons.extension_outlined,
  );

  const StudioGame(
    this.title,
    this.description,
    this.appleId,
    this.package,
    this.icon,
  );
  final String title, description, appleId, package;
  final IconData icon;
  Uri? link(TargetPlatform platform) => platform == TargetPlatform.android
      ? Uri.https('play.google.com', '/store/apps/details', {'id': package})
      : appleId.isEmpty
      ? null
      : Uri.https('apps.apple.com', '/app/id$appleId');
}

Future<void> showMoreGames(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: ChaturangTheme.deepMaroon,
  builder: (_) => const SafeArea(
    top: false,
    child: SingleChildScrollView(child: MoreGamesSection()),
  ),
);

class MoreGamesSection extends StatelessWidget {
  const MoreGamesSection({super.key});

  Future<void> _open(BuildContext context, Uri url) async {
    var opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      /* A missing store app can fail on some devices. */
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the store. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'More games from Neurantra',
              style: TextStyle(
                color: ChaturangTheme.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Something new for your next break.',
              style: TextStyle(color: ChaturangTheme.secondaryText),
            ),
            const SizedBox(height: 16),
            for (final game in StudioGame.values)
              if (game.link(Theme.of(context).platform) case final Uri url)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: const Color(0xFF203738),
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: Icon(
                        game.icon,
                        color: ChaturangTheme.saffronLight,
                        size: 30,
                      ),
                      title: Text(
                        game.title,
                        style: const TextStyle(
                          color: ChaturangTheme.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        game.description,
                        style: const TextStyle(
                          color: ChaturangTheme.secondaryText,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: ChaturangTheme.saffronLight,
                      ),
                      onTap: () => _open(context, url),
                    ),
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}
