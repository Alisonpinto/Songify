import 'package:flutter/material.dart';

import '../../theme.dart';

class SearchIconButton extends StatelessWidget {
  final void Function()? onPressed;

  const SearchIconButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
      icon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primaryYellow),
      tooltip: "Search songs",
      onPressed: onPressed,
    );
  }
}
