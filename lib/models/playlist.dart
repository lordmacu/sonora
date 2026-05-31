class Playlist {
  final String id;
  final String name;
  final List<String> songIds;

  const Playlist({
    required this.id,
    required this.name,
    required this.songIds,
  });

  static const generalId = 'general';
  static const favoritesId = 'favorites';

  bool get isProtected => id == generalId || id == favoritesId;
}
