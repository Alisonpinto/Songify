import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';
import '../widgets/mini_player.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;

  const AlbumDetailScreen({super.key, required this.albumName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      bottomNavigationBar: const MiniPlayer(),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final tracks = state.getTracksForAlbum(albumName);

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
                          content: Text("Are you sure you want to delete '$albumName'?", style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () {
                                Provider.of<AppState>(context, listen: false).deleteAlbum(albumName);
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
                    albumName,
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
                              state.removeTrackFromAlbum(track, albumName);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed from $albumName')),
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
                
                // Add some padding at the bottom so the last item isn't blocked by the miniplayer
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
            ],
          );
        },
      ),
    );
  }
}
