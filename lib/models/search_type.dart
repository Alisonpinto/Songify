
enum SearchType {
  all,
  songs,
  playlists;

  const SearchType();

  String get hint {
    switch (this) {
      case SearchType.all:
        return "Search for songs and playlists...";
      case SearchType.songs:
        return "Search online for any song...";
      case SearchType.playlists:
        return "Search online for public playlists...";
    }
  }

  String get label {
    switch (this) {
      case SearchType.all:
        return "All";
      case SearchType.songs:
        return "Songs";
      case SearchType.playlists:
        return "Playlists";
    }
  }
}