import 'package:flutter/material.dart';
import 'package:songify_flutter/theme.dart';

class MusicStatTile extends StatelessWidget {
  final Widget icon;
  final Widget title;
  final Widget subtitle;
  final Color? color;

  const MusicStatTile({super.key, required this.icon, required this.title, required this.subtitle, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: color, size: 35),
                child: icon,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle.merge(
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  child: title,
                ),
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  child: subtitle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
