enum MazeTheme {
  hedge('Hedge garden', 'Leafy walls, sunlit paths'),
  stone('Ancient stone', 'Weathered rock and moss'),
  glass('Crystal glass', 'Icy edges and luminous reflections');

  const MazeTheme(this.label, this.description);
  final String label, description;
}
