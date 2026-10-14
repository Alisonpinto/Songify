import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class Soundwave extends StatelessWidget {
  final bool playing;
  final Color color;
  final double phase;

  const Soundwave({
    super.key,
    this.playing = false,
    required this.color,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SoundwavePainter(
        phase: phase,
        accentColor: color,
        isPlaying: playing,
      ),
    );
  }
}

class _SoundwavePainter extends CustomPainter {
  final double phase;
  final Color accentColor;
  final bool isPlaying;

  _SoundwavePainter({
    required this.phase,
    required this.accentColor,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final path = Path();
    final fillPath = Path();

    path.moveTo(0, midY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, midY);

    final amplitude = isPlaying ? size.height * 0.38 : size.height * 0.08;

    for (double x = 0; x <= size.width; x += 3) {
      final normalizedX = x / size.width;
      final envelope = math.sin(normalizedX * math.pi);
      final y = midY +
          math.sin((normalizedX * 3.5 * math.pi) + phase) * amplitude * envelope +
          math.cos((normalizedX * 7.0 * math.pi) - (phase * 1.5)) * (amplitude * 0.35) * envelope;

      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, midY),
        Offset(0, size.height),
        [
          accentColor.withValues(alpha: isPlaying ? 0.35 : 0.08),
          Colors.transparent,
        ],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = isPlaying ? accentColor : accentColor.withValues(alpha: 0.40)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SoundwavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.isPlaying != isPlaying || oldDelegate.accentColor != accentColor;
  }
}
