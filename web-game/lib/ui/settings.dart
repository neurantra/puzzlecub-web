import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/family_games.dart';

import 'style.dart';


Future<void> openSettings(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const SettingsScreen()));

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* Show a recoverable error below. */
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open this link. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Terms of use'),
          onTap: () => _open(context, Uri.parse('https://puzzlecub.com/terms')),
        ),
        ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Privacy policy'),
          onTap: () =>
              _open(context, Uri.parse('https://puzzlecub.com/privacy')),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About Alphadoku'),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const AlphadokuAboutScreen()),
          ),
        ),
        const Divider(height: 32),
        const Eyebrow('More games from Neurantra'),
        const SizedBox(height: 8),
        for (final game in FamilyGame.values)
          ListTile(
            title: Text(game.title),
            subtitle: Text(game.description),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _open(context, game.link(defaultTargetPlatform)),
          ),
      ],
    ),
  );
}

class AlphadokuAboutScreen extends StatelessWidget {
  const AlphadokuAboutScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About Alphadoku')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: AlphadokuMark(size: 80)),
        const SizedBox(height: 16),
        Text(
          'Alphadoku: Letter Sudoku',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text('Version 1.0.0 · Nine letters. One hidden line.'),
        const SizedBox(height: 12),
        const Text(
          'A letter Sudoku game by Neurantra. Solve at your pace, discover the hidden line, and explore four levels of challenge. Puzzles and the word library live on your device.',
        ),
        const SizedBox(height: 24),
        const Eyebrow('Built with open source'),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('App framework and device tools'),
          subtitle: Text(
            'Flutter, Dart, local storage and link-opening libraries.',
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Words and language resources'),
          subtitle: Text(
            'ESDB, WordNet and wordfreq support our reviewed word library.',
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Typography and icons'),
          subtitle: Text('Openly licensed fonts and Material icons.'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Purchases and advertising integrations'),
          subtitle: Text(
            'The web edition uses no billing SDK. Full dependency notices are available below.',
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.article_outlined),
          label: const Text('View all licenses and notices'),
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Alphadoku: Letter Sudoku',
            applicationVersion: '1.0.0',
          ),
        ),
      ],
    ),
  );
}
