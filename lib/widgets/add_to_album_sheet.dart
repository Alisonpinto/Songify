import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';

void showAddToAlbumSheet(BuildContext context, Track track, AppState state) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Add to Album",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (state.albumNames.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  "No albums created yet.\nGo to Library -> Albums to create one.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              ...state.albumNames.map((album) {
                return ListTile(
                  leading: const Icon(Icons.album_rounded, color: AppTheme.primaryYellow),
                  title: Text(album, style: const TextStyle(color: AppTheme.textPrimary)),
                  onTap: () {
                    state.addTrackToAlbum(track, album);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added to $album')),
                    );
                  },
                );
              }),
          ],
        ),
      );
    },
  );
}
