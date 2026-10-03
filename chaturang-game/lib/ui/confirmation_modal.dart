import 'package:flutter/material.dart';

import 'theme.dart';

/// Shows a small confirmation modal with [title], [message], and two
/// buttons (cancel + confirm). Returns true if the user confirms.
///
/// Used for forfeit-flow confirmation: tapping Forfeit / Reset / Quit
/// during an active game routes through this prompt to make sure the
/// loss is intentional.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) {
      return AlertDialog(
        backgroundColor: ChaturangTheme.deepMaroon,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: ChaturangTheme.saffron.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'RoyalSans',
            color: ChaturangTheme.saffronLight,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ChaturangTheme.secondaryText,
            fontSize: 14,
            fontFamily: 'RoyalSans',
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: ChaturangTheme.parchment,
            ),
            child: Text(
              cancelLabel,
              style: TextStyle(
                fontFamily: 'RoyalSans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: destructive
                  ? ChaturangTheme.terracotta
                  : ChaturangTheme.saffronLight,
            ),
            child: Text(
              confirmLabel,
              style: TextStyle(
                fontFamily: 'RoyalSans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
