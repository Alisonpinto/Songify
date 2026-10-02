import 'package:flutter/material.dart';

import '../theme.dart';

Future<bool> showLogoutDialog({required BuildContext context}) async {
  bool? logout = await showDialog(
    context: context,
    builder: (context) {
      return const LogoutDialog();
    },
  );

  return logout ?? false;
}

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkCard,
      title: const Text("Log Out", style: TextStyle(color: Colors.white)),
      content: const Text("Are you sure you want to log out?", style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => _onCancel(context),
          child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () => _onLogOut(context),
          child: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  void _onCancel(BuildContext context) => Navigator.of(context).pop(false);
  void _onLogOut(BuildContext context) => Navigator.of(context).pop(true);
}
