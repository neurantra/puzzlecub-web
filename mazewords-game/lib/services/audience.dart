import 'dart:ui' show PlatformDispatcher;

/// Local declaration, not verified age or parental consent.
/// This product policy matches Puzzlecub's locale-based 13/16 tiers;
/// device locale is a heuristic, not proof of jurisdiction.
class Audience {
  final int? birthYear;
  final int? _currentYear;
  final String? _countryCode;
  // Public test overrides keep policy tests independent of device locale/time.
  Audience(this.birthYear, {int? currentYear, String? countryCode})
    // ignore: prefer_initializing_formals
    : _currentYear = currentYear,
      // ignore: prefer_initializing_formals
      _countryCode = countryCode;
  int get currentYear => _currentYear ?? DateTime.now().year;
  bool get answered =>
      birthYear != null && birthYear! >= 1900 && birthYear! <= currentYear;
  int get cutoff =>
      euEea.contains(
        (_countryCode ?? PlatformDispatcher.instance.locale.countryCode ?? '')
            .toUpperCase(),
      )
      ? 16
      : 13;
  // Assume December 31 when only the year is known; never age up early.
  bool get externalServicesAllowed =>
      answered && currentYear - birthYear! - 1 >= cutoff;
  static const euEea = {
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
    'IE',
    'IT',
    'LV',
    'LT',
    'LU',
    'MT',
    'NL',
    'PL',
    'PT',
    'RO',
    'SK',
    'SI',
    'ES',
    'SE',
    'IS',
    'LI',
    'NO',
  };
}
