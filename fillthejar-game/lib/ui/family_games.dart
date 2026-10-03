import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'art.dart';

enum FamilyGame {
  puzzlecub(
    'PuzzleCub',
    'Number and geography puzzles. A world of little discoveries.',
    'puzzlecub',
    'https://apps.apple.com/us/app/puzzlecub/id6768766852',
    'https://play.google.com/store/apps/details?id=com.sumquest.app',
  ),
  chaturang(
    'Chaturang',
    'Ancient chess. Fresh possibilities. Your next move awaits.',
    'chaturang',
    'https://apps.apple.com/us/app/chaturang-ancient-chess/id6770267722',
    'https://play.google.com/store/apps/details?id=com.chaturang.app',
  ),
  mazewords(
    'Maze Words',
    'Run the maze. Find the words.',
    'mazewords',
    '',
    'https://play.google.com/store/apps/details?id=com.mazewords.app',
  );

  static const mazeWordsAppleId = String.fromEnvironment(
    'MAZEWORDS_APPLE_APP_STORE_ID',
  );
  static String? get mazeWordsIos => RegExp(r'^\d+$').hasMatch(mazeWordsAppleId)
      ? 'https://apps.apple.com/app/id$mazeWordsAppleId'
      : null;

  const FamilyGame(
    this.title,
    this.description,
    this.asset,
    this.ios,
    this.android,
  );
  final String title, description, asset, ios, android;
  String get image => 'assets/family/$asset.png';
}

Future<void> openFamilyGame(BuildContext context, FamilyGame game) async {
  final ios = game == FamilyGame.mazewords ? FamilyGame.mazeWordsIos : game.ios;
  var url = defaultTargetPlatform == TargetPlatform.android
      ? game.android
      : ios;
  if (kIsWeb &&
      defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.android) {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Play ${game.title}',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            ListTile(
              leading: const Icon(Icons.apple),
              title: const Text('App Store'),
              onTap: () => Navigator.pop(ctx, ios ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.android),
              title: const Text('Google Play'),
              onTap: () => Navigator.pop(ctx, game.android),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    url = choice;
  }
  if (url == null || url.isEmpty) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Maze Words is coming soon'),
          content: const Text(
            'The App Store download link will be available when Maze Words is published.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    return;
  }
  try {
    if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (_) {
    /* Give the player a visible retry path. */
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The store could not open. Please try again.'),
      ),
    );
  }
}

class FamilyGames extends StatelessWidget {
  const FamilyGames({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More little adventures',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
        const SizedBox(height: 4),
        const Text('Meet the Neurantra game family.'),
        const SizedBox(height: 16),
        for (final game in FamilyGame.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => openFamilyGame(context, game),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(game.image, width: 64, height: 64),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Play ${game.title}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: purple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              game.description,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: purple),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const Text(
          'Your next favorite might be just a tap away.',
          style: TextStyle(fontSize: 12, color: purple),
        ),
      ],
    ),
  );
}
