import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Same conservative birth-year policy as the sibling games. The year never
// leaves this device. Unknown profiles can play with online services disabled.
bool protectedProfile(int? year, DateTime now, String country) {
  if (year == null || year < 1900 || year > now.year) return true;
  const europe = {
    'AT',
    'BE',
    'BG',
    'HR',
    'CY',
    'CZ',
    'DK',
    'EE',
    'FI',
    'FR',
    'DE',
    'GR',
    'HU',
    'IS',
    'IE',
    'IT',
    'LV',
    'LI',
    'LT',
    'LU',
    'MT',
    'NL',
    'NO',
    'PL',
    'PT',
    'RO',
    'SK',
    'SI',
    'ES',
    'SE',
  };
  final threshold = europe.contains(country.toUpperCase()) ? 16 : 13;
  return now.isBefore(DateTime(year + threshold, 12, 31));
}

class Preferences extends ChangeNotifier {
  Preferences(this.storage) {
    _year = storage.getInt('birthYear');
    _declared = storage.getBool('ageDeclared') ?? false;
    final profile = storage.getString('ageProfile');
    if (profile != null) {
      try {
        final decoded = jsonDecode(profile) as Map<String, dynamic>;
        _year = decoded['year'] as int?;
        _declared = decoded['declared'] == true;
      } catch (_) {
        _year = null;
        _declared = false;
      }
    }
  }
  int? _year;
  bool _declared = false;
  final SharedPreferences storage;
  int? get year => _year;
  bool get declared => _declared;
  bool get music => storage.getBool('music') ?? false;
  bool get sound => storage.getBool('sound') ?? true;
  bool get reducedMotion => storage.getBool('reducedMotion') ?? false;
  int get wins => storage.getInt('wins') ?? 0;
  bool get protected => protectedProfile(
    year,
    DateTime.now(),
    WidgetsBinding.instance.platformDispatcher.locale.countryCode ?? '',
  );
  Future<void> setFlag(String key, bool value) async {
    if (!await storage.setBool(key, value)) throw StateError('Could not save');
    notifyListeners();
  }

  Future<void> saveYear(int? value) async {
    if (value != null && (value < 1900 || value > DateTime.now().year)) {
      throw ArgumentError('Enter a valid year');
    }
    // Commit the declaration and year together; failed writes cannot enable ads.
    if (!await storage.setString(
      'ageProfile',
      jsonEncode({'year': value, 'declared': true}),
    )) {
      throw StateError('Could not save');
    }
    _year = value;
    _declared = true;
    notifyListeners();
  }

  Future<void> recordWin() async {
    if (!await storage.setInt('wins', wins + 1)) {
      throw StateError('Could not save');
    }
    notifyListeners();
  }

  void refreshAudience() => notifyListeners();
}
