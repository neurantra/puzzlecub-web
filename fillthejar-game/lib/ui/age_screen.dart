import 'app_icon.dart';
import 'package:flutter/material.dart';
import '../services/audience.dart';
import '../services/services.dart';

class AgeScreen extends StatefulWidget {
  final SaveStore? store;
  final ValueChanged<Audience> onSaved;
  const AgeScreen({super.key, this.store, required this.onSaved});
  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  int? _year;
  bool _saving = false;
  String? _error;
  Future<void> _save() async {
    if (_year == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.store != null &&
          !await widget.store!.prefs.setInt(Audience.key, _year!)) {
        throw StateError('Could not save');
      }
      if (mounted) widget.onSaved(Audience(_year));
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Your answer could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const JarAppIcon(size: 76),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Fill the Jar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                const Text(
                  'To set up the right experience for you, please choose your year of birth.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  key: const ValueKey('birth-year'),
                  decoration: const InputDecoration(
                    labelText: 'Year of birth',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  menuMaxHeight: 300,
                  items: [
                    for (var year = DateTime.now().year; year >= 1900; year--)
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _year = value),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _year == null || _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Continue'),
                ),
                if (_error != null) Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                const Text(
                  'Your answer stays on this device. It helps us tailor ads and online features. Every puzzle is available to everyone. Younger profiles have no ads or shared transfers. A parent or grown-up can correct this answer in Settings → Age information.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
