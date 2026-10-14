import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpectrumBars extends StatelessWidget {
  final bool playing;
  final double progress;
  final Color color;

  const SpectrumBars({
    required this.playing,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final factor = playing ? 0.30 + 0.70 * ((math.sin(progress * 2 * math.pi + (i * 1.3)) + 1) / 2) : 0.20;
        final barHeight = 5.0 + (factor * 14.0);

        return Container(
          width: 3.0,
          height: barHeight,
          margin: const EdgeInsets.symmetric(horizontal: 1.2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.60),
                blurRadius: 4,
              ),
            ],
          ),
        );
      }),
    );
  }
}
