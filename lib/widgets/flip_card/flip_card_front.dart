import 'package:flutter/material.dart';

class FlipCardFront extends StatelessWidget {
  final String title;
  final String artist;

  final Widget cover;

  final Widget spectrumBars;
  final Widget soundwaves;

  final BorderRadius? borderRadius;
  final Color color;

  final Duration currentPosition;
  final Duration totalDuration;

  final Widget actionPill;

  const FlipCardFront({
    super.key,
    required this.title,
    required this.artist,
    required this.cover,
    required Widget? spectrumBars,
    required Widget? soundwaves,
    this.borderRadius,
    required this.color,
    required this.currentPosition,
    required this.totalDuration,
    required this.actionPill,
  })  : spectrumBars = spectrumBars ?? const SizedBox(),
        soundwaves = soundwaves ?? const SizedBox();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          cover,

          // Glossy Specular Sheen Overlay
          Positioned.fill(
            child: _GlossyDecoration(),
          ),

          // Header Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Title(
                    title: title,
                    artist: artist,
                  ),
                ),
                spectrumBars,
              ],
            ),
          ),

          // Bottom Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    soundwaves,
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _buildTrackTimePill(),
                        ),
                        const SizedBox(width: 8),
                        actionPill,
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTimePill() {
    final curMin = currentPosition.inMinutes;
    final curSec = currentPosition.inSeconds % 60;
    final totMin = totalDuration.inMinutes;
    final totSec = totalDuration.inSeconds % 60;
    final timeStr =
        '${curMin.toString().padLeft(2, '0')}:${curSec.toString().padLeft(2, '0')} / ${totMin.toString().padLeft(2, '0')}:${totSec.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Text(
        timeStr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.80),
          fontSize: 10,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String title;
  final String artist;

  const _Title({super.key, required this.title, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          artist,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _GlossyDecoration extends StatelessWidget {
  const _GlossyDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.02),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.65),
          ],
          stops: const [0.0, 0.25, 0.55, 1.0],
        ),
      ),
    );
  }
}
