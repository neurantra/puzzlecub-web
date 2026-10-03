import 'dart:math';
import 'package:flutter/material.dart';

Future<bool> ageParentGate(
  BuildContext context, {
  String explanation = 'To correct age information, please solve this first.',
}) async {
  final random = Random.secure();
  final a = 12 + random.nextInt(18), b = 3 + random.nextInt(7);
  return await showDialog<bool>(
        context: context,
        builder: (context) => _ParentGate(a: a, b: b, explanation: explanation),
      ) ??
      false;
}

class _ParentGate extends StatefulWidget {
  const _ParentGate({
    required this.a,
    required this.b,
    required this.explanation,
  });
  final String explanation;
  final int a, b;
  @override
  State<_ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<_ParentGate> {
  String answer = '';
  bool wrong = false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('For parents and grown-ups'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.explanation),
        Text('${widget.a} × ${widget.b} = ?'),
        TextField(
          key: const ValueKey('parent-answer'),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Answer',
            errorText: wrong ? 'Please try again.' : null,
          ),
          onChanged: (value) => answer = value,
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
          if (int.tryParse(answer.trim()) == widget.a * widget.b) {
            Navigator.pop(context, true);
          } else {
            setState(() => wrong = true);
          }
        },
        child: const Text('Continue'),
      ),
    ],
  );
}

Future<bool> showAgeInformation(
  BuildContext context, {
  int? birthYear,
  bool required = false,
  required Future<void> Function(int) save,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AgeInformation(
        birthYear: birthYear,
        requiredAnswer: required,
        save: save,
      ),
    ) ??
    false;

class _AgeInformation extends StatefulWidget {
  const _AgeInformation({
    this.birthYear,
    required this.requiredAnswer,
    required this.save,
  });
  final int? birthYear;
  final bool requiredAnswer;
  final Future<void> Function(int) save;
  @override
  State<_AgeInformation> createState() => _AgeInformationState();
}

class _AgeInformationState extends State<_AgeInformation> {
  late int? year = widget.birthYear;
  bool saving = false;
  String? error;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.requiredAnswer && !saving,
    child: AlertDialog(
      title: const Text('Age information'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose the player’s year of birth. It stays on this device and helps set up ads and online features. Every puzzle is available to everyone.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const ValueKey('birth-year'),
              initialValue: year,
              isExpanded: true,
              menuMaxHeight: 280,
              decoration: const InputDecoration(labelText: 'Year of birth'),
              items: [
                for (var y = DateTime.now().year; y >= 1900; y--)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: saving
                  ? null
                  : (value) => setState(() => year = value),
            ),
            const SizedBox(height: 12),
            const Text(
              'Younger profiles have no ads, shared coin transfers, crash reporting, or game promotions. A parent or grown-up can correct this answer in Settings. Coins and progress are kept.',
            ),
            if (error != null) Text(error!),
          ],
        ),
      ),
      actions: [
        if (!widget.requiredAnswer)
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        FilledButton(
          onPressed: year == null || saving
              ? null
              : () async {
                  setState(() {
                    saving = true;
                    error = null;
                  });
                  try {
                    await widget.save(year!);
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (_) {
                    if (mounted) {
                      setState(() {
                        saving = false;
                        error = 'Could not save. Please try again.';
                      });
                    }
                  }
                },
          child: Text(saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}
