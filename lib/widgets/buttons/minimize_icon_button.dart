
import 'package:flutter/material.dart';

import '../../theme.dart';

class MinimizeIconButton extends StatelessWidget {

  final void Function()? onPressed;

  const MinimizeIconButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textPrimary, size: 32),
      onPressed: onPressed,
    );
  }
}
