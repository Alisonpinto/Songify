import 'package:flutter/material.dart';

class LogoutIconButton extends StatelessWidget {
  final void Function()? onPressed;

  const LogoutIconButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.logout_rounded, color: Colors.white70),
    );
  }
}
