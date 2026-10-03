import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapopia/services/atlas_commerce.dart';
import 'package:mapopia/services/atlas_ads.dart';
import 'package:mapopia/geo/domain/geo_region.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'test unlock bypasses an exhausted trial without granting or consuming ownership',
    () async {
      final trial = jsonEncode({
        'region': 'india',
        'pieces': ['a', 'b'],
        'limit': 2,
      });
      SharedPreferences.setMockInitialValues({
        'mapTrial': trial,
        'fullAtlas': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final commerce = AtlasCommerce(prefs);
      final ads = AtlasAds(commerce);
      expect(commerce.trialExhausted, true);
      expect(commerce.fullAtlas, AtlasCommerce.testUnlock);
      for (final region in GeoRegion.values) {
        expect(
          commerce.canPlace(region, 20, 50),
          AtlasCommerce.testUnlock || region == GeoRegion.australia,
        );
      }
      if (AtlasCommerce.testUnlock) {
        ads.ready = true;
        expect(ads.eligible, false);
        await commerce.recordTrialProgress(GeoRegion.usa, {'new'}, 50);
        await commerce.recordTrialProgress(GeoRegion.india, {'new'}, 50);
      }
      expect(prefs.getString('mapTrial'), trial);
      expect(prefs.getBool('fullAtlas'), false);
      ads.dispose();
      commerce.dispose();
    },
  );
}
