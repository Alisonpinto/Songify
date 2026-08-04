import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  track.primaryColor.withOpacity(0.22),
                  AppTheme.darkBackground,
                ],
                stops: const [0.0, 0.7],
              ),
            ),
            child: SafeArea(
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
                      icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryYellow),
                      tooltip: "Recommendations",
                      onPressed: () => _showRecommendationsBottomSheet(context, state),
                    ),
                  ],
                ),
              ),

              // Album Art
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = math.min(constraints.maxWidth, constraints.maxHeight);
                      return Center(
                        child: SizedBox(
                          width: size,
                          height: size,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: CircularAlbumCover(
                                  track: track,
                                  isPlaying: isPlaying,
                                ),
                              ),
                              Positioned(
                                right: -size * 0.05,
                                top: -size * 0.15,
                                child: VinylTonearm(
                                  isPlaying: isPlaying,
                                  discSize: size,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                    Row(
                      children: [
                        IconButton(
                          iconSize: 28,
                          icon: Icon(
                            state.isLiked(track.id)
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: state.isLiked(track.id)
                                ? AppTheme.primaryYellow
                                : AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            state.toggleLikeTrack(track);
                          },
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
      ),
    );
      },
    );
  }

  void _showRecommendationsBottomSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, state, child) {
            final tracks = state.recommendedTracks;
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Color(0xFF1E222D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryYellow, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Recommended for You",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Based on the currently playing song",
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: state.isLoadingRecommendations
                        ? const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryYellow),
                          )
                        : tracks.isEmpty
                            ? const Center(
                                child: Text(
                                  "No recommendations available for this track.",
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: tracks.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final track = tracks[index];
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
                                      Navigator.pop(context); // Close bottom sheet
                                      state.addTrackAndPlay(track);
                                    },
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class CircularAlbumCover extends StatefulWidget {
  final Track track;
  final bool isPlaying;

  const CircularAlbumCover({
    super.key,
    required this.track,
    required this.isPlaying,
  });

  @override
  State<CircularAlbumCover> createState() => _CircularAlbumCoverState();
}

class _CircularAlbumCoverState extends State<CircularAlbumCover> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(CircularAlbumCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        
        return Center(
          child: RotationTransition(
            turns: _rotationController,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Vinyl Disc Paint
                  Positioned.fill(
                    child: CustomPaint(
                      painter: VinylDiscPainter(),
                    ),
                  ),
                  
                  // Album Art Image / Placeholder in the middle
                  Container(
                    width: size * 0.62,
                    height: size * 0.62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.darkCard,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: ClipOval(
                      child: widget.track.thumbnailUrl != null && widget.track.thumbnailUrl!.isNotEmpty
                          ? Image.network(
                              widget.track.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(size * 0.62),
                            )
                          : _buildPlaceholder(size * 0.62),
                    ),
                  ),
                  
                  // Vinyl Center Spindle / Label Ring
                  Container(
                    width: size * 0.15,
                    height: size * 0.15,
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryYellow.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: size * 0.04,
                        height: size * 0.04,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(double imageSize) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.track.primaryColor,
            widget.track.secondaryColor,
          ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: AppTheme.textPrimary,
        size: imageSize * 0.4,
      ),
    );
  }
}

class VinylDiscPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Base Vinyl Circle
    final basePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2C2F36),
          const Color(0xFF15181E),
          const Color(0xFF0A0C10),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, basePaint);

    // Grooves
    final groovePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric groove lines
    for (double i = 0.7; i < 0.95; i += 0.03) {
      canvas.drawCircle(center, radius * i, groovePaint);
    }
    for (double i = 0.35; i < 0.65; i += 0.04) {
      canvas.drawCircle(center, radius * i, groovePaint);
    }

    // Outer edge highlights
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 1, edgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VinylTonearm extends StatelessWidget {
  final bool isPlaying;
  final double discSize;

  const VinylTonearm({
    super.key,
    required this.isPlaying,
    required this.discSize,
  });

  @override
  Widget build(BuildContext context) {
    final width = discSize * 0.35;
    final height = discSize * 0.55;

    return AnimatedRotation(
      turns: isPlaying ? 0.0 : -0.06, // swing away slightly when paused
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: Alignment.topRight,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: TonearmPainter(),
        ),
      ),
    );
  }
}

class TonearmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = const Color(0xFF8E8E93)
      ..style = PaintingStyle.fill;

    final armPaint = Paint()
      ..color = const Color(0xFFC7C7CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final headPaint = Paint()
      ..color = const Color(0xFF3A3A3C)
      ..style = PaintingStyle.fill;

    // 1. Draw base at top-right
    final baseCenter = Offset(size.width - (size.width * 0.2), size.width * 0.2);
    canvas.drawCircle(baseCenter, size.width * 0.16, Paint()..color = const Color(0xFF2C2C2E));
    canvas.drawCircle(baseCenter, size.width * 0.10, basePaint);

    // 2. Draw the arm bending down and left towards the record
    final path = Path()
      ..moveTo(baseCenter.dx, baseCenter.dy)
      ..lineTo(size.width - (size.width * 0.3), size.height * 0.4)
      ..lineTo(size.width * 0.3, size.height * 0.85);

    canvas.drawPath(path, armPaint);

    // 3. Draw headshell at the needle end
    final headOffset = Offset(size.width * 0.3, size.height * 0.85);
    canvas.drawCircle(headOffset, size.width * 0.06, basePaint);
    
    // Draw the cartridge rectangle rotated slightly
    canvas.save();
    canvas.translate(headOffset.dx, headOffset.dy);
    canvas.rotate(0.3); // Rotate slightly
    canvas.drawRect(
      Rect.fromLTWH(-size.width * 0.06, 0, size.width * 0.1, size.height * 0.1),
      headPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(-size.width * 0.08, size.height * 0.08, size.width * 0.04, size.height * 0.025),
      Paint()..color = AppTheme.primaryYellow,
    ); // Accent color tip
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
