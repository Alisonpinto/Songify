import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:songify_flutter/widgets/flip_card/flip_card_front.dart';
import 'package:songify_flutter/widgets/flip_card/soundwave.dart';
import 'package:songify_flutter/widgets/flip_card/spectrum_bars.dart';

/// Represents a single synchronized lyric line with an associated timestamp.
class LyricLine {
  /// The timestamp in the song when this lyric line begins.
  final Duration timestamp;

  /// The text content of the lyric.
  final String text;

  /// Optional translated text or secondary Romanized subtitle.
  final String? translation;

  /// Creates a [LyricLine].
  const LyricLine({
    required this.timestamp,
    required this.text,
    this.translation,
  });
}

/// A production-grade 3D flip card for music playback interfaces.
class MusicPlayerFlipCard extends StatefulWidget {
  final String title;
  final String artist;
  final String? album;
  final Widget? coverArt;
  final String? coverImageUrl;
  final List<LyricLine> lyrics;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isPlaying;
  final Color accentColor;
  final Color? secondaryColor;
  final Color backgroundColor;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool enableParallaxTilt;
  final bool showVinylEdge;
  final bool showWaveform;
  final bool showSpectrumBars;
  final ValueChanged<Duration>? onSeekLyric;
  final ValueChanged<bool>? onFlip;
  final VoidCallback? onPlayPause;
  final String tapForLyricsLabel;
  final String tapForCoverLabel;

  const MusicPlayerFlipCard({
    super.key,
    required this.title,
    required this.artist,
    this.album,
    this.coverArt,
    this.coverImageUrl,
    this.lyrics = const [],
    this.currentPosition = Duration.zero,
    this.totalDuration = const Duration(minutes: 3, seconds: 30),
    this.isPlaying = true,
    this.accentColor = const Color(0xFFFFC107),
    this.secondaryColor,
    this.backgroundColor = const Color(0xFF161A22),
    this.width = 340,
    this.height = 380,
    this.borderRadius,
    this.enableParallaxTilt = true,
    this.showVinylEdge = true,
    this.showWaveform = true,
    this.showSpectrumBars = true,
    this.onSeekLyric,
    this.onFlip,
    this.onPlayPause,
    this.tapForLyricsLabel = 'Tap for lyrics',
    this.tapForCoverLabel = 'Tap for cover',
  });

  @override
  State<MusicPlayerFlipCard> createState() => _MusicPlayerFlipCardState();
}

