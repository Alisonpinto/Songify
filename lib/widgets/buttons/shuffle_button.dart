import 'package:flutter/material.dart';

import '../../theme.dart';

class ShuffleButton extends StatelessWidget {

  final void Function()? onPressed;

  const ShuffleButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.shuffle_rounded,
        size: 16,
        color: AppTheme.primaryYellow,
      ),
      label: const Text(
        "Shuffle",
        style: TextStyle(
          color: AppTheme.primaryYellow,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
