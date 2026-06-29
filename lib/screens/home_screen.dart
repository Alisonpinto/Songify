import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';
import '../widgets/add_to_album_sheet.dart';
import 'dart:math' as math;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        List<Track> filteredTracks = state.songsList;
        if (state.searchQuery.trim().isNotEmpty) {
          filteredTracks = state.songsList.where((t) => 
            t.title.toLowerCase().contains(state.searchQuery.toLowerCase()) || 
            t.artist.toLowerCase().contains(state.searchQuery.toLowerCase())
          ).toList();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Good Evening, Alison",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Your offline music hub is ready",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: state.updateSearch,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: "Search songs, artists...",
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                    suffixIcon: state.searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          onPressed: () => state.updateSearch(""),
                        ) 
                      : null,
                    filled: true,
                    fillColor: AppTheme.darkSurface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppTheme.primaryYellow),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredTracks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final track = filteredTracks[index];
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
                          icon: Icon(
                            track.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: track.isFavorite ? AppTheme.primaryYellow : AppTheme.textSecondary,
                          ),
                          onPressed: () => state.toggleFavorite(track),
                        ),
                        onTap: () {
                          if (state.songsList.indexOf(track) != -1) {
                            state.playingTrackIndex = state.songsList.indexOf(track);
                            state.togglePlayPause(); // This will play it if it's new
                          }
                        },
                        onLongPress: () {
                          showAddToAlbumSheet(context, track, state);
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
