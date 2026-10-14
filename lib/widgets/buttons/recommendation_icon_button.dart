import 'package:flutter/material.dart';

import '../../theme.dart';

class RecommendationIconButton extends StatelessWidget {
  final void Function()? onPressed;

  const RecommendationIconButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryYellow),
        tooltip: "Recommendations",
        onPressed: onPressed);
  }
}
