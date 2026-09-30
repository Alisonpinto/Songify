import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jiosaavn/jiosaavn.dart' show PlaylistRequest;
import 'package:provider/provider.dart';
import 'package:songify_flutter/models/search_type.dart';
import 'package:songify_flutter/utils/debouncer.dart';
import 'package:songify_flutter/widgets/input/search_text_field.dart';
import 'package:songify_flutter/widgets/input/search_type_chip.dart';
import 'package:songify_flutter/widgets/track_list_tile.dart';

import '../models/track.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/add_to_album_sheet.dart';
import '../widgets/procedural_album_art.dart';
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

  SearchType _searchType = SearchType.all;

  bool _isLoading = false;
  late final Debouncer<String> _searchDebouncer = Debouncer(const Duration(milliseconds: 500), (prev, next) {
    if (mounted && prev?.trim() != next.trim()) {
      _performSearch(next);
    }
  },);

  @override
  void dispose() {
    _searchController.dispose();
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
      switch (_searchType) {
        case SearchType.all:
          final results = await Future.wait([state.searchOnline(query), state.searchPlaylistsOnline(query)]);
          if (mounted) {
            setState(() {
              _searchResults = results[0] as List<Track>;
              _playlistResults = results[1] as List<PlaylistRequest>;
              _isLoading = false;
            });
          }
        case SearchType.songs:
          final results = await state.searchOnline(query);
          if (mounted) {
            setState(() {
              _searchResults = results;
              _playlistResults = [];
              _isLoading = false;
            });
          }
        case SearchType.playlists:
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () {
                state.clearRecentSearches();
              },
              child: const Text(
                "Clear All",
                style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
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
                leading: TrackThumbnail(track: track, isPlaying: isPlaying, size: 48),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
          ..._searchResults.map((track) {
            final isPlaying = state.currentTrack.id == track.id && state.isPlaying;

            return TrackListTile(
              track: track,
              playing: isPlaying,
              onAddToPlaylist: () => _onAddTrackToAlbum(state, track),
              onPressed: () => _onTrackPressed(state, track),
              onLongPressed: () => _onAddTrackToAlbum(state, track),
            );
          }),
        ],
        if (_playlistResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 24.0, bottom: 12.0),
            child: Text(
              "JioSaavn Playlists",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
          // TODO(Yuki): replace once playlists work
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
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
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
                const Padding(padding: EdgeInsets.fromLTRB(0, 24, 0, 16), child: _Title()),
                SearchTextField(
                  searchController: _searchController,
                  searchType: _searchType,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          onPressed: _onRemoveSearch,
                        )
                      : null,
                  onSubmitted: _performSearch,
                  onChanged: _onSearch,
                ),
                const SizedBox(height: 12),
                Row(
                  spacing: 8,
                  children: [
                    ...SearchType.values.map((e) {
                      return SearchTypeChip(
                        searchType: e,
                        selected: _searchType == e,
                        onSelected: _onSearchTypeChanged,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                      : (_searchController.text.trim().isEmpty && state.recentSearches.isNotEmpty)
                      ? _buildRecentSearchesSection(context, state)
                      : _searchType == SearchType.all
                      ? _buildUnifiedSearchResults(state)
                      : _searchType == SearchType.songs
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

                                  return TrackListTile(
                                    track: track,
                                    playing: isPlaying,
                                    onAddToPlaylist: () => _onAddTrackToAlbum(state, track),
                                    onPressed: () => _onTrackPressed(state, track),
                                    onLongPressed: () => _onAddTrackToAlbum(state, track),
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
                                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
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

  void _onTrackPressed(AppState state, Track track) {
    state.addToRecentSearches(track);
    state.addTrackAndPlay(track);
  }

  void _onAddTrackToAlbum(AppState state, Track track) {
    showAddToAlbumSheet(context, track, state);
  }

  void _onSearchTypeChanged(SearchType type, bool selected) {
    if (selected && _searchType != type) {
      setState(() {
        _searchType = type;
        _performSearch(_searchController.text);
      });
    }
  }

  void _onRemoveSearch() {
    _searchController.clear();
    _performSearch("");
  }

  void _onSearch(String value) {
    setState(() {}); // Update suffix icon

    _searchDebouncer.debounce(value);
  }
}

class _Title extends StatelessWidget {
  const _Title({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "Discover",
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
    );
  }
}
