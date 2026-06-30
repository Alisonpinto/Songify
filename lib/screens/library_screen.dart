import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';
import '../widgets/add_to_album_sheet.dart';
import 'album_detail_screen.dart';
import 'auth_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        List<Track> displayList = state.songsList;
        
        // Filter by active chip
        if (state.activeFilterChip == 'Imported') {
          displayList = displayList.where((t) => t.isImported).toList();
        }
        
        // Filter by search
        if (state.searchQuery.trim().isNotEmpty) {
          displayList = displayList.where((t) => 
            t.title.toLowerCase().contains(state.searchQuery.toLowerCase()) || 
            t.artist.toLowerCase().contains(state.searchQuery.toLowerCase())
          ).toList();
        }

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Your Library",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await state.requestPermissionAndFetchSongs();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Scanned local device for music')),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.download_rounded, color: AppTheme.primaryYellow, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "Import",
                              style: TextStyle(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['All Songs', 'Albums'].map((chip) {
                    final isSelected = state.activeFilterChip == chip;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(chip),
                        selected: isSelected,
                        onSelected: (_) => state.updateFilter(chip),
                        backgroundColor: AppTheme.darkSurface,
                        selectedColor: AppTheme.primaryYellow.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryYellow : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryYellow : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (state.activeFilterChip == 'Albums') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!state.isLoggedIn) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                        return;
                      }
                      
                      String newAlbumName = "";
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.darkCard,
                          title: const Text("Create Album"),
                          content: TextField(
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: "Album Name",
                              hintStyle: TextStyle(color: AppTheme.textMuted),
                            ),
                            style: const TextStyle(color: AppTheme.textPrimary),
                            onChanged: (val) => newAlbumName = val,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
                            ),
                            TextButton(
                              onPressed: () async {
                                final success = await state.createAlbum(newAlbumName);
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Create", style: TextStyle(color: AppTheme.primaryYellow)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.black),
                    label: const Text("Create New Album", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
                Expanded(
                  child: state.albumNames.isEmpty
                      ? const Center(
                          child: Text(
                            "No albums yet.\nCreate one to get started!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1,
                          ),
                          itemCount: state.albumNames.length,
                          itemBuilder: (context, index) {
                            final album = state.albumNames[index];
                            final tracksCount = state.getTracksForAlbum(album).length;
                            
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AlbumDetailScreen(albumName: album),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [AppTheme.darkCard, Color(0xFF2A3140)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.album_rounded, size: 48, color: AppTheme.primaryYellow),
                                    const SizedBox(height: 12),
                                    Text(
                                      album,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$tracksCount songs",
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ] else ...[
                Expanded(
                  child: displayList.isEmpty
                    ? const Center(
                        child: Text(
                          "No tracks found in this category.",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final track = displayList[index];
                          final isPlaying = state.currentTrack.id == track.id && state.isPlaying;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: TrackThumbnail(
                                track: track, 
                                isPlaying: isPlaying,
                                size: 48,
                              ),
                              title: Text(
                                track.title,
                                style: TextStyle(
                                  color: isPlaying ? AppTheme.primaryYellow : AppTheme.textPrimary,
                                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
                                    onPressed: () {
                                      showAddToAlbumSheet(context, track, state);
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                state.playFromQueue(displayList, track);
                              },
                            ),
                          );
                        },
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
