import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;

  const AlbumDetailScreen({super.key, required this.albumName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(albumName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.darkCard,
                  title: const Text("Delete Album"),
                  content: Text("Are you sure you want to delete '$albumName'?"),
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
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          final tracks = state.getTracksForAlbum(albumName);

          if (tracks.isEmpty) {
            return const Center(
              child: Text(
                "This album is empty.\nAdd songs from your library!",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final isPlaying = state.currentTrack.id == track.id && state.isPlaying;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: track.isFavorite ? AppTheme.primaryYellow : AppTheme.textSecondary,
                        ),
                        onPressed: () => state.toggleFavorite(track),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.textSecondary),
                        onPressed: () {
                          state.removeTrackFromAlbum(track, albumName);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Removed from $albumName')),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    if (state.songsList.indexOf(track) != -1) {
                      state.playingTrackIndex = state.songsList.indexOf(track);
                      state.togglePlayPause();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
