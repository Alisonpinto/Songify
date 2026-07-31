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

  void _loadRecommendations(List<Track> playlistTracks) async {
    if (!mounted) return;
    setState(() {
      _isRecommendationsLoading = true;
    });

    final state = Provider.of<AppState>(context, listen: false);
    String seedId = '5WXAlMNt'; // default seed: BTS Dynamite
    
    final onlineTrack = playlistTracks.firstWhere(
      (t) => t.youtubeId != null && t.youtubeId!.isNotEmpty,
      orElse: () => Track(id: -1, title: "", artist: "", duration: "", pattern: "", primaryColor: Colors.grey, secondaryColor: Colors.black),
    );

    if (onlineTrack.id != -1) {
      seedId = onlineTrack.youtubeId!;
    } else if (playlistTracks.isNotEmpty) {
      try {
        final searchResults = await state.searchOnline(playlistTracks.first.title);
        if (searchResults.isNotEmpty) {
          seedId = searchResults.first.youtubeId!;
        }
      } catch (_) {}
    }

    final recommendations = await state.getRecommendationsForSong(seedId);
    
    if (mounted) {
      setState(() {
        _recommendations = recommendations;
        _isRecommendationsLoading = false;
        _didFetchRecommendations = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      bottomNavigationBar: const MiniPlayer(),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final tracks = state.getTracksForAlbum(widget.albumName);

          if (!_didFetchRecommendations && !_isRecommendationsLoading) {
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
                        const Text(
                          "Based on songs in this playlist",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
