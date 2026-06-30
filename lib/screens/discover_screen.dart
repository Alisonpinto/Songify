import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';
import '../widgets/add_to_album_sheet.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Track> _searchResults = [];
  bool _isLoading = false;

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    final state = Provider.of<AppState>(context, listen: false);
    final results = await state.searchOnline(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 24, 0, 16),
                  child: Text(
                    "Discover",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: "Search online for any song...",
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch("");
                          },
                        ) 
                      : null,
                    filled: true,
                    fillColor: AppTheme.darkSurface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppTheme.primaryYellow),
                    ),
                  ),
                  onSubmitted: _performSearch,
                  onChanged: (val) {
                    setState(() {}); // Update suffix icon
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                      : _searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                "Search for tracks online completely ad-free.",
                                style: TextStyle(color: AppTheme.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final track = _searchResults[index];
                                final isPlaying = state.currentTrack.id == track.id && state.isPlaying;

                                return ListTile(
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
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
                                    onPressed: () {
                                      showAddToAlbumSheet(context, track, state);
                                    },
                                  ),
                                  onTap: () {
                                    state.addTrackAndPlay(track);
                                  },
                                  onLongPress: () {
                                    showAddToAlbumSheet(context, track, state);
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
