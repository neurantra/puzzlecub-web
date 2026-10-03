import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/family_games.dart';
import 'age.dart';
import 'toy_box.dart';

Future<void> openFamilyLink(BuildContext context, Uri uri) async {
  if (!await grownUpGate(context) || !context.mounted) return;
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    /* Keep the game available if the store/browser cannot open. */
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the link. Please try again.'),
      ),
    );
  }
}

Future<void> showAppInformation(
  BuildContext context,
  String section,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(
      section == 'about'
          ? 'About Slide & Sort'
          : section == 'privacy'
          ? 'Privacy'
          : 'Terms',
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section == 'about') ...[
            const Center(child: Pip(size: 84)),
            const Text(
              'Little slides. Big smiles.\nVersion 1.0.0 · Build 1\nMade by Neurantra LLC.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Three cheerful sliding puzzles: alphabets, number patterns, and counting from 1 to 29. Play solo or race Pip. No purchases or subscriptions.',
            ),
            // TextButton(
            //  onPressed: () => showLicensePage(
            //     context: context,
            //    applicationName: 'Slide & Sort',
            //    applicationVersion: '1.0.0',
            //   ),
            //  child: const Text('Open-source licenses'),
            // ),
          ] else if (section == 'privacy') ...[
            const Text(
              'Your birth year, settings, and happy finishes stay on this device. No account, cloud vault, or analytics is used.\n\nProtected and unknown-age profiles do not request ads. For eligible older players, Google AdMob handles consent and may process advertising and device data. Required ad privacy choices are available in Settings.\n\nLinks to other games and websites require a grown-up check.',
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => openFamilyLink(
                context,
                Uri.parse('https://neurantra.com/privacy'),
              ),
              child: const Text('Read Neurantra privacy policy'),
            ),
          ] else ...[
            const Text(
              'Slide & Sort is provided by Neurantra LLC. The game is free to play with no in-app purchases. Please read our full terms of service for the terms that govern use of the app.',
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => openFamilyLink(
                context,
                Uri.parse('https://neurantra.com/terms'),
              ),
              child: const Text('Read full terms'),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Done'),
      ),
    ],
  ),
);

class FamilyGamesPanel extends StatelessWidget {
  const FamilyGamesPanel({super.key});
  @override
  Widget build(BuildContext context) => PaperCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More from Neurantra',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'More little adventures',
          style: TextStyle(fontSize: 11, color: teal),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final game in FamilyGame.values)
              OutlinedButton(
                onPressed: () =>
                    openFamilyLink(context, game.link(defaultTargetPlatform)),
                child: Text(game.title),
              ),
          ],
        ),
      ],
    ),
  );
}
