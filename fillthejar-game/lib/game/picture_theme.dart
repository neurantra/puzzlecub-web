/// Bundled catalog: packs grant access; pictures are unlocked separately.
class PicturePack {
  final String id, title, cover;
  final int coins;
  const PicturePack(this.id, this.title, this.cover, {this.coins = 30});
  static const catalog = [
    PicturePack('animals', 'Animals', 'assets/pictures/fox.png'),
    PicturePack('landscapes', 'Landscapes', 'assets/pictures/alpine-lake.png'),
    PicturePack('vehicles', 'Vehicles', 'assets/pictures/vintage-train.png'),
  ];
  List<PictureTheme> get pictures =>
      PictureTheme.catalog.where((p) => p.packId == id).toList();
  static PicturePack? find(String? id) {
    for (final pack in catalog) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}

class PictureTheme {
  final String id, title, asset, packId;
  final int coins;
  const PictureTheme({
    required this.id,
    required this.title,
    required this.asset,
    required this.packId,
    this.coins = 60,
  });

  static const catalog = [
    PictureTheme(
      id: 'woodland-fox',
      title: 'Woodland Fox',
      packId: 'animals',
      asset: 'assets/pictures/fox.png',
    ),
    PictureTheme(
      id: 'tiger',
      title: 'Tiger',
      packId: 'animals',
      asset: 'assets/pictures/tiger.png',
    ),
    PictureTheme(
      id: 'polar-bear',
      title: 'Polar Bear',
      packId: 'animals',
      asset: 'assets/pictures/polar-bear.png',
    ),
    PictureTheme(
      id: 'bald-eagle',
      title: 'Bald Eagle',
      packId: 'animals',
      asset: 'assets/pictures/bald-eagle.png',
    ),
    PictureTheme(
      id: 'zebra',
      title: 'Zebra',
      packId: 'animals',
      asset: 'assets/pictures/zebra.png',
    ),
    PictureTheme(
      id: 'giant-panda',
      title: 'Bamboo Panda',
      packId: 'animals',
      asset: 'assets/pictures/giant-panda.png',
    ),
    PictureTheme(
      id: 'snow-leopard',
      title: 'Snow Leopard',
      packId: 'animals',
      asset: 'assets/pictures/snow-leopard.png',
    ),
    PictureTheme(
      id: 'savanna-elephant',
      title: 'Savanna Elephant',
      packId: 'animals',
      asset: 'assets/pictures/savanna-elephant.png',
    ),
    PictureTheme(
      id: 'reef-turtle',
      title: 'Reef Turtle',
      packId: 'animals',
      asset: 'assets/pictures/reef-turtle.png',
    ),
    PictureTheme(
      id: 'peacock-garden',
      title: 'Peacock Garden',
      packId: 'animals',
      asset: 'assets/pictures/peacock-garden.png',
    ),
    PictureTheme(
      id: 'alpine-lake',
      title: 'Alpine Lake',
      packId: 'landscapes',
      asset: 'assets/pictures/alpine-lake.png',
    ),
    PictureTheme(
      id: 'sunset-coast',
      title: 'Sunset Coast',
      packId: 'landscapes',
      asset: 'assets/pictures/sunset-coast.png',
    ),
    PictureTheme(
      id: 'lavender-hills',
      title: 'Lavender Hills',
      packId: 'landscapes',
      asset: 'assets/pictures/lavender-hills.png',
    ),
    PictureTheme(
      id: 'desert-oasis',
      title: 'Desert Oasis',
      packId: 'landscapes',
      asset: 'assets/pictures/desert-oasis.png',
    ),
    PictureTheme(
      id: 'forest-waterfall',
      title: 'Forest Waterfall',
      packId: 'landscapes',
      asset: 'assets/pictures/forest-waterfall.png',
    ),
    PictureTheme(
      id: 'northern-lights',
      title: 'Northern Lights',
      packId: 'landscapes',
      asset: 'assets/pictures/northern-lights.png',
    ),
    PictureTheme(
      id: 'autumn-valley',
      title: 'Autumn Valley',
      packId: 'landscapes',
      asset: 'assets/pictures/autumn-valley.png',
    ),
    PictureTheme(
      id: 'blossom-garden',
      title: 'Blossom Garden',
      packId: 'landscapes',
      asset: 'assets/pictures/blossom-garden.png',
    ),
    PictureTheme(
      id: 'tropical-island',
      title: 'Tropical Island',
      packId: 'landscapes',
      asset: 'assets/pictures/tropical-island.png',
    ),
    PictureTheme(
      id: 'snowy-village',
      title: 'Snowy Village',
      packId: 'landscapes',
      asset: 'assets/pictures/snowy-village.png',
    ),
    PictureTheme(
      id: 'vintage-train',
      title: 'Vintage Train',
      packId: 'vehicles',
      asset: 'assets/pictures/vintage-train.png',
    ),
    PictureTheme(
      id: 'red-roadster',
      title: 'Red Roadster',
      packId: 'vehicles',
      asset: 'assets/pictures/red-roadster.png',
    ),
    PictureTheme(
      id: 'harbor-sailboat',
      title: 'Harbor Sailboat',
      packId: 'vehicles',
      asset: 'assets/pictures/harbor-sailboat.png',
    ),
    PictureTheme(
      id: 'golden-biplane',
      title: 'Golden Biplane',
      packId: 'vehicles',
      asset: 'assets/pictures/golden-biplane.png',
    ),
    PictureTheme(
      id: 'country-tractor',
      title: 'Country Tractor',
      packId: 'vehicles',
      asset: 'assets/pictures/country-tractor.png',
    ),
    PictureTheme(
      id: 'coastal-bus',
      title: 'Coastal Bus',
      packId: 'vehicles',
      asset: 'assets/pictures/coastal-bus.png',
    ),
    PictureTheme(
      id: 'red-fire-engine',
      title: 'Red Fire Engine',
      packId: 'vehicles',
      asset: 'assets/pictures/red-fire-engine.png',
    ),
    PictureTheme(
      id: 'lunar-rover',
      title: 'Lunar Rover',
      packId: 'vehicles',
      asset: 'assets/pictures/lunar-rover.png',
    ),
    PictureTheme(
      id: 'yellow-excavator',
      title: 'Yellow Excavator',
      packId: 'vehicles',
      asset: 'assets/pictures/yellow-excavator.png',
    ),
    PictureTheme(
      id: 'classic-motorcycle',
      title: 'Classic Motorcycle',
      packId: 'vehicles',
      asset: 'assets/pictures/classic-motorcycle.png',
    ),
  ];
  static PictureTheme? find(String? id) {
    for (final theme in catalog) {
      if (theme.id == id) return theme;
    }
    return null;
  }
}
