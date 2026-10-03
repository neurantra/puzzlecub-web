import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/services/ad_units.dart';
import 'widget_test.dart' show session;

void main() {
  test('interstitial cadence persists and ignores incomplete levels', () {
    final game = session();
    expect(game.recordCompletedTransition(), isFalse);
    expect(game.interstitialProgress, 0);
    game.complete = true;
    expect(game.recordCompletedTransition(), isFalse);
    expect(game.recordCompletedTransition(), isFalse);
    final restored = session()
      ..restore(game.encode())
      ..complete = true;
    expect(restored.recordCompletedTransition(), isFalse);
    expect(restored.recordCompletedTransition(), isTrue);
    expect(restored.interstitialProgress, 0);
    expect(restored.recordCompletedTransition(), isFalse);
  });
  test('interstitials use their own IDs and development stays on test ads', () {
    expect(
      AdUnits.interstitial(TargetPlatform.iOS, release: true),
      AdUnits.iosInterstitial,
    );
    expect(
      AdUnits.interstitial(TargetPlatform.iOS, release: false),
      'ca-app-pub-3940256099942544/4411468910',
    );
    expect(
      AdUnits.interstitial(TargetPlatform.android, release: true),
      AdUnits.androidInterstitial,
    );
    expect(
      AdUnits.interstitial(TargetPlatform.android, release: false),
      'ca-app-pub-3940256099942544/1033173712',
    );
  });
  test('native releases select their publisher rewarded units', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      for (final release in [false, true]) {
        final live = release;
        final publisher = platform == TargetPlatform.iOS
            ? AdUnits.iosRewarded
            : AdUnits.androidRewarded;
        final unit = AdUnits.rewarded(platform, release: release);
        expect(unit == publisher, live);
        expect(AdUnits.usesTestRewarded(platform, release: release), !live);
        expect(unit, isNot(AdUnits.iosInterstitial));
        expect(unit, isNot(AdUnits.androidInterstitial));
      }
    }
  });
}
