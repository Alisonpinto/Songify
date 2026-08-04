import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/track.dart';
import '../theme.dart';
import '../widgets/procedural_album_art.dart';
import '../widgets/add_to_album_sheet.dart';
import '../widgets/recommendation_grid.dart';
import 'album_detail_screen.dart';
import 'package:random_avatar/random_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _localSearchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildAlbumPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkCard, Color(0xFF2A3140)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.album_rounded, size: 40, color: AppTheme.primaryYellow),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final filteredTracks = _localSearchQuery.isEmpty
            ? state.songsList
            : state.searchLocalSongs(_localSearchQuery);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.darkCard,
                        border: Border.all(color: AppTheme.primaryYellow.withValues(alpha: 0.5), width: 1.5),
                        image: state.userProfileImage != null
                            ? DecorationImage(
                                image: NetworkImage(state.userProfileImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: state.userProfileImage == null
                          ? ClipOval(
                              child: RandomAvatar(
                                state.currentAvatarSeed,
                                trBackground: false,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      state.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.isLoggedIn) ...[
                          if (state.isLoadingShelves)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryYellow),
                              ),
                            )
                          else ...[
                            const RecommendationGrid(),
                          ],
                        ] else ...[
                          const RecommendationGrid(),
                        ],
                        if (state.albumNames.isNotEmpty) ...[
                          const Text(
                            "Your Albums",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.albumNames.length,
                      itemBuilder: (context, index) {
                        final album = state.albumNames[index];
                        final tracksCount = state.getTracksForAlbum(album).length;
                        final albumTracks = state.getTracksForAlbum(album);
                        final firstTrackWithThumb = albumTracks.firstWhere(
                          (t) => t.thumbnailUrl != null && t.thumbnailUrl!.isNotEmpty,
                          orElse: () => Track(id: -1, title: "", artist: "", duration: "", pattern: "", primaryColor: Colors.grey, secondaryColor: Colors.black),
                        );
                        final hasCover = firstTrackWithThumb.id != -1;

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
                            width: 130,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  // Background Image or Placeholder
                                  Positioned.fill(
                                    child: hasCover
                                        ? Image.network(
                                            firstTrackWithThumb.thumbnailUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => _buildAlbumPlaceholder(),
                                          )
                                        : _buildAlbumPlaceholder(),
                                  ),
                                  // Gradient Overlay
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.1),
                                            Colors.black.withValues(alpha: 0.85),
                                          ],
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
                                          album,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "$tracksCount songs",
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isSearching
                      ? Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.5)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: "Search from all songs...",
                              hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _isSearching = false;
                                    _searchController.clear();
                                    _localSearchQuery = "";
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _localSearchQuery = val;
                              });
                            },
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "All Songs",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  icon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primaryYellow),
                                  tooltip: "Search songs",
                                  onPressed: () {
                                    setState(() {
                                      _isSearching = true;
                                    });
                                  },
                                ),
                                const SizedBox(width: 4),
                                TextButton.icon(
                                  onPressed: filteredTracks.isNotEmpty
                                      ? () => state.shuffleQueue(filteredTracks)
                                      : null,
                                  icon: const Icon(Icons.shuffle_rounded, size: 16, color: AppTheme.primaryYellow),
                                  label: const Text(
                                    "Shuffle",
                                    style: TextStyle(
                                      color: AppTheme.primaryYellow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    backgroundColor: AppTheme.darkCard,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                  const SizedBox(height: 12),
                ],
                filteredTracks.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Text(
                            "No matching songs found.",
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTracks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final track = filteredTracks[index];
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
                              state.playFromQueue(filteredTracks, track);
                            },
                            onLongPress: () {
                              showAddToAlbumSheet(context, track, state);
                            },
                          );
                        },
                      ),
                      ],
                    ),
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
