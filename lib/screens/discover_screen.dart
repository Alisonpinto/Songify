import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:jiosaavn/jiosaavn.dart' show PlaylistRequest;
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';
import '../widgets/add_to_album_sheet.dart';
import 'playlist_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Track> _searchResults = [];
  List<PlaylistRequest> _playlistResults = [];
  String _searchType = "all"; // "all", "songs", or "playlists"
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _playlistResults = [];
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    final state = Provider.of<AppState>(context, listen: false);
    
    try {
      if (_searchType == "all") {
        final results = await Future.wait([
          state.searchOnline(query),
          state.searchPlaylistsOnline(query),
        ]);
        if (mounted) {
          setState(() {
            _searchResults = results[0] as List<Track>;
            _playlistResults = results[1] as List<PlaylistRequest>;
            _isLoading = false;
          });
        }
      } else if (_searchType == "songs") {
        final results = await state.searchOnline(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _playlistResults = [];
            _isLoading = false;
          });
        }
      } else {
        final results = await state.searchPlaylistsOnline(query);
        if (mounted) {
          setState(() {
            _playlistResults = results;
            _searchResults = [];
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildRecentSearchesSection(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Searches",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                state.clearRecentSearches();
              },
              child: const Text(
                "Clear All",
                style: TextStyle(
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: state.recentSearches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final track = state.recentSearches[index];
              final isPlaying = state.currentTrack.id == track.id && state.isPlaying;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: TrackThumbnail(
                  track: track,
                  isPlaying: isPlaying,
                  size: 48,
                ),
                title: Text(
                  track.title,
                  style: TextStyle(
                    color: isPlaying ? AppTheme.primaryYellow : AppTheme.textPrimary,
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  track.artist,
                  style: const TextStyle(color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                      tooltip: "Search again",
                      onPressed: () {
                        _searchController.text = track.title;
                        _performSearch(track.title);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
                      tooltip: "Add to album",
                      onPressed: () {
                        showAddToAlbumSheet(context, track, state);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  state.addToRecentSearches(track);
                  state.addTrackAndPlay(track);
                },
                onLongPress: () {
                  showAddToAlbumSheet(context, track, state);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedSearchResults(AppState state) {
    if (_searchResults.isEmpty && _playlistResults.isEmpty) {
      return const Center(
        child: Text(
          "Search for songs and JioSaavn playlists online.",
          style: TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (_searchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              "Songs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          ..._searchResults.map((track) {
            final isPlaying = state.currentTrack.id == track.id && state.isPlaying;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: TrackThumbnail(
                track: track, 
                isPlaying: isPlaying,
                size: 48,
              ),
              title: Text(
                track.title,
                style: TextStyle(
                  color: isPlaying ? AppTheme.primaryYellow : AppTheme.textPrimary,
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                track.artist,
                style: const TextStyle(color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
                onPressed: () {
                  showAddToAlbumSheet(context, track, state);
                },
              ),
              onTap: () {
                state.addToRecentSearches(track);
                state.addTrackAndPlay(track);
              },
              onLongPress: () {
                showAddToAlbumSheet(context, track, state);
              },
            );
          }).toList(),
        ],
        if (_playlistResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 24.0, bottom: 12.0),
            child: Text(
              "JioSaavn Playlists",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          ..._playlistResults.map((playlist) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  playlist.image,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: AppTheme.darkCard,
                    child: const Icon(Icons.playlist_play_rounded, color: AppTheme.primaryYellow),
                  ),
                ),
              ),
              title: Text(
                playlist.listname,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "${playlist.firstname.isNotEmpty ? 'By ${playlist.firstname}' : 'JioSaavn Playlist'} • ${playlist.listCount.isNotEmpty ? playlist.listCount : playlist.count} songs",
                style: const TextStyle(color: AppTheme.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistDetailScreen(
                      playlistId: playlist.listid,
                      playlistName: playlist.listname,
                      imageUrl: playlist.image,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 16),
                  child: Text(
                    "Discover",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: _searchType == "all" ? "Search for songs and playlists..." : (_searchType == "songs" ? "Search online for any song..." : "Search online for public playlists..."),
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch("");
                          },
                        ) 
                      : null,
                    filled: true,
                    fillColor: AppTheme.darkSurface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppTheme.primaryYellow),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppTheme.primaryYellow),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2),
                    ),
                  ),
                  onSubmitted: _performSearch,
                  onChanged: (val) {
                    setState(() {}); // Update suffix icon
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      _performSearch(val);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("All"),
                      selected: _searchType == "all",
                      selectedColor: AppTheme.primaryYellow,
                      backgroundColor: AppTheme.darkCard,
                      labelStyle: TextStyle(
                        color: _searchType == "all" ? Colors.black : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _searchType = "all";
                            _performSearch(_searchController.text);
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Songs"),
                      selected: _searchType == "songs",
                      selectedColor: AppTheme.primaryYellow,
                      backgroundColor: AppTheme.darkCard,
                      labelStyle: TextStyle(
                        color: _searchType == "songs" ? Colors.black : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _searchType = "songs";
                            _performSearch(_searchController.text);
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Playlists"),
                      selected: _searchType == "playlists",
                      selectedColor: AppTheme.primaryYellow,
                      backgroundColor: AppTheme.darkCard,
                      labelStyle: TextStyle(
                        color: _searchType == "playlists" ? Colors.black : AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _searchType = "playlists";
                            _performSearch(_searchController.text);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                      : (_searchController.text.trim().isEmpty && state.recentSearches.isNotEmpty)
                          ? _buildRecentSearchesSection(context, state)
                          : _searchType == "all"
                              ? _buildUnifiedSearchResults(state)
                              : _searchType == "songs"
                                  ? _searchResults.isEmpty
                                      ? const Center(
                                          child: Text(
                                            "Search for tracks online completely ad-free.",
                                            style: TextStyle(color: AppTheme.textSecondary),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: _searchResults.length,
                                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final track = _searchResults[index];
                                            final isPlaying = state.currentTrack.id == track.id && state.isPlaying;

                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: TrackThumbnail(
                                                track: track, 
                                                isPlaying: isPlaying,
                                                size: 48,
                                              ),
                                              title: Text(
                                                track.title,
                                                style: TextStyle(
                                                  color: isPlaying ? AppTheme.primaryYellow : AppTheme.textPrimary,
                                                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Text(
                                                track.artist,
                                                style: const TextStyle(color: AppTheme.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
                                                onPressed: () {
                                                  showAddToAlbumSheet(context, track, state);
                                                },
                                              ),
                                              onTap: () {
                                                state.addToRecentSearches(track);
                                                state.addTrackAndPlay(track);
                                              },
                                              onLongPress: () {
                                                showAddToAlbumSheet(context, track, state);
                                              },
                                            );
                                          },
                                        )
                                  : _playlistResults.isEmpty
                                      ? const Center(
                                          child: Text(
                                            "Search for public playlists online.",
                                            style: TextStyle(color: AppTheme.textSecondary),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: _playlistResults.length,
                                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final playlist = _playlistResults[index];
                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  playlist.image,
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    width: 48,
                                                    height: 48,
                                                    color: AppTheme.darkCard,
                                                    child: const Icon(Icons.playlist_play_rounded, color: AppTheme.primaryYellow),
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                playlist.listname,
                                                style: const TextStyle(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Text(
                                                "${playlist.firstname.isNotEmpty ? 'By ${playlist.firstname}' : 'JioSaavn Playlist'} • ${playlist.listCount.isNotEmpty ? playlist.listCount : playlist.count} songs",
                                                style: const TextStyle(color: AppTheme.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => PlaylistDetailScreen(
                                                      playlistId: playlist.listid,
                                                      playlistName: playlist.listname,
                                                      imageUrl: playlist.image,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
