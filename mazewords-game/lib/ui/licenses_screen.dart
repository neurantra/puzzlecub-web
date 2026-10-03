import 'package:flutter/material.dart';
import '../services/language_licenses.dart';

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Licenses')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Credits & acknowledgements',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thanks to the people who make our language data and software available. Tap a source for details.',
          ),
          const SizedBox(height: 20),
          for (final credit in languageCredits)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: Text(credit.title),
              subtitle: Text(credit.summary),
              children: [SelectionArea(child: Text(credit.details.trim()))],
            ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Software & fonts'),
            subtitle: const Text('Open-source license notices'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Maze Words',
            ),
          ),
        ],
      ),
    ),
  );
}