class _MusicPlayerFlipCardState extends State<MusicPlayerFlipCard> with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final AnimationController _waveController;
  late final AnimationController _vinylController;
  final ScrollController _lyricsScrollController = ScrollController();

  double _tiltX = 0.0;
  double _tiltY = 0.0;
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    if (widget.isPlaying) {
      _waveController.repeat();
      _vinylController.repeat();
    }
  }

  @override
  void didUpdateWidget(MusicPlayerFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _waveController.repeat();
        _vinylController.repeat();
      } else {
        _waveController.stop();
        _vinylController.stop();
      }
    }

    final activeIdx = _calculateActiveLyricIndex();
    if (activeIdx != _lastActiveIndex) {
      _lastActiveIndex = activeIdx;
      if (_flipController.value >= 0.5) {
        _scrollToActiveLyric(activeIdx);
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _waveController.dispose();
    _vinylController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  int _calculateActiveLyricIndex() {
    if (widget.lyrics.isEmpty) return -1;
    for (int i = widget.lyrics.length - 1; i >= 0; i--) {
      if (widget.currentPosition >= widget.lyrics[i].timestamp) {
        return i;
      }
    }
    return 0;
  }

  void _scrollToActiveLyric(int index) {
    if (!_lyricsScrollController.hasClients || index < 0) return;
    final targetOffset = math.max(0.0, (index * 54.0) - 120.0);
    _lyricsScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleFlip() {
    if (_flipController.isAnimating) return;
    final isShowingBack = _flipController.value >= 0.5;
    if (isShowingBack) {
      _flipController.reverse();
      widget.onFlip?.call(false);
    } else {
      _flipController.forward();
      widget.onFlip?.call(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveLyric(_calculateActiveLyricIndex());
      });
    }
  }

  void _onPointerHover(PointerEvent event) {
    if (!widget.enableParallaxTilt || _flipController.value >= 0.5) return;
    final halfW = widget.width / 2;
    final halfH = widget.height / 2;
    final x = (event.localPosition.dx - halfW) / halfW;
    final y = (event.localPosition.dy - halfH) / halfH;

    setState(() {
      _tiltX = (-y * 0.10).clamp(-0.10, 0.10);
      _tiltY = (x * 0.10).clamp(-0.10, 0.10);
    });
  }

  void _onPointerExit(PointerEvent event) {
    if (!widget.enableParallaxTilt) return;
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(24.0);
    final secondary = widget.secondaryColor ?? widget.accentColor.withValues(alpha: 0.7);

    return MouseRegion(
      onHover: _onPointerHover,
      onExit: _onPointerExit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleFlip,
        child: AnimatedBuilder(
          animation: Listenable.merge([_flipController, _waveController, _vinylController]),
          builder: (context, _) {
            final flipVal = _flipController.value;
            final isBack = flipVal >= 0.5;
            final angle = flipVal * math.pi;

            final depthScale = 1.0 - (0.10 * math.sin(flipVal * math.pi));

            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..multiply(Matrix4.diagonal3Values(depthScale, depthScale, 1.0))
              ..rotateX(isBack ? 0.0 : _tiltX)
              ..rotateY(angle + (isBack ? 0.0 : _tiltY));

            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ambient radial glow
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: effectiveRadius,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentColor.withValues(alpha: widget.isPlaying ? 0.25 : 0.08),
                              blurRadius: 36,
                              spreadRadius: 4,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: secondary.withValues(alpha: widget.isPlaying ? 0.15 : 0.04),
                              blurRadius: 50,
                              spreadRadius: 6,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Rotating Vinyl Disc (front face peek)
                    if (widget.showVinylEdge && !isBack)
                      Positioned(
                        right: -widget.width * 0.14,
                        top: widget.height * 0.10,
                        bottom: widget.height * 0.10,
                        width: widget.height * 0.80,
                        child: AnimatedBuilder(
                          animation: _vinylController,
                          builder: (context, _) {
                            final rot = _vinylController.value * 2 * math.pi;
                            return Transform.rotate(
                              angle: rot,
                              child: _VinylDiscPainterWidget(
                                accentColor: widget.accentColor,
                                title: widget.title,
                              ),
                            );
                          },
                        ),
                      ),

                    // Front or Back Face
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: effectiveRadius,
                        child: isBack
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _buildBackFace(context, effectiveRadius),
                              )
                            : _buildFrontFace(context, effectiveRadius),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontFace(BuildContext context, BorderRadius radius) {
    Widget cover;

    // Base Artwork
    if (widget.coverArt != null) {
      cover = widget.coverArt!;
    } else if (widget.coverImageUrl != null && widget.coverImageUrl!.isNotEmpty) {
      cover = Image.network(
        widget.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackArtwork(),
      );
    } else {
      cover = ColoredBox(
        color: widget.backgroundColor,
        child: _buildFallbackArtwork(),
      );
    }

    Widget soundwaves = SizedBox(
      height: 32,
      width: double.infinity,
      child: Soundwave(
        phase: _waveController.value * 2 * math.pi,
        color: widget.accentColor,
        playing: widget.isPlaying,
      ),
    );

    Widget bars = SpectrumBars(
      playing: widget.isPlaying,
      progress: _waveController.value,
      color: widget.accentColor,
    );

    return FlipCardFront(
      title: widget.title,
      artist: widget.artist,
      cover: cover,
      spectrumBars: widget.showSpectrumBars ? bars : null,
      soundwaves: widget.showWaveform ? soundwaves : null,
      color: widget.accentColor,
      borderRadius: radius,
      currentPosition: widget.currentPosition,
      totalDuration: widget.totalDuration,
      actionPill: _buildActionPill(
        icon: Icons.lyrics_outlined,
        label: widget.tapForLyricsLabel,
        accentColor: widget.accentColor,
        onTap: _toggleFlip,
      ),
    );
  }

  Widget _buildBackFace(BuildContext context, BorderRadius radius) {
    final activeIndex = _calculateActiveLyricIndex();

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: radius,
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: widget.coverArt ?? _buildFallbackArtwork(),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: widget.backgroundColor.withValues(alpha: 0.85),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.artist,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionPill(
                      icon: Icons.album_outlined,
                      label: widget.tapForCoverLabel,
                      accentColor: widget.accentColor,
                      onTap: _toggleFlip,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(
                  color: Colors.white.withValues(alpha: 0.12),
                  height: 1,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: widget.lyrics.isEmpty
                      ? Center(
                          child: Text(
                            'No synchronized lyrics available',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _lyricsScrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: widget.lyrics.length,
                          itemBuilder: (context, index) {
                            final line = widget.lyrics[index];
                            final isActive = index == activeIndex;
                            final isPast = index < activeIndex;

                            return InkWell(
                              onTap: () {
                                widget.onSeekLyric?.call(line.timestamp);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? widget.accentColor.withValues(alpha: 0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isActive
                                      ? Border.all(
                                          color: widget.accentColor.withValues(alpha: 0.40),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.text,
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : isPast
                                                ? Colors.white.withValues(alpha: 0.50)
                                                : Colors.white.withValues(alpha: 0.28),
                                        fontSize: isActive ? 15 : 13,
                                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                        height: 1.3,
                                        shadows: isActive
                                            ? [
                                                Shadow(
                                                  color: widget.accentColor.withValues(alpha: 0.70),
                                                  blurRadius: 10,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                    if (line.translation != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          line.translation!,
                                          style: TextStyle(
                                            color: isActive
                                                ? widget.accentColor.withValues(alpha: 0.90)
                                                : Colors.white.withValues(alpha: 0.35),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (widget.showWaveform)
                  SizedBox(
                    height: 16,
                    width: double.infinity,
                    child: Soundwave(
                      phase: _waveController.value * 2 * math.pi,
                      color: widget.accentColor,
                      playing: widget.isPlaying,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackArtwork() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            widget.accentColor.withValues(alpha: 0.45),
            widget.backgroundColor,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 64,
          color: widget.accentColor.withValues(alpha: 0.60),
        ),
      ),
    );
  }
}

class _VinylDiscPainterWidget extends StatelessWidget {
  final Color accentColor;
  final String title;

  const _VinylDiscPainterWidget({
    required this.accentColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final radius = constraints.maxWidth / 2;
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _VinylDiscPainter(
            accentColor: accentColor,
            radius: radius,
          ),
        );
      },
    );
  }
}

class _VinylDiscPainter extends CustomPainter {
  final Color accentColor;
  final double radius;

  _VinylDiscPainter({
    required this.accentColor,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final discPaint = Paint()
      ..color = const Color(0xFF0A0C10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, discPaint);

    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double r = radius * 0.45; r < radius * 0.95; r += 7.0) {
      canvas.drawCircle(center, r, groovePaint);
    }

    final labelRadius = radius * 0.36;
    final labelPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        labelRadius,
        [
          accentColor,
          accentColor.withValues(alpha: 0.70),
          const Color(0xFF141820),
        ],
        const [0.0, 0.70, 1.0],
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, labelRadius, labelPaint);

    final holePaint = Paint()
      ..color = const Color(0xFF050608)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.07, holePaint);

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 1, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _VinylDiscPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor || oldDelegate.radius != radius;
  }
}
