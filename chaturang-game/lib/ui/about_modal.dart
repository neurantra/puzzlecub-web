import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_info.dart';
import 'theme.dart';

/// Opens a bottom-sheet modal with app info: description, developer credit,
/// links to web / privacy / terms. Mirrors the Sumquest About modal pattern.
Future<void> showAboutSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ChaturangTheme.deepMaroon,
    // With the Invite / Rate / More-from-Neurantra rows added in 1.0.2,
    // the modal exceeds the default half-screen cap on smaller iPhones
    // (was visibly clipped in TestFlight). Same fix as the Stats modal:
    // scroll-controlled + a SingleChildScrollView so content can grow
    // and scroll if needed.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              const SizedBox(height: 12),
              Text(
                'About Chaturang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'RoyalSans',
                  color: ChaturangTheme.saffronLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chaturang is an 8th-century Indian game widely considered '
                'the earliest known form of chess. Pieces are weaker, there '
                'is no castling, and the King has a once-per-game special '
                'leap.',
                style: TextStyle(
                  color: ChaturangTheme.secondaryText,
                  fontSize: 14,
                  fontFamily: 'RoyalSans',
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Made with ♥ by Neurantra',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'RoyalSans',
                  color: ChaturangTheme.secondaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _ActionRow(
                icon: Icons.share_outlined,
                label: 'Invite Friends',
                onTap: _shareInvite,
              ),
              _ActionRow(
                icon: Icons.info_outline,
                label: 'Licenses',
                onTap: (context) async {
                  showLicensePage(
                    context: context,
                    applicationName: 'Chaturang for PuzzleCub',
                  );
                },
              ),
              const _LinkRow(
                icon: Icons.apps,
                label: 'More from Neurantra',
                url: StoreLinks.neurantraSite,
              ),
              const Divider(
                color: Color(0x33FFFFFF),
                height: 24,
                thickness: 0.5,
              ),
              const _LinkRow(
                icon: Icons.public,
                label: 'neurantra.com',
                url: 'https://neurantra.com',
              ),
              const _LinkRow(
                icon: Icons.lock_outline,
                label: 'Privacy Policy',
                url: 'https://puzzlecub.com/privacy',
              ),
              const _LinkRow(
                icon: Icons.description_outlined,
                label: 'Terms of Use',
                url: 'https://puzzlecub.com/terms',
              ),
              const SizedBox(height: 12),
              Text(
                'Version ${AppInfo.versionDisplay}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ChaturangTheme.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: ChaturangTheme.parchment.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Opens the OS share sheet with an invite message + both store links.
/// Includes both Play Store and App Store links so the message works
/// for any recipient regardless of platform — no smart-link service or
/// landing page needed.
///
/// On iPad the share sheet renders as a popover that needs an anchor
/// [Rect] (`sharePositionOrigin`) — without it, the underlying
/// `share_plus` asserts and the sheet never appears. Compute the rect
/// from the tapped row's render box so it points back at the source.
Future<void> _shareInvite(BuildContext context) async {
  const text =
      "I'm playing Chaturang — the 8th-century Indian ancestor of chess. "
      'Try it!\n\n'
      'Play free against AI: https://puzzlecub.com/chaturang';
  final box = context.findRenderObject() as RenderBox?;
  final origin = (box != null && box.hasSize)
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
  await Share.share(
    text,
    subject: 'Play Chaturang on PuzzleCub',
    sharePositionOrigin: origin,
  );
}

/// Row that fires an action (vs. opening a URL — that's [_LinkRow]).
/// Visually mirrors [_LinkRow] so the rows feel uniform, but ends with
/// a forward-chevron rather than the open-in-new icon to hint that the
/// tap stays in-app (or hands off to a system sheet).
///
/// [onTap] receives the row's [BuildContext] so callers can derive an
/// anchor rect for things like iPad share-sheet popovers.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function(BuildContext context) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: ChaturangTheme.saffronLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'RoyalSans',
                  color: ChaturangTheme.parchment,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: ChaturangTheme.parchment,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.label, required this.url});

  final IconData icon;
  final String label;
  final String url;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: ChaturangTheme.saffronLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'RoyalSans',
                  color: ChaturangTheme.parchment,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new,
              color: ChaturangTheme.parchment,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
