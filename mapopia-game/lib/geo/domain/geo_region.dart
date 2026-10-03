// Region catalog extracted from Puzzlecub. Mapopia owns its play rules.

/// The assemblable regions. Each maps to a generated asset pack at
/// `assets/geo/<id>.json`, built by `tools/build-geo-packs.mjs`.
enum GeoRegion {
  usa,
  europe,
  southAmerica,
  africa,
  asia,
  oceania,
  world,
  india,
  brazil,
  canada,
  australia,
  mexico,
  germany,
  japan,
  uk,
  china,
  indonesia,
  argentina,
}

/// Asset-file stem for a region — `assets/geo/<id>.json`.
String geoRegionAssetId(GeoRegion region) => switch (region) {
  GeoRegion.usa => 'usa',
  GeoRegion.europe => 'europe',
  GeoRegion.southAmerica => 'southAmerica',
  GeoRegion.africa => 'africa',
  GeoRegion.asia => 'asia',
  GeoRegion.oceania => 'oceania',
  GeoRegion.world => 'world',
  GeoRegion.india => 'india',
  GeoRegion.brazil => 'brazil',
  GeoRegion.canada => 'canada',
  GeoRegion.australia => 'australia',
  GeoRegion.mexico => 'mexico',
  GeoRegion.germany => 'germany',
  GeoRegion.japan => 'japan',
  GeoRegion.uk => 'uk',
  GeoRegion.china => 'china',
  GeoRegion.indonesia => 'indonesia',
  GeoRegion.argentina => 'argentina',
};

/// Full display name (setup header, results sub-tag).
String geoRegionLabel(GeoRegion region) => switch (region) {
  GeoRegion.usa => 'United States',
  GeoRegion.europe => 'Europe',
  GeoRegion.southAmerica => 'South America',
  GeoRegion.africa => 'Africa',
  GeoRegion.asia => 'Asia',
  GeoRegion.oceania => 'Oceania',
  GeoRegion.world => 'World',
  GeoRegion.india => 'India',
  GeoRegion.brazil => 'Brazil',
  GeoRegion.canada => 'Canada',
  GeoRegion.australia => 'Australia',
  GeoRegion.mexico => 'Mexico',
  GeoRegion.germany => 'Germany',
  GeoRegion.japan => 'Japan',
  GeoRegion.uk => 'United Kingdom',
  GeoRegion.china => 'China',
  GeoRegion.indonesia => 'Indonesia',
  GeoRegion.argentina => 'Argentina',
};

/// Short label for setup chips and compact UI.
String geoRegionShortLabel(GeoRegion region) => switch (region) {
  GeoRegion.usa => 'USA',
  GeoRegion.europe => 'Europe',
  GeoRegion.southAmerica => 'S. America',
  GeoRegion.africa => 'Africa',
  GeoRegion.asia => 'Asia',
  GeoRegion.oceania => 'Oceania',
  GeoRegion.world => 'World',
  GeoRegion.india => 'India',
  GeoRegion.brazil => 'Brazil',
  GeoRegion.canada => 'Canada',
  GeoRegion.australia => 'Australia',
  GeoRegion.mexico => 'Mexico',
  GeoRegion.germany => 'Germany',
  GeoRegion.japan => 'Japan',
  GeoRegion.uk => 'UK',
  GeoRegion.china => 'China',
  GeoRegion.indonesia => 'Indonesia',
  GeoRegion.argentina => 'Argentina',
};

/// What each region's pieces are called, in plural form — naive `+ "s"`
/// pluralisation broke for "country"/"countries", so the helper just
/// returns the correct plural directly.
String geoRegionPieceNounPlural(GeoRegion region) => switch (region) {
  GeoRegion.usa => 'states',
  GeoRegion.europe => 'countries',
  GeoRegion.southAmerica => 'countries',
  GeoRegion.africa => 'countries',
  GeoRegion.asia => 'countries',
  GeoRegion.oceania => 'countries',
  GeoRegion.world => 'countries',
  GeoRegion.india => 'states',
  GeoRegion.brazil => 'states',
  GeoRegion.canada => 'provinces',
  GeoRegion.australia => 'states',
  GeoRegion.mexico => 'states',
  GeoRegion.germany => 'states',
  GeoRegion.japan => 'prefectures',
  GeoRegion.uk => 'countries',
  GeoRegion.china => 'provinces',
  GeoRegion.indonesia => 'provinces',
  GeoRegion.argentina => 'provinces',
};

/// Singular piece noun — used in in-round nudges ("Right state!").
String geoRegionPieceNoun(GeoRegion region) => switch (region) {
  GeoRegion.usa => 'state',
  GeoRegion.europe => 'country',
  GeoRegion.southAmerica => 'country',
  GeoRegion.africa => 'country',
  GeoRegion.asia => 'country',
  GeoRegion.oceania => 'country',
  GeoRegion.world => 'country',
  GeoRegion.india => 'state',
  GeoRegion.brazil => 'state',
  GeoRegion.canada => 'province',
  GeoRegion.australia => 'state',
  GeoRegion.mexico => 'state',
  GeoRegion.germany => 'state',
  GeoRegion.japan => 'prefecture',
  GeoRegion.uk => 'country',
  GeoRegion.china => 'province',
  GeoRegion.indonesia => 'province',
  GeoRegion.argentina => 'province',
};

/// Piece count for the setup screen. These match the actual pack
/// contents from `tools/build-geo-packs.mjs`; the play screen still
/// reads the authoritative count off the loaded `GeoPack`, but
/// keeping these accurate avoids the setup screen contradicting the
/// in-game count.
int geoRegionApproxPieces(GeoRegion region) => switch (region) {
  GeoRegion.usa => 50,
  GeoRegion.europe => 38,
  GeoRegion.southAmerica => 12,
  GeoRegion.africa => 51,
  GeoRegion.asia => 45,
  GeoRegion.oceania => 7,
  GeoRegion.world => 151,
  GeoRegion.india => 34,
  GeoRegion.brazil => 27,
  GeoRegion.canada => 13,
  GeoRegion.australia => 8,
  GeoRegion.mexico => 32,
  GeoRegion.germany => 16,
  GeoRegion.japan => 47,
  GeoRegion.uk => 4,
  GeoRegion.china => 31,
  GeoRegion.indonesia => 33,
  GeoRegion.argentina => 24,
};
