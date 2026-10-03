import 'dart:math';
import 'package:flutter/material.dart';
import '../services/preferences.dart';
import 'toy_box.dart';

Future<bool> grownUpGate(BuildContext context) async {
  final random = Random();
  final a = 12 + random.nextInt(18), b = 3 + random.nextInt(7);
  final controller = TextEditingController();
  String? error;
  final passed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('A little grown-up check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please ask a grown-up: what is $a × $b?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Answer',
                errorText: error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (int.tryParse(controller.text) == a * b) {
                Navigator.pop(context, true);
              } else {
                setState(() => error = 'Try that one again.');
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    ),
  );
  // The dialog route may animate out while the field still owns its controller.
  await Future<void>.delayed(const Duration(milliseconds: 250));
  controller.dispose();
  return passed ?? false;
}

Future<void> editAge(
  BuildContext context,
  Preferences preferences, {
  bool first = false,
}) async {
  if (!first && !await grownUpGate(context)) return;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: !first,
    builder: (context) => _AgeDialog(preferences: preferences, first: first),
  );
}

class _AgeDialog extends StatefulWidget {
  const _AgeDialog({required this.preferences, required this.first});
  final Preferences preferences;
  final bool first;
  @override
  State<_AgeDialog> createState() => _AgeDialogState();
}

class _AgeDialogState extends State<_AgeDialog> {
  late final controller = TextEditingController(
    text: widget.preferences.year?.toString() ?? '',
  );
  String? error;
  bool busy = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save({bool skip = false}) async {
    final year = int.tryParse(controller.text);
    if (!skip && (year == null || year < 1900 || year > DateTime.now().year)) {
      setState(() => error = 'Please enter a valid birth year.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.preferences.saveYear(skip ? null : year);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Could not save. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.first && !busy,
    child: AlertDialog(
      title: Text(widget.first ? 'A little about you' : 'Age information'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What year were you born? Your year stays on this device. Younger players play without ads.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              enabled: !busy,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Birth year',
                hintText: 'YYYY',
                errorText: error,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Every puzzle is free to play.',
              style: TextStyle(color: teal, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy
              ? null
              : () => widget.first ? save(skip: true) : Navigator.pop(context),
          child: Text(widget.first ? 'Play without sharing' : 'Cancel'),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}
