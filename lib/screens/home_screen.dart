import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:songify_flutter/widgets/album_tile.dart';
import 'package:songify_flutter/widgets/buttons/search_icon_button.dart';
import 'package:songify_flutter/widgets/buttons/shuffle_button.dart';
import 'package:songify_flutter/widgets/track_list_tile.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final filteredTracks = _localSearchQuery.isEmpty ? state.songsList : state.searchLocalSongs(_localSearchQuery);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const _Avatar(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Recommendations(loggedIn: state.isLoggedIn, loadingShelves: state.isLoadingShelves),
                        if (state.albumNames.isNotEmpty) ...[
                          const _Title("Your Albums"),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 130,
                            child: ListView.separated(
                              separatorBuilder: (context, index) => const SizedBox(width: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: state.albumNames.length,
                              itemBuilder: (context, index) {
                                final album = state.albumNames[index];
                                final tracksCount = state.getTracksForAlbum(album).length;
                                final albumTracks = state.getTracksForAlbum(album);
                                final firstTrackWithThumb = albumTracks.firstWhere(
                                  (t) => t.thumbnailUrl != null && t.thumbnailUrl!.isNotEmpty,
                                  orElse: () => Track(
                                    id: -1,
                                    title: "",
                                    artist: "",
                                    duration: "",
                                    pattern: "",
                                    primaryColor: Colors.grey,
                                    secondaryColor: Colors.black,
                                  ),
                                );

                                return AlbumTile(
                                  name: album,
                                  trackCount: tracksCount,
                                  coverUrl: firstTrackWithThumb.thumbnailUrl,
                                  onPressed: () => _onAlbumPressed(album),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          _isSearching
                              ? SizedBox(
                                  height: 46,
                                  child: _SearchField(
                                    controller: _searchController,
                                    onClose: _onCloseSearch,
                                    onChanged: _onSearch,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const _Title("All Songs"),
                                    Row(
                                      children: [
                                        SearchIconButton(onPressed: _onOpenSearch),
                                        const SizedBox(width: 4),
                                        ShuffleButton(
                                          onPressed: filteredTracks.isNotEmpty
                                              ? () => _onShuffle(state, filteredTracks)
                                              : null,
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

                                  return TrackListTile(
                                    track: track,
                                    playing: isPlaying,
                                    onPressed: () => _onPlayTrack(state, filteredTracks, track),
                                    onAddToPlaylist: () => _onAddTrackToAlbum(state, track),
                                    onLongPressed: () => _onAddTrackToAlbum(state, track),
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

  void _onAlbumPressed(String album) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AlbumDetailScreen(albumName: album)));
  }

  void _onPlayTrack(AppState state, List<Track> tracks, Track track) {
    state.playFromQueue(tracks, track);
  }

  void _onAddTrackToAlbum(AppState state, Track track) {
    showAddToAlbumSheet(context, track, state);
  }

  void _onCloseSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _localSearchQuery = "";
    });
  }

  void _onSearch(String text) {
    setState(() => _localSearchQuery = text);
  }

  void _onOpenSearch() => setState(() => _isSearching = true);

  void _onShuffle(AppState state, List<Track> tracks) {
    state.shuffleQueue(tracks);
  }
}

class _Title extends StatelessWidget {
  final String title;

  const _Title(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
    );
  }
}

// TODO(Yuki): unify this widget with the existing SearchTextField
class _SearchField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function()? onClose;
  final void Function(String text)? onChanged;

  const _SearchField({super.key, this.controller, this.onClose, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryYellow.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: "Search from all songs...",
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
            onPressed: onClose,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.darkCard,
                border: Border.all(color: AppTheme.primaryYellow.withValues(alpha: 0.5), width: 1.5),
                image: state.userProfileImage != null
                    ? DecorationImage(image: NetworkImage(state.userProfileImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: state.userProfileImage == null
                  ? ClipOval(child: RandomAvatar(state.currentAvatarSeed, trBackground: false))
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              state.userName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ],
        );
      },
    );
  }
}

class _Recommendations extends StatelessWidget {
  final bool loggedIn;
  final bool loadingShelves;

  const _Recommendations({super.key, required this.loggedIn, required this.loadingShelves});

  @override
  Widget build(BuildContext context) {
    if (loggedIn && loadingShelves) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow)),
      );
    }

    return RecommendationGrid();
  }
}
