import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/track.dart';
import '../theme.dart';
import 'dart:typed_data';

class TrackThumbnail extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final double size;
  
  const TrackThumbnail({
    super.key, 
    required this.track, 
    this.isPlaying = false,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualSize = size.isFinite ? size : math.min(constraints.maxWidth, constraints.maxHeight);

        return Container(
          width: actualSize,
          height: actualSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E2430), // AppTheme.darkCard
                Color(0xFF2A3140), // Slightly lighter
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.audiotrack_rounded,
            color: isPlaying ? AppTheme.primaryYellow : AppTheme.textSecondary,
            size: actualSize * 0.45,
          ),
        );
      },
    );
  }
}

class ProceduralAlbumArt extends StatefulWidget {
  final String pattern;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPlaying;
  final double size;

  const ProceduralAlbumArt({
    super.key,
    required this.pattern,
    required this.primaryColor,
    required this.secondaryColor,
    this.isPlaying = false,
    this.size = 64.0,
  });

  @override
  State<ProceduralAlbumArt> createState() => _ProceduralAlbumArtState();
}

class _ProceduralAlbumArtState extends State<ProceduralAlbumArt> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 14),
    );
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    if (widget.isPlaying) {
      if (widget.pattern == 'vinyl') {
        _rotationController.repeat();
      }
      _waveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ProceduralAlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        if (widget.pattern == 'vinyl') {
          _rotationController.repeat();
        }
        _waveController.repeat(reverse: true);
      } else {
        _rotationController.stop();
        _waveController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [widget.primaryColor, widget.secondaryColor],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: Listenable.merge([_rotationController, _waveController]),
          builder: (context, child) {
            double angle = widget.pattern == 'vinyl' ? _rotationController.value * 2 * math.pi : 0;
            double waveFactor = widget.isPlaying ? 0.6 + (_waveController.value * 0.8) : 1.0;
            
            return Transform.rotate(
              angle: angle,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: ArtPainter(
                  pattern: widget.pattern,
                  primaryColor: widget.primaryColor,
                  secondaryColor: widget.secondaryColor,
                  waveFactor: waveFactor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ArtPainter extends CustomPainter {
  final String pattern;
  final Color primaryColor;
  final Color secondaryColor;
  final double waveFactor;

  ArtPainter({
    required this.pattern,
    required this.primaryColor,
    required this.secondaryColor,
    required this.waveFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;
    final radius = math.min(width, height) / 2;
    final centerOffset = Offset(centerX, centerY);

    switch (pattern) {
      case 'vinyl':
        final blackPaint = Paint()..color = Colors.black.withOpacity(0.7);
        canvas.drawCircle(centerOffset, radius * 0.95, blackPaint);
        
        final strokePaint = Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
          
        for (int i = 1; i <= 6; i++) {
          canvas.drawCircle(centerOffset, radius * (0.95 - i * 0.11), strokePaint);
        }
        
        canvas.drawCircle(centerOffset, radius * 0.38, Paint()..color = primaryColor);
        canvas.drawCircle(centerOffset, radius * 0.22, Paint()..color = secondaryColor.withOpacity(0.6));
        canvas.drawCircle(centerOffset, radius * 0.08, Paint()..color = const Color(0xFF0D1117));
        break;

      case 'waves':
        final int barCount = 6;
        final double spacing = width / (barCount + 1);
        final paint = Paint()
          ..color = Colors.white.withOpacity(0.85)
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round;

        for (int i = 0; i < barCount; i++) {
          final double baseHeight = height * (0.25 + 0.35 * math.sin((i + 1) * 1.1)) * waveFactor;
          final double x = spacing * (i + 1);
          canvas.drawLine(
            Offset(x, centerY - baseHeight / 2),
            Offset(x, centerY + baseHeight / 2),
            paint,
          );
        }
        break;

      case 'spheres':
        canvas.drawCircle(
          Offset(centerX - radius * 0.2, centerY - radius * 0.15),
          radius * 0.65,
          Paint()..color = Colors.white.withOpacity(0.18),
        );
        canvas.drawCircle(
          Offset(centerX + radius * 0.25, centerY + radius * 0.25),
          radius * 0.55,
          Paint()..color = secondaryColor.withOpacity(0.35),
        );
        canvas.drawCircle(
          centerOffset,
          8.0,
          Paint()..color = Colors.white,
        );
        break;

      default:
        final int cellCount = 5;
        final double step = width / cellCount;
        final linePaint = Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 1.0;

        for (int i = 1; i < cellCount; i++) {
          canvas.drawLine(Offset(i * step, 0), Offset(i * step, height), linePaint);
          canvas.drawLine(Offset(0, i * step), Offset(width, i * step), linePaint);
        }

        final path = Path()
          ..moveTo(centerX, centerY - radius * 0.45)
          ..lineTo(centerX + radius * 0.4, centerY + radius * 0.35)
          ..lineTo(centerX - radius * 0.4, centerY + radius * 0.35)
          ..close();
          
        canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.25));
    }
  }

  @override
  bool shouldRepaint(covariant ArtPainter oldDelegate) {
    return pattern != oldDelegate.pattern ||
        primaryColor != oldDelegate.primaryColor ||
        secondaryColor != oldDelegate.secondaryColor ||
        waveFactor != oldDelegate.waveFactor;
  }
}
