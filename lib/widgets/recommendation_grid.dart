import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';
import 'add_to_album_sheet.dart';

class RecommendationGrid extends StatelessWidget {
  const RecommendationGrid({super.key});

  List<Track> _getSystematicRecommendations(AppState state) {
    final List<Track> combined = [];
    final Set<int> seenIds = {};

    void addTrack(Track track) {
      if (!seenIds.contains(track.id)) {
        combined.add(track);
        seenIds.add(track.id);
      }
    }

    // 1. Add from Continue Listening (highest priority)
    if (state.continueListeningTracks.isNotEmpty) {
      addTrack(state.continueListeningTracks.first);
    }
    // 2. Add from Because You Liked
    if (state.becauseYouLikedTracks.isNotEmpty) {
      addTrack(state.becauseYouLikedTracks.first);
    }
    // 3. Add from Trending Now
    if (state.trendingTracks.isNotEmpty) {
      addTrack(state.trendingTracks.first);
      if (state.trendingTracks.length > 1) {
        addTrack(state.trendingTracks[1]);
      }
    }
    // 4. Add from More From Artist
    if (state.moreFromArtistTracks.isNotEmpty) {
      addTrack(state.moreFromArtistTracks.first);
    }
    // 5. Add from Your Top Songs
    if (state.topTracks.isNotEmpty) {
      addTrack(state.topTracks.first);
    }
    // 6. Add from Discover New Music
    if (state.discoverTracks.isNotEmpty) {
      addTrack(state.discoverTracks.first);
    }
    // 7. Add from Similar Genre
    if (state.similarGenreTracks.isNotEmpty) {
      addTrack(state.similarGenreTracks.first);
    }
    // 8. Add from Users Also Listen To
    if (state.usersAlsoListenToTracks.isNotEmpty) {
      addTrack(state.usersAlsoListenToTracks.first);
    }
    // 9. Add from Recently Played
    if (state.recentlyPlayedTracks.isNotEmpty) {
      addTrack(state.recentlyPlayedTracks.first);
    }

    // 10. Fallback pool: populate remaining items systematically from recommended list
    int index = 0;
    final fallbackLists = [
      state.recommendedTracks,
      state.trendingTracks,
      state.discoverTracks,
      state.becauseYouLikedTracks,
    ];

    while (combined.length < 8 && fallbackLists.any((l) => l.isNotEmpty)) {
      bool added = false;
      for (var list in fallbackLists) {
        if (index < list.length) {
          addTrack(list[index]);
          added = true;
        }
      }
      if (!added) break;
      index++;
    }

    return combined.take(12).toList(); // Return up to 12 items (6 rows)
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final gridTracks = _getSystematicRecommendations(state);
    final crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommendations",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        
        if (state.isLoadingRecommendations && gridTracks.isEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: crossAxisCount == 3 ? 3.2 : 2.8,
            ),
            itemCount: 8,
            itemBuilder: (context, index) => const QuickAccessSkeletonCard(),
          )
        else if (gridTracks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                "No recommendations available right now.",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: crossAxisCount == 3 ? 3.2 : 2.8,
            ),
            itemCount: gridTracks.length,
            itemBuilder: (context, index) {
              final track = gridTracks[index];
              return QuickAccessCard(
                track: track,
                onTap: () => state.addTrackAndPlay(track),
                onLongPress: () => _showTrackOptions(context, track, state),
              );
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showTrackOptions(BuildContext context, Track track, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isLiked = state.isLiked(track.id);
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E222D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    track.thumbnailUrl ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      color: AppTheme.darkSurface,
                      child: const Icon(Icons.music_note_rounded, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                subtitle: Text(track.artist, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: AppTheme.textSecondary),
                title: const Text("Add to Playlist", style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  showAddToAlbumSheet(context, track, state);
                },
              ),
              ListTile(
                leading: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isLiked ? AppTheme.primaryYellow : AppTheme.textSecondary,
                ),
                title: Text(isLiked ? "Remove from Liked" : "Like Song", style: const TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  state.toggleLikeTrack(track);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_play_next_rounded, color: AppTheme.textSecondary),
                title: const Text("Add to Queue", style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  final index = state.songsList.indexWhere((t) => t.id == track.id);
                  if (index == -1) {
                    state.songsList.add(track);
                  }
                  state.currentQueue.add(track);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added "${track.title}" to queue')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_rounded, color: AppTheme.textSecondary),
                title: const Text("View Artist", style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: track.artist));
                  state.changeTab(1); // Switch to Discover tab
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied "${track.artist}" to clipboard and switched to Discover tab')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: AppTheme.textSecondary),
                title: const Text("Share", style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: 'Listen to ${track.title} by ${track.artist} on Songify!'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Song link copied to clipboard!')),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class QuickAccessCard extends StatefulWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const QuickAccessCard({
    super.key,
    required this.track,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<QuickAccessCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isPlaying = appState.currentTrack.id == widget.track.id && appState.isPlaying;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF2A2D36), // Charcoal dark grey background matching the image
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  splashColor: AppTheme.primaryYellow.withOpacity(0.15),
                  highlightColor: AppTheme.primaryYellow.withOpacity(0.08),
                  child: Row(
                    children: [
                      // Artwork on the left
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                widget.track.thumbnailUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppTheme.darkSurface,
                                  child: Icon(
                                    isPlaying ? Icons.volume_up_rounded : Icons.music_note_rounded,
                                    color: isPlaying ? AppTheme.primaryYellow : AppTheme.textSecondary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            if (isPlaying)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.4),
                                  child: const Center(
                                    child: Icon(Icons.pause_rounded, color: AppTheme.primaryYellow, size: 20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Text metadata details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.track.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isPlaying ? AppTheme.primaryYellow : AppTheme.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.track.artist,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 9.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuickAccessSkeletonCard extends StatefulWidget {
  const QuickAccessSkeletonCard({super.key});

  @override
  State<QuickAccessSkeletonCard> createState() => _QuickAccessSkeletonCardState();
}

class _QuickAccessSkeletonCardState extends State<QuickAccessSkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF2A2D36),
            ),
            child: Row(
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 10,
                          width: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: 8,
                          width: 45,
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
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
