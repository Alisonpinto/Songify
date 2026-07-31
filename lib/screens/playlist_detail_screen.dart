import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';
import '../widgets/mini_player.dart';
import '../widgets/add_to_album_sheet.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  final String playlistName;
  final String imageUrl;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
    required this.imageUrl,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Track> _tracks = [];
  bool _isLoading = true;
  List<Track> _recommendations = [];
  bool _isRecommendationsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  void _loadTracks() async {
    final state = Provider.of<AppState>(context, listen: false);
    final tracks = await state.getPlaylistTracks(widget.playlistId);
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
      _loadRecommendations(tracks);
    }
  }

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
          final color1 = _tracks.isNotEmpty ? _tracks.first.primaryColor : AppTheme.primaryYellow;
          final color2 = _tracks.isNotEmpty ? _tracks.first.secondaryColor : const Color(0xFFE91E63);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppTheme.darkBackground,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 16),
                  title: Text(
                    widget.playlistName,
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
                      widget.imageUrl.isNotEmpty
                          ? Image.network(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => FittedBox(
                                fit: BoxFit.cover,
                                child: ProceduralAlbumArt(
                                  pattern: 'grid',
                                  primaryColor: color1,
                                  secondaryColor: color2,
                                  size: 400,
                                ),
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.cover,
                              child: ProceduralAlbumArt(
                                pattern: 'grid',
                                primaryColor: color1,
                                secondaryColor: color2,
                                size: 400,
                              ),
                            ),
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
                        _isLoading
                            ? "Loading tracks..."
                            : "${_tracks.length} ${_tracks.length == 1 ? 'song' : 'songs'}",
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: (_isLoading || _tracks.isEmpty)
                            ? null
                            : () => state.shuffleQueue(_tracks),
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

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryYellow),
                  ),
                )
              else if (_tracks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "No songs found in this playlist.",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = _tracks[index];
                        final isPlaying = state.currentTrack.id == track.id && state.isPlaying;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
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
                              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
                              onPressed: () {
                                showAddToAlbumSheet(context, track, state);
                              },
                            ),
                            onTap: () {
                              state.addTrackAndPlay(track);
                            },
                            onLongPress: () {
                              showAddToAlbumSheet(context, track, state);
                            },
                          ),
                        );
                      },
                      childCount: _tracks.length,
                    ),
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
                                tooltip: "Add to Playlist",
                                onPressed: () {
                                  showAddToAlbumSheet(context, track, state);
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
