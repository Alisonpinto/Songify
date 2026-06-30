import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';
import '../screens/auth_screen.dart';

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
                "Add to Playlist",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (!state.isLoggedIn)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const Text(
                      "Log in to save and organize your favorite songs into playlists.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: AppTheme.darkBackground,
                      ),
                      child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            else if (state.albumNames.isEmpty)
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
                  onTap: () async {
                    final success = await state.addTrackToAlbum(track, album);
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to $album')),
                        );
                      }
                    }
                  },
                );
              }),
          ],
        ),
      );
    },
  );
}
