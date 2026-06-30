import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';
import '../widgets/add_to_album_sheet.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(double progress, String totalDurationStr) {
    // Basic mock formatter for display
    int totalSeconds = 0;
    List<String> parts = totalDurationStr.split(':');
    if (parts.length == 2) {
      totalSeconds = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } else if (parts.length == 3) {
      totalSeconds = int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + int.parse(parts[2]);
    }
    
    int elapsed = (progress * totalSeconds).toInt();
    int m = elapsed ~/ 60;
    int s = elapsed % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final track = state.currentTrack;
        final isPlaying = state.isPlaying;

        return Scaffold(
          backgroundColor: AppTheme.darkBackground,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textPrimary, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                    const Text(
                      "Now Playing",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Album Art
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: TrackThumbnail(
                      track: track,
                      isPlaying: isPlaying,
                      size: double.infinity,
                    ),
                  ),
                ),
              ),

              // Title and Favorite
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artist,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
                      onPressed: () {
                        showAddToAlbumSheet(context, track, state);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: AppTheme.primaryYellow,
                        inactiveTrackColor: AppTheme.darkCard,
                        thumbColor: AppTheme.primaryYellow,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayColor: AppTheme.primaryYellow.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: state.trackProgress.clamp(0.0, 1.0),
                        onChanged: (value) => state.seek(value),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(state.trackProgress, track.duration),
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        Text(
                          track.duration,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: state.isShuffle ? AppTheme.primaryYellow : AppTheme.textSecondary,
                      ),
                      onPressed: () => state.toggleShuffle(),
                    ),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.textPrimary),
                      onPressed: () => state.prevTrack(),
                    ),
                    GestureDetector(
                      onTap: () => state.togglePlayPause(),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isPlaying ? AppTheme.primaryYellow : AppTheme.darkCard,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: isPlaying ? Colors.black : AppTheme.textPrimary,
                          size: 40,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(Icons.skip_next_rounded, color: AppTheme.textPrimary),
                      onPressed: () => state.nextTrack(),
                    ),
                    IconButton(
                      icon: Icon(
                        state.isRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                        color: state.isRepeat ? AppTheme.primaryYellow : AppTheme.textSecondary,
                      ),
                      onPressed: () => state.toggleRepeat(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
      },
    );
  }
}
