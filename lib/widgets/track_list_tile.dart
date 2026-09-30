import 'package:flutter/material.dart';
import 'package:songify_flutter/models/track.dart';
import 'package:songify_flutter/theme.dart';
import 'package:songify_flutter/widgets/procedural_album_art.dart';

class TrackListTile extends StatelessWidget {
  final Track track;
  final bool playing;
  final void Function()? onAddToPlaylist;
  final void Function()? onPressed;
  final void Function()? onLongPressed;

  const TrackListTile({
    super.key,
    required this.track,
    required this.playing,
    this.onAddToPlaylist,
    this.onPressed,
    this.onLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: TrackThumbnail(track: track, isPlaying: playing, size: 48),
      title: Text(
        track.title,
        style: TextStyle(
          color: playing ? AppTheme.primaryYellow : AppTheme.textPrimary,
          fontWeight: playing ? FontWeight.bold : FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        style: const TextStyle(color: AppTheme.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
        onPressed: onAddToPlaylist,
      ),
      onTap: onPressed,
      onLongPress: onLongPressed,
    );
  }
}
