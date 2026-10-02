
import 'package:flutter/material.dart';

import '../theme.dart';

class PremiumFeaturesInfo extends StatelessWidget {

  final Color color;
  final Widget? trailing;

  const PremiumFeaturesInfo({super.key, required this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    Widget? t;
    if (trailing != null) {
      t = Padding(
        padding: EdgeInsets.only(top: 32),
        child: trailing!,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), AppTheme.darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.cloud_sync_rounded, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            const Text(
              "Unlock Premium Features",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Log in to save your playlists, sync your music library across devices, and customize your profile.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5, fontSize: 15),
            ),
            ?t,
          ],
        ),
      ),
    );
  }
}
