import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';
import '../widgets/mini_player.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;

  const AlbumDetailScreen({super.key, required this.albumName});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  List<Track> _recommendations = [];
  bool _isRecommendationsLoading = false;
  bool _didFetchRecommendations = false;
  int _lastTrackCount = -1;

  String _getGenreForTrack(Track track) {
    final genres = ['Pop', 'Rock', 'Lofi', 'Hip Hop', 'Romantic', 'Party', 'Classical'];
    final index = (track.title.hashCode + track.artist.hashCode).abs() % genres.length;
    return genres[index];
  }

  void _loadRecommendations(List<Track> playlistTracks) async {
    if (!mounted) return;
    setState(() {
      _isRecommendationsLoading = true;
    });

    final state = Provider.of<AppState>(context, listen: false);
    List<Track> finalRecommendations = [];

    // Check if album name or tracks match spiritual/devotional keywords
    final albumLower = widget.albumName.toLowerCase();
    
    // 1. Jesus / Christian topic check
    final jesusKeywords = ['jesus', 'christ', 'gospel', 'church', 'christian', 'worship', 'bible', 'prayer', 'hallelujah', 'lord', 'cross', 'amen'];
    bool isJesusTopic = jesusKeywords.any((keyword) => albumLower.contains(keyword));
    if (!isJesusTopic) {
      isJesusTopic = playlistTracks.any((t) => jesusKeywords.any((keyword) => t.title.toLowerCase().contains(keyword)));
    }

    // 2. Hindu / General Devotional topic check
    final devotionalKeywords = ['devotional', 'bhajan', 'krishna', 'rama', 'shiva', 'ganesha', 'durga', 'hanuman', 'stotra', 'aarti', 'mantra', 'spiritual', 'prarthana', 'god'];
    bool isDevotionalTopic = devotionalKeywords.any((keyword) => albumLower.contains(keyword));
    if (!isDevotionalTopic) {
      isDevotionalTopic = playlistTracks.any((t) => devotionalKeywords.any((keyword) => t.title.toLowerCase().contains(keyword)));
    }

    if (isJesusTopic) {
      try {
        // Query online for similar topic songs
        final searchResults = await state.searchOnline("popular christian worship jesus songs");
        finalRecommendations.addAll(searchResults);
      } catch (_) {}
    } else if (isDevotionalTopic) {
      try {
        final searchResults = await state.searchOnline("popular bhajan devotional songs");
        finalRecommendations.addAll(searchResults);
      } catch (_) {}
    }

    // A. Content-based fallback: Query songs by the same artists and genres from this playlist online!
    final Set<String> targetArtists = {};
    final Set<String> targetGenres = {};

    if (playlistTracks.isNotEmpty) {
      for (var t in playlistTracks) {
        if (t.artist.isNotEmpty && t.artist.toLowerCase() != 'unknown' && t.artist.toLowerCase() != 'unknown artist') {
          targetArtists.add(t.artist);
        }
        targetGenres.add(_getGenreForTrack(t));
      }
    } else {
      // If the playlist is empty, gather from the user's saved library tracks
      final libraryTracks = state.songsList;
      for (var t in libraryTracks) {
        if (t.artist.isNotEmpty && t.artist.toLowerCase() != 'unknown' && t.artist.toLowerCase() != 'unknown artist') {
          targetArtists.add(t.artist);
        }
        targetGenres.add(_getGenreForTrack(t));
      }
    }

    final artistsList = targetArtists.toList()..shuffle();
    final genresList = targetGenres.toList()..shuffle();

    // Fetch songs by artist online
    for (var artist in artistsList.take(2)) {
      try {
        final searchResults = await state.searchOnline(artist);
        for (var track in searchResults) {
          if (finalRecommendations.indexWhere((t) => t.title.toLowerCase() == track.title.toLowerCase()) == -1) {
            finalRecommendations.add(track);
          }
        }
      } catch (_) {}
    }

    // Fetch songs by genre online
    for (var genre in genresList.take(2)) {
      try {
        final searchResults = await state.searchOnline("$genre hits");
        for (var track in searchResults) {
          if (finalRecommendations.indexWhere((t) => t.title.toLowerCase() == track.title.toLowerCase()) == -1) {
            finalRecommendations.add(track);
          }
        }
      } catch (_) {}
    }

    // B. Also load standard collaborative recommendations for a seed track to blend them
    if (playlistTracks.isNotEmpty) {
      final seedTracks = List<Track>.from(playlistTracks)..shuffle();
      final querySeeds = seedTracks.take(2).toList();

      for (var seedTrack in querySeeds) {
        String seedId = '';
        if (seedTrack.youtubeId != null && seedTrack.youtubeId!.isNotEmpty) {
          seedId = seedTrack.youtubeId!;
        } else {
          try {
            final searchResults = await state.searchOnline(seedTrack.title);
            if (searchResults.isNotEmpty) {
              seedId = searchResults.first.youtubeId!;
            }
          } catch (_) {}
        }

        if (seedId.isNotEmpty) {
          try {
            final seedRecommendations = await state.getRecommendationsForSong(seedId);
            for (var track in seedRecommendations) {
              if (finalRecommendations.indexWhere((t) => t.title.toLowerCase() == track.title.toLowerCase()) == -1) {
                finalRecommendations.add(track);
              }
            }
          } catch (_) {}
        }
      }
    }

    // If still empty, fall back to general trending tracks
    if (finalRecommendations.isEmpty && state.trendingTracks.isNotEmpty) {
      finalRecommendations.addAll(state.trendingTracks);
    }

    // Filter out tracks that are already in this album
    final albumTrackTitles = playlistTracks.map((t) => t.title.toLowerCase()).toSet();
    finalRecommendations = finalRecommendations.where((t) => !albumTrackTitles.contains(t.title.toLowerCase())).toList();

    // Shuffle the final list a bit so it is fresh and distinct every time they load the page
    finalRecommendations.shuffle();

    if (mounted) {
      setState(() {
        _recommendations = finalRecommendations.take(15).toList();
        _isRecommendationsLoading = false;
        _didFetchRecommendations = true;
      });
    }
  }

  String _getRecommendationSubtitle(List<Track> playlistTracks) {
    final albumLower = widget.albumName.toLowerCase();
    final jesusKeywords = ['jesus', 'christ', 'gospel', 'church', 'christian', 'worship', 'bible', 'prayer', 'hallelujah', 'lord', 'cross', 'amen'];
    bool isJesus = jesusKeywords.any((keyword) => albumLower.contains(keyword)) ||
        playlistTracks.any((t) => jesusKeywords.any((keyword) => t.title.toLowerCase().contains(keyword)));
        
    if (isJesus) return "Recommended songs matching the Jesus/Christian topic";
    
    final devotionalKeywords = ['devotional', 'bhajan', 'krishna', 'rama', 'shiva', 'ganesha', 'durga', 'hanuman', 'stotra', 'aarti', 'mantra', 'spiritual', 'prarthana', 'god'];
    bool isDevotional = devotionalKeywords.any((keyword) => albumLower.contains(keyword)) ||
        playlistTracks.any((t) => devotionalKeywords.any((keyword) => t.title.toLowerCase().contains(keyword)));
        
    if (isDevotional) return "Recommended songs matching the devotional/spiritual topic";
    
    return "Based on songs in this album";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      bottomNavigationBar: const MiniPlayer(),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final tracks = state.getTracksForAlbum(widget.albumName);

          if ((!_didFetchRecommendations || _lastTrackCount != tracks.length) && !_isRecommendationsLoading) {
            _lastTrackCount = tracks.length;
            _didFetchRecommendations = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadRecommendations(tracks);
            });
          }

          final pattern = tracks.isNotEmpty ? tracks.first.pattern : 'vinyl';
          final color1 = tracks.isNotEmpty ? tracks.first.primaryColor : AppTheme.primaryYellow;
          final color2 = tracks.isNotEmpty ? tracks.first.secondaryColor : const Color(0xFFE91E63);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppTheme.darkBackground,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.darkCard,
                          title: const Text("Delete Album", style: TextStyle(color: Colors.white)),
                          content: Text("Are you sure you want to delete '${widget.albumName}'?", style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () {
                                Provider.of<AppState>(context, listen: false).deleteAlbum(widget.albumName);
                                Navigator.pop(context);
                                Navigator.pop(context); // Go back to library
                              },
                              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 16),
                  title: Text(
                    widget.albumName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      FittedBox(
                        fit: BoxFit.cover,
                        child: ProceduralAlbumArt(
                          pattern: pattern,
                          primaryColor: color1,
                          secondaryColor: color2,
                          size: 400,
                        ),
                      ),
                      // Gradient overlay to blend image into the background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppTheme.darkBackground.withValues(alpha: 0.6),
                              AppTheme.darkBackground,
                            ],
                            stops: const [0.5, 0.85, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}",
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: tracks.isNotEmpty ? () => state.shuffleQueue(tracks) : null,
                        icon: const Icon(Icons.shuffle_rounded, color: Colors.black),
                        label: const Text(
                          'Shuffle Play',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryYellow,
                          disabledBackgroundColor: AppTheme.primaryYellow.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (tracks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.album_rounded, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 16),
                        const Text(
                          "This album is empty.\nAdd songs from your library!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index];
                      final isPlaying = state.currentTrack.id == track.id && state.isPlaying;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
                        child: ListTile(
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
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.textSecondary),
                            onPressed: () {
                              state.removeTrackFromAlbum(track, widget.albumName);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed from ${widget.albumName}')),
                              );
                            },
                          ),
                          onTap: () {
                            state.playFromQueue(tracks, track);
                          },
                        ),
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
                
                // Recommendations Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Colors.white24, height: 32),
                        const Text(
                          "Recommended for You",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRecommendationSubtitle(tracks),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        if (_isRecommendationsLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0),
                            child: Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryYellow),
                            ),
                          )
                        else if (_recommendations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                "No recommendations available.",
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recommendations.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final track = _recommendations[index];
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
                                  icon: const Icon(Icons.add_rounded, color: AppTheme.primaryYellow),
                                  tooltip: "Add directly to this playlist",
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final success = await state.addTrackToAlbum(track, widget.albumName);
                                    if (success && mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Added to ${widget.albumName}')),
                                      );
                                      setState(() {
                                        _recommendations.removeAt(index);
                                      });
                                    }
                                  },
                                ),
                                onTap: () {
                                  state.addTrackAndPlay(track);
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
