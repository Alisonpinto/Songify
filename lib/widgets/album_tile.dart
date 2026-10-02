import 'package:flutter/material.dart';

import '../theme.dart';

class AlbumTile extends StatelessWidget {
  final String name;
  final int trackCount;
  final String? coverUrl;
  final void Function()? onPressed;

  const AlbumTile({super.key, required this.name, required this.trackCount, required this.coverUrl, this.onPressed});

  @override
  Widget build(BuildContext context) {
    Widget cover = const AlbumPlaceholder();

    if (coverUrl != null && coverUrl!.isNotEmpty) {
      cover = Image.network(
        coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const AlbumPlaceholder(),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: SizedBox(
        width: 130,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background Image or Placeholder
                Positioned.fill(child: cover),
                // Gradient Overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.85)],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
                // Texts
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text("$trackCount songs", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AlbumPlaceholder extends StatelessWidget {
  const AlbumPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkCard, Color(0xFF2A3140)],
        ),
      ),
      child: const Center(child: Icon(Icons.album_rounded, size: 40, color: AppTheme.primaryYellow)),
    );
  }
}
