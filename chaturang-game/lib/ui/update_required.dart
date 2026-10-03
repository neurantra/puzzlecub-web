import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_info.dart';
import '../data/release_policy.dart';

class UpdateRequired extends StatelessWidget {
  const UpdateRequired({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update, size: 56),
              const SizedBox(height: 24),
              Text(
                'A new version awaits',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'You’re using Chaturang v${AppInfo.versionName}. Please download the latest version to continue playing and enjoy the latest improvements. Your purchases remain yours.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final link = defaultTargetPlatform == TargetPlatform.iOS
                      ? StoreLinks.iosAppStore
                      : StoreLinks.androidPlayStore;
                  if (!await launchUrl(
                        Uri.parse(link),
                        mode: LaunchMode.externalApplication,
                      ) &&
                      context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Open your app store and search for Chaturang to update.',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Update Chaturang'),
              ),
              TextButton(
                onPressed: () => ReleasePolicy.instance.refresh(force: true),
                child: const Text('Check again'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
