import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jiosaavn/jiosaavn.dart';
import '../models/track.dart';
import '../utils/search_engine.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/recommendation_service.dart';

class AppState extends ChangeNotifier {
  int currentTab = 0; // 0 = Home, 1 = Library, 2 = Now Playing
  String searchQuery = "";
  String activeFilterChip = "All Songs";
  
  // User Profile Data
  String? userId;
  String userName = "Music Lover";
  String userHandle = "@musiclover";
  String? userProfileImage;
  
  String? _avatarSeed;
  String get currentAvatarSeed => _avatarSeed ?? userName;
  
  void generateNewAvatar() {
    _avatarSeed = DateTime.now().millisecondsSinceEpoch.toString();
    notifyListeners();
  }
  List<Track> songsList = [];
  List<Track> currentQueue = [];
  
  int playingTrackIndex = 0;
  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final JioSaavnClient _jio = JioSaavnClient();
  
  List<Track> recommendedTracks = [];
  bool isLoadingRecommendations = false;
  
  // Recommendation Service & Shelf Lists
  final RecommendationService _recommendationService = RecommendationService();
  List<Track> continueListeningTracks = [];
  List<Track> becauseYouLikedTracks = [];
  List<Track> trendingTracks = [];
  List<Track> moreFromArtistTracks = [];
  List<Track> topTracks = [];
  List<Track> discoverTracks = [];
  List<Track> recentlyPlayedTracks = [];
  List<Track> similarGenreTracks = [];
  List<Track> usersAlsoListenToTracks = [];
  bool isLoadingShelves = false;

  final Set<int> _likedTrackIds = {};
  Track? _lastTrack;
  double _lastTrackProgress = 0.0;
  
  List<Track> recentSearches = [];
  Map<String, int> playCounts = {};
  
  bool isPlaying = false;
  double trackProgress = 0.0;
  bool isShuffle = false;
  bool isRepeat = false;
  
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _processingStateSub;
  
  Duration? _currentDuration;
  final _supabase = Supabase.instance.client;
  List<String> _albumNamesCache = [];
  Map<String, List<int>> _albumTracksCache = {};
  
  StreamSubscription<AuthState>? _authStateSub;
  bool get isLoggedIn => _supabase.auth.currentUser != null;
  
  int _generateStableId(String stringId) {
    int hash = 0;
    for (int i = 0; i < stringId.length; i++) {
      hash = 31 * hash + stringId.codeUnitAt(i);
    }
    return hash;
  }
  
  AppState() {
    _initAudioStreams();
    
    _authStateSub = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        loadSavedTracks();
      }
    });
    
    _restorePlaybackState().then((_) {
      requestPermissionAndFetchSongs();
    });
  }

  void _initAudioStreams() {
    DateTime lastSavedTime = DateTime.now();
    _positionSub = audioPlayer.positionStream.listen((position) {
      if (_currentDuration != null && _currentDuration!.inMilliseconds > 0) {
        trackProgress = position.inMilliseconds / _currentDuration!.inMilliseconds;
        _lastTrackProgress = trackProgress;
        notifyListeners();
      }
      final now = DateTime.now();
      if (now.difference(lastSavedTime).inSeconds >= 3) {
        lastSavedTime = now;
        _persistPosition(position.inMilliseconds);
        
        // Log playing activity periodically to save position for Continue Listening
        if (isLoggedIn && currentQueue.isNotEmpty && playingTrackIndex < currentQueue.length) {
          final current = currentQueue[playingTrackIndex];
          _recommendationService.logActivity(current, 'play', positionMs: position.inMilliseconds);
        }
      }
    });
    
    _durationSub = audioPlayer.durationStream.listen((duration) {
      _currentDuration = duration;
    });
    
    _playerStateSub = audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
      if (!state.playing) {
        _persistPosition(audioPlayer.position.inMilliseconds);
      }
    });

    _processingStateSub = audioPlayer.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        if (isLoggedIn && _lastTrack != null) {
          _recommendationService.logActivity(_lastTrack!, 'complete');
          _lastTrack = null;
          _lastTrackProgress = 0.0;
          updateRecommendationShelves();
        }
      }
    });

    audioPlayer.currentIndexStream.listen((index) {
      if (index != null && currentQueue.isNotEmpty && index < currentQueue.length) {
        final nextTrack = currentQueue[index];

        // Track skips vs completions on transition
        if (isLoggedIn && _lastTrack != null && _lastTrack!.id != nextTrack.id) {
          if (_lastTrackProgress >= 0.95) {
            _recommendationService.logActivity(_lastTrack!, 'complete');
          } else {
            _recommendationService.logActivity(_lastTrack!, 'skip', positionMs: audioPlayer.position.inMilliseconds);
          }
        }

        playingTrackIndex = index;
        _lastTrack = nextTrack;
        _lastTrackProgress = 0.0;
        notifyListeners();
        _persistPlaybackState();
        
        if (isLoggedIn) {
          _recommendationService.logActivity(nextTrack, 'play');
          updateRecommendationShelves();
        }
        
        if (nextTrack.youtubeId != null) {
          fetchRecommendations(nextTrack.youtubeId!);
        }
      }
    });
  }



  Future<void> loadSavedTracks() async {
    try {
      if (!isLoggedIn) {
        userId = null;
        userName = "Guest";
        userHandle = "Log in to save playlists";
        userProfileImage = null;
        _albumNamesCache.clear();
        _albumTracksCache.clear();
        
        // Remove non-local tracks from memory if they log out
        songsList.removeWhere((track) => !track.isImported);
        
        // Clear recommendation shelves
        continueListeningTracks.clear();
        becauseYouLikedTracks.clear();
        trendingTracks.clear();
        moreFromArtistTracks.clear();
        topTracks.clear();
        discoverTracks.clear();
        recentlyPlayedTracks.clear();
        similarGenreTracks.clear();
        usersAlsoListenToTracks.clear();
        _likedTrackIds.clear();
        
        notifyListeners();
        return;
      }

      // 1. Fetch User Data
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        userId = currentUser.id;
        userName = "Music Lover"; // Default if not found
        userHandle = "@musiclover";
        
        try {
          final userResponse = await _supabase.from('users').select().eq('id', currentUser.id).limit(1);
          if (userResponse.isNotEmpty) {
            final userData = userResponse.first;
            userName = userData['name'] ?? userName;
            userHandle = userData['handle'] ?? userHandle;
            userProfileImage = userData['profile_image_url'];
          }
        } catch (e) {
          print("Error fetching user data: $e");
        }

        // Fetch Liked Track IDs
        try {
          final likedResponse = await _supabase
              .from('user_song_stats')
              .select('track_id')
              .eq('user_id', currentUser.id)
              .eq('is_liked', true);
          _likedTrackIds.clear();
          for (var row in likedResponse) {
            _likedTrackIds.add((row['track_id'] as num).toInt());
          }
        } catch (e) {
          print("Error fetching liked track IDs: $e");
        }
        
        notifyListeners(); // Update UI with user info immediately
        
        // Refresh shelves
        updateRecommendationShelves();
      }

      // 2. Fetch albums for this user
      try {
        final albumsResponse = await _supabase.from('albums').select('name').eq('user_id', currentUser!.id);
        _albumNamesCache = albumsResponse.map((a) => a['name'] as String).toList();
        
        _albumTracksCache.clear();
        final userTrackIds = <int>{};
        
        if (_albumNamesCache.isNotEmpty) {
          // 3. Fetch album tracks
          final albumTracksResponse = await _supabase.from('album_tracks').select();
          for (var row in albumTracksResponse) {
            String albumName = row['album_name'];
            if (_albumNamesCache.contains(albumName)) {
              int trackId = row['track_id'];
              if (!_albumTracksCache.containsKey(albumName)) {
                 _albumTracksCache[albumName] = [];
              }
              _albumTracksCache[albumName]!.add(trackId);
              userTrackIds.add(trackId);
            }
          }
        }
        
        // 4. Fetch saved tracks that are in the user's albums
        if (userTrackIds.isNotEmpty) {
          final tracksResponse = await _supabase.from('saved_tracks').select();
          for (var row in tracksResponse) {
            try {
              final track = Track.fromJson(row);
              if (userTrackIds.contains(track.id)) {
                if (songsList.indexWhere((t) => t.id == track.id) == -1) {
                   songsList.add(track);
                }
              }
            } catch (e) {
              print("Error parsing saved track: $e");
            }
          }
        }
      } catch (e) {
        print("Error fetching user library: $e");
      }
      
    } catch (e) {
      print("Error loading from Supabase: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateProfile(String newName, String newHandle) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;
    
    try {
      await _supabase.from('users').upsert({
        'id': currentUser.id,
        'name': newName,
        'handle': newHandle,
      });
      userName = newName;
      userHandle = newHandle;
      notifyListeners();
    } catch (e) {
      print("Error updating profile: $e");
      rethrow;
    }
  }

  Future<void> requestPermissionAndFetchSongs() async {
    await loadSavedTracks();
    
    try {
      bool permissionStatus = await _audioQuery.permissionsRequest();
      if (!permissionStatus) {
        permissionStatus = await Permission.storage.request().isGranted;
        if (!permissionStatus) {
          // Handle permission denied
          return;
        }
      }
      
      // Request Notification Permission for Foreground Service
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      
      // Request Ignore Battery Optimization so app isn't killed while cycling
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }

      List<SongModel> songs = await _audioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final patterns = ['waves', 'vinyl', 'spheres', 'grid'];
      final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange];
      final random = math.Random();
      final localTracks = songs.where((s) => s.isMusic == true && s.data != null).map((song) {
        return Track(
          id: song.id,
          title: song.title,
          artist: song.artist ?? "Unknown Artist",
          duration: _formatDuration(song.duration),
          pattern: patterns[random.nextInt(patterns.length)],
          primaryColor: colors[random.nextInt(colors.length)],
          secondaryColor: colors[random.nextInt(colors.length)],
          isImported: true,
          uri: song.data,
        );
      }).toList();
      
      for (var localTrack in localTracks) {
        if (songsList.indexWhere((t) => t.id == localTrack.id) == -1) {
          songsList.add(localTrack);
        }
      }
    } catch (e) {
      print("Local songs fetch error: $e");
    }

    notifyListeners();
  }

  String _formatDuration(int? milliseconds) {
    if (milliseconds == null) return "00:00";
    Duration d = Duration(milliseconds: milliseconds);
    String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
  
  Track get currentTrack {
    if (currentQueue.isEmpty) {
      if (songsList.isEmpty) {
        return Track(
          id: -1, title: "No songs found", artist: "Import some music", duration: "00:00", pattern: "waves",
          primaryColor: Colors.grey, secondaryColor: Colors.black,
        );
      }
      currentQueue = List.from(songsList);
    }
    if (playingTrackIndex < 0 || playingTrackIndex >= currentQueue.length) {
      playingTrackIndex = 0;
    }
    return currentQueue[playingTrackIndex];
  }
  
  void changeTab(int index) {
    currentTab = index;
    notifyListeners();
  }
  
  void updateSearch(String query) {
    searchQuery = query;
    notifyListeners();
  }
  
  void updateFilter(String filter) {
    activeFilterChip = filter;
    notifyListeners();
  }
  
  List<String> get albumNames => _albumNamesCache;

  Future<bool> createAlbum(String name) async {
    if (!isLoggedIn) return false;
    
    if (name.trim().isEmpty) return false;
    if (!_albumNamesCache.contains(name)) {
      _albumNamesCache.add(name);
      notifyListeners();
      try {
        await _supabase.from('albums').insert({
          'name': name,
          if (userId != null) 'user_id': userId,
        });
        return true;
      } catch (e) {
        print("Error creating album in Supabase: $e");
        return false;
      }
    }
    return true;
  }

  Future<void> deleteAlbum(String name) async {
    if (_albumNamesCache.contains(name)) {
      _albumNamesCache.remove(name);
      notifyListeners();
      try {
        await _supabase.from('albums').delete().eq('name', name);
      } catch (e) {
        print("Error deleting album: $e");
      }
    }
  }

  Future<bool> addTrackToAlbum(Track track, String albumName) async {
    if (!isLoggedIn) return false;
    
    if (!_albumTracksCache.containsKey(albumName)) {
      _albumTracksCache[albumName] = [];
    }
    if (!_albumTracksCache[albumName]!.contains(track.id)) {
      _albumTracksCache[albumName]!.add(track.id);
      notifyListeners();
      try {
        // Must insert into saved_tracks first to satisfy foreign key constraint in album_tracks
        final trackJson = track.toJson();
        await _supabase.from('saved_tracks').upsert(trackJson);
        
        await _supabase.from('album_tracks').upsert({
          'album_name': albumName,
          'track_id': track.id
        });

        // Log activity
        await _recommendationService.logActivity(track, 'playlist_add');
        updateRecommendationShelves();
        
        return true;
      } catch (e) {
        print("Error adding track to album: $e");
        _albumTracksCache[albumName]!.remove(track.id);
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  Future<void> removeTrackFromAlbum(Track track, String albumName) async {
    if (_albumTracksCache.containsKey(albumName) && _albumTracksCache[albumName]!.contains(track.id)) {
      _albumTracksCache[albumName]!.remove(track.id);
      notifyListeners();
      try {
        await _supabase.from('album_tracks')
            .delete()
            .eq('album_name', albumName)
            .eq('track_id', track.id);
        
        // Log activity
        await _recommendationService.logActivity(track, 'playlist_remove');
        updateRecommendationShelves();
      } catch (e) {
        print("Error removing track from album: $e");
      }
    }
  }

  List<Track> getTracksForAlbum(String albumName) {
    List<int> trackIds = _albumTracksCache[albumName] ?? [];
    return songsList.where((track) => trackIds.contains(track.id)).toList();
  }
  
  Future<List<Track>> searchOnline(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final searchResult = await _jio.search.songs(query);
      if (searchResult != null && searchResult.results != null && searchResult.results!.isNotEmpty) {
        final songIds = searchResult.results!.map((s) => s.id!).toList();
        final List<SongResponse> detailedSongs = await _jio.songs.detailsById(songIds);
        
        final List<Track> tracks = [];
        final patterns = ['waves', 'vinyl', 'spheres', 'grid'];
        final random = math.Random();
        
        for (var song in detailedSongs) {
          String? streamUrl;
          if (song.downloadUrl != null && song.downloadUrl!.isNotEmpty) {
            streamUrl = song.downloadUrl!.last.link; // Highest quality
          }
          if (streamUrl == null) continue;
          
          String? imageUrl;
          if (song.image != null && song.image!.isNotEmpty) {
            imageUrl = song.image!.last.link; 
          }
          
          String artistName = song.primaryArtists.isNotEmpty ? song.primaryArtists : 'Unknown Artist';
          
          int durationSeconds = 0;
          try {
            durationSeconds = int.parse(song.duration);
          } catch (_) {}

          tracks.add(Track(
            id: _generateStableId(song.id),
            title: song.name ?? 'Unknown',
            artist: artistName,
            duration: _formatDuration(durationSeconds * 1000),
            pattern: patterns[random.nextInt(patterns.length)],
            primaryColor: const Color(0xFFE91E63),
            secondaryColor: const Color(0xFFF48FB1),
            isImported: false,
            uri: streamUrl, // Direct Stream URL!
            thumbnailUrl: imageUrl,
            youtubeId: song.id, // Save raw JioSaavn ID
          ));
        }
        return tracks;
      }
    } catch (e) {
      print("Error fetching from JioSaavn: $e");
    }
    return [];
  }

  Future<List<PlaylistRequest>> searchPlaylistsOnline(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _jio.search.request(
        call: 'search.getPlaylistResults',
        queryParameters: {'q': query},
      );
      final req = PlaylistSearchRequest.fromJson(response);
      return req.results;
    } catch (e) {
      print("Error searching playlists from JioSaavn: $e");
    }
    return [];
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      final response = await _jio.search.request(
        call: 'playlist.getDetails',
        queryParameters: {'listid': playlistId},
      );
      final playlist = Playlist.fromJson(response);
      final songIds = playlist.songs.map((s) => s.id!).toList();
      if (songIds.isEmpty) return [];
      
      final List<SongResponse> detailedSongs = await _jio.songs.detailsById(songIds);
      final List<Track> tracks = [];
      final patterns = ['waves', 'vinyl', 'spheres', 'grid'];
      final random = math.Random();
      
      for (var song in detailedSongs) {
        String? streamUrl;
        if (song.downloadUrl != null && song.downloadUrl!.isNotEmpty) {
          streamUrl = song.downloadUrl!.last.link; // Highest quality
        }
        if (streamUrl == null) continue;
        
        String? imageUrl;
        if (song.image != null && song.image!.isNotEmpty) {
          imageUrl = song.image!.last.link; 
        }
        
        String artistName = song.primaryArtists.isNotEmpty ? song.primaryArtists : 'Unknown Artist';
        int durationSeconds = 0;
        try {
          durationSeconds = int.parse(song.duration);
        } catch (_) {}

        tracks.add(Track(
          id: _generateStableId(song.id),
          title: song.name ?? 'Unknown',
          artist: artistName,
          duration: _formatDuration(durationSeconds * 1000),
          pattern: patterns[random.nextInt(patterns.length)],
          primaryColor: const Color(0xFFE91E63),
          secondaryColor: const Color(0xFFF48FB1),
          isImported: false,
          uri: streamUrl,
          thumbnailUrl: imageUrl,
          youtubeId: song.id, // Save raw JioSaavn ID
        ));
      }
      return tracks;
    } catch (e) {
      print("Error fetching playlist tracks: $e");
    }
    return [];
  }

  Future<void> fetchRecommendations(String songId) async {
    isLoadingRecommendations = true;
    recommendedTracks = [];
    notifyListeners();
    try {
      final res = await _jio.search.dio.get(
        "/",
        queryParameters: {
          '__call': 'reco.getreco',
          'pid': songId,
          'api_version': 4,
          '_format': 'json',
          '_marker': '0',
          'ctx': 'wap6dot0',
        },
      );
      
      var data = res.data;
      if (data is String) {
        data = jsonDecode(data);
      }
      
      if (data is List && data.isNotEmpty) {
        final List<Track> tracks = [];
        final patterns = ['waves', 'vinyl', 'spheres', 'grid'];
        final random = math.Random();
        
        for (var item in data) {
          try {
            final song = SongResponse.fromJson(item as Map<String, dynamic>);
            
            String? streamUrl;
            if (song.downloadUrl != null && song.downloadUrl!.isNotEmpty) {
              streamUrl = song.downloadUrl!.last.link;
            }
            if (streamUrl == null) continue;
            
            String? imageUrl;
            if (song.image != null && song.image!.isNotEmpty) {
              imageUrl = song.image!.last.link;
            }
            
            String artistName = song.primaryArtists.isNotEmpty ? song.primaryArtists : 'Unknown Artist';
            int durationSeconds = 0;
            try {
              durationSeconds = int.parse(song.duration);
            } catch (_) {}

            tracks.add(Track(
              id: _generateStableId(song.id),
              title: song.name ?? 'Unknown',
              artist: artistName,
              duration: _formatDuration(durationSeconds * 1000),
              pattern: patterns[random.nextInt(patterns.length)],
              primaryColor: const Color(0xFFE91E63),
              secondaryColor: const Color(0xFFF48FB1),
              isImported: false,
              uri: streamUrl,
              thumbnailUrl: imageUrl,
              youtubeId: song.id, // Save raw JioSaavn ID
            ));
          } catch (e) {
            print("Error parsing recommended song: $e");
          }
        }
        recommendedTracks = tracks;
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
    } finally {
      isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  Future<List<Track>> getRecommendationsForSong(String songId) async {
    try {
      final res = await _jio.search.dio.get(
        "/",
        queryParameters: {
          '__call': 'reco.getreco',
          'pid': songId,
          'api_version': 4,
          '_format': 'json',
          '_marker': '0',
          'ctx': 'wap6dot0',
        },
      );
      
      var data = res.data;
      if (data is String) {
        data = jsonDecode(data);
      }
      
      if (data is List && data.isNotEmpty) {
        final List<Track> tracks = [];
        final patterns = ['waves', 'vinyl', 'spheres', 'grid'];
        final random = math.Random();
        
        for (var item in data) {
          try {
            final song = SongResponse.fromJson(item as Map<String, dynamic>);
            
            String? streamUrl;
            if (song.downloadUrl != null && song.downloadUrl!.isNotEmpty) {
              streamUrl = song.downloadUrl!.last.link;
            }
            if (streamUrl == null) continue;
            
            String? imageUrl;
            if (song.image != null && song.image!.isNotEmpty) {
              imageUrl = song.image!.last.link;
            }
            
            String artistName = song.primaryArtists.isNotEmpty ? song.primaryArtists : 'Unknown Artist';
            int durationSeconds = 0;
            try {
              durationSeconds = int.parse(song.duration);
            } catch (_) {}

            tracks.add(Track(
              id: _generateStableId(song.id),
              title: song.name ?? 'Unknown',
              artist: artistName,
              duration: _formatDuration(durationSeconds * 1000),
              pattern: patterns[random.nextInt(patterns.length)],
              primaryColor: const Color(0xFFE91E63),
              secondaryColor: const Color(0xFFF48FB1),
              isImported: false,
              uri: streamUrl,
              thumbnailUrl: imageUrl,
              youtubeId: song.id,
            ));
          } catch (_) {}
        }
        return tracks;
      }
    } catch (e) {
      print("Error in getRecommendationsForSong: $e");
    }
    return [];
  }
  
  ConcatenatingAudioSource _createConcatenatingSource(List<Track> queue) {
    final audioSources = queue.map((track) {
      if (!track.isImported && track.uri != null) {
        return AudioSource.uri(
          Uri.parse(track.uri!),
          tag: MediaItem(
            id: track.id.toString(),
            album: "Online",
            title: track.title,
            artist: track.artist,
            artUri: track.thumbnailUrl != null ? Uri.parse(track.thumbnailUrl!) : null,
          ),
        );
      } else {
        return AudioSource.uri(
          Uri.file(track.uri ?? ''),
          tag: MediaItem(
            id: track.id.toString(),
            album: "Local Music",
            title: track.title,
            artist: track.artist,
          ),
        );
      }
    }).toList();

    return ConcatenatingAudioSource(children: audioSources);
  }

  Future<void> addTrackAndPlay(Track track) async {
    await incrementPlayCount(track);
    final existingIndex = songsList.indexWhere((t) => t.id == track.id);
    if (existingIndex == -1) {
      songsList.insert(0, track);
    }
    currentQueue = List.from(songsList);
    playingTrackIndex = currentQueue.indexWhere((t) => t.id == track.id);
    if (playingTrackIndex == -1) playingTrackIndex = 0;
    
    if (audioPlayer.playing) await audioPlayer.pause();
    final source = _createConcatenatingSource(currentQueue);
    await audioPlayer.setAudioSource(source, initialIndex: playingTrackIndex);
    audioPlayer.setLoopMode(isRepeat ? LoopMode.one : LoopMode.all);
    audioPlayer.setShuffleModeEnabled(isShuffle);
    audioPlayer.play();
    notifyListeners();
    _persistPlaybackState();
  }
  
  Future<void> playFromQueue(List<Track> queue, Track track) async {
    if (queue.isEmpty) return;
    await incrementPlayCount(track);
    currentQueue = List.from(queue);
    playingTrackIndex = currentQueue.indexOf(track);
    if (playingTrackIndex == -1) playingTrackIndex = 0;
    
    if (audioPlayer.playing) await audioPlayer.pause();
    final source = _createConcatenatingSource(currentQueue);
    await audioPlayer.setAudioSource(source, initialIndex: playingTrackIndex);
    audioPlayer.setLoopMode(isRepeat ? LoopMode.one : LoopMode.all);
    audioPlayer.setShuffleModeEnabled(isShuffle);
    audioPlayer.play();
    notifyListeners();
    _persistPlaybackState();
  }
  
  Future<void> shuffleQueue(List<Track> queue) async {
    if (queue.isEmpty) return;
    currentQueue = List.from(queue)..shuffle();
    isShuffle = true;
    playingTrackIndex = 0;
    
    if (currentQueue.isNotEmpty) {
      await incrementPlayCount(currentQueue[0]);
    }
    
    if (audioPlayer.playing) await audioPlayer.pause();
    final source = _createConcatenatingSource(currentQueue);
    await audioPlayer.setAudioSource(source, initialIndex: 0);
    audioPlayer.setLoopMode(isRepeat ? LoopMode.one : LoopMode.all);
    await audioPlayer.setShuffleModeEnabled(false);
    audioPlayer.play();
    notifyListeners();
    _persistPlaybackState();
  }
  
  Future<void> togglePlayPause() async {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      if (currentTrack.id != -1) {
        if (audioPlayer.processingState == ProcessingState.idle) {
          final source = _createConcatenatingSource(currentQueue);
          await audioPlayer.setAudioSource(source, initialIndex: playingTrackIndex);
        }
        audioPlayer.play();
      }
    }
    notifyListeners();
  }
  
  void nextTrack() {
    if (audioPlayer.hasNext) {
      audioPlayer.seekToNext();
    } else {
      audioPlayer.seek(Duration.zero, index: 0);
    }
  }
  
  void prevTrack() {
    if (audioPlayer.hasPrevious) {
      audioPlayer.seekToPrevious();
    } else {
      audioPlayer.seek(Duration.zero, index: currentQueue.length - 1);
    }
  }
  
  void toggleShuffle() {
    isShuffle = !isShuffle;
    audioPlayer.setShuffleModeEnabled(isShuffle);
    notifyListeners();
  }
  
  void toggleRepeat() {
    isRepeat = !isRepeat;
    audioPlayer.setLoopMode(isRepeat ? LoopMode.one : LoopMode.all);
    notifyListeners();
  }
  
  void seek(double progress) {
    trackProgress = progress;
    if (_currentDuration != null) {
      final ms = (progress * _currentDuration!.inMilliseconds).toInt();
      audioPlayer.seek(Duration(milliseconds: ms));
      _persistPosition(ms);
    }
    notifyListeners();
  }
  
  Future<void> _persistPlaybackState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = currentQueue.map((track) => track.toJson()).toList();
      await prefs.setString('saved_queue', jsonEncode(queueJson));
      await prefs.setInt('saved_track_index', playingTrackIndex);
      
      if (currentQueue.isNotEmpty && playingTrackIndex >= 0 && playingTrackIndex < currentQueue.length) {
        final current = currentQueue[playingTrackIndex];
        if (current.youtubeId != null) {
          await prefs.setString('last_online_track_id', current.youtubeId!);
        }
      }
    } catch (e) {
      print("Error persisting playback state: $e");
    }
  }

  Future<void> _persistPosition(int positionMs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('saved_position_ms', positionMs);
    } catch (e) {
      print("Error persisting position: $e");
    }
  }

  int _parseDurationStringToMs(String durationStr) {
    try {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return (minutes * 60 + seconds) * 1000;
      } else if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);
        return (hours * 3600 + minutes * 60 + seconds) * 1000;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _restorePlaybackState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString('saved_queue');
      final savedIndex = prefs.getInt('saved_track_index');
      final savedPositionMs = prefs.getInt('saved_position_ms') ?? 0;

      await _restoreRecentSearches();
      await _restorePlayCounts();
      await _restoreRecommendationShelves();

      if (queueString != null && savedIndex != null) {
        final List<dynamic> queueList = jsonDecode(queueString);
        final restoredQueue = queueList.map((item) => Track.fromJson(item)).toList();
        
        if (restoredQueue.isNotEmpty && savedIndex >= 0 && savedIndex < restoredQueue.length) {
          currentQueue = restoredQueue;
          playingTrackIndex = savedIndex;
          _lastTrack = currentQueue[playingTrackIndex];
          
          final source = _createConcatenatingSource(currentQueue);
          await audioPlayer.setAudioSource(
            source,
            initialIndex: playingTrackIndex,
            initialPosition: Duration(milliseconds: savedPositionMs),
          );
          
          final durationMs = _parseDurationStringToMs(currentTrack.duration);
          if (durationMs > 0) {
            trackProgress = savedPositionMs / durationMs;
          }
          
          notifyListeners();
        }
      }
      
      final lastOnlineId = prefs.getString('last_online_track_id');
      if (lastOnlineId != null) {
        fetchRecommendations(lastOnlineId);
      } else {
        fetchRecommendations('5WXAlMNt'); // Dynamite BTS default seed
      }
    } catch (e) {
      print("Error restoring playback state: $e");
    }
  }

  // Recommendation caching helper methods
  Future<void> _restoreRecommendationShelves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      List<Track> restoreShelf(String key) {
        final jsonStr = prefs.getString(key);
        if (jsonStr == null) return [];
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((item) => Track.fromJson(item)).toList();
      }

      continueListeningTracks = restoreShelf('shelf_continue_listening');
      becauseYouLikedTracks = restoreShelf('shelf_because_you_liked');
      trendingTracks = restoreShelf('shelf_trending');
      moreFromArtistTracks = restoreShelf('shelf_more_from_artist');
      topTracks = restoreShelf('shelf_top_songs');
      discoverTracks = restoreShelf('shelf_discover');
      recentlyPlayedTracks = restoreShelf('shelf_recently_played');
      similarGenreTracks = restoreShelf('shelf_similar_genre');
      usersAlsoListenToTracks = restoreShelf('shelf_users_also_listen_to');
      
      notifyListeners();
    } catch (e) {
      print("Error restoring recommendation shelves: $e");
    }
  }

  Future<void> _persistRecommendationShelves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      Future<void> saveShelf(String key, List<Track> tracks) async {
        final jsonStr = jsonEncode(tracks.map((t) => t.toJson()).toList());
        await prefs.setString(key, jsonStr);
      }

      await saveShelf('shelf_continue_listening', continueListeningTracks);
      await saveShelf('shelf_because_you_liked', becauseYouLikedTracks);
      await saveShelf('shelf_trending', trendingTracks);
      await saveShelf('shelf_more_from_artist', moreFromArtistTracks);
      await saveShelf('shelf_top_songs', topTracks);
      await saveShelf('shelf_discover', discoverTracks);
      await saveShelf('shelf_recently_played', recentlyPlayedTracks);
      await saveShelf('shelf_similar_genre', similarGenreTracks);
      await saveShelf('shelf_users_also_listen_to', usersAlsoListenToTracks);
    } catch (e) {
      print("Error persisting recommendation shelves: $e");
    }
  }

  Future<void> updateRecommendationShelves() async {
    final currentUid = userId;
    if (currentUid == null) return;
    
    isLoadingShelves = true;
    notifyListeners();
    
    try {
      final continueFuture = _recommendationService.getContinueListening(currentUid);
      final becauseLikedFuture = _recommendationService.getBecauseYouLiked(currentUid);
      final topSongsFuture = _recommendationService.getTopSongs(currentUid);
      final recentlyPlayedFuture = _recommendationService.getRecentlyPlayed(currentUid);
      final trendingFuture = _recommendationService.getTrendingSongs();
      final artistFuture = _recommendationService.getSongsByArtist(currentUid, songsList);
      final genreFuture = _recommendationService.getSongsByGenre(currentUid, songsList);
      final discoverFuture = _recommendationService.getDiscoverSongs(currentUid, songsList);
      final usersAlsoFuture = _recommendationService.getUsersAlsoListenTo(currentUid);
      
      final results = await Future.wait([
        continueFuture,
        becauseLikedFuture,
        topSongsFuture,
        recentlyPlayedFuture,
        trendingFuture,
        artistFuture,
        genreFuture,
        discoverFuture,
        usersAlsoFuture,
      ]);
      
      continueListeningTracks = results[0];
      becauseYouLikedTracks = results[1];
      topTracks = results[2];
      recentlyPlayedTracks = results[3];
      trendingTracks = results[4];
      moreFromArtistTracks = results[5];
      similarGenreTracks = results[6];
      discoverTracks = results[7];
      usersAlsoListenToTracks = results[8];
      
      await _persistRecommendationShelves();
    } catch (e) {
      print("Error updating recommendation shelves: $e");
    } finally {
      isLoadingShelves = false;
      notifyListeners();
    }
  }

  bool isLiked(int trackId) => _likedTrackIds.contains(trackId);

  Future<void> toggleLikeTrack(Track track) async {
    if (!isLoggedIn) return;
    final likeStatus = !_likedTrackIds.contains(track.id);
    
    if (likeStatus) {
      _likedTrackIds.add(track.id);
    } else {
      _likedTrackIds.remove(track.id);
    }
    notifyListeners();
    
    try {
      await _recommendationService.logActivity(
        track, 
        likeStatus ? 'like' : 'unlike'
      );
      
      updateRecommendationShelves();
    } catch (e) {
      print("Error toggling like: $e");
      if (likeStatus) {
        _likedTrackIds.remove(track.id);
      } else {
        _likedTrackIds.add(track.id);
      }
      notifyListeners();
    }
  }

  Future<void> addToRecentSearches(Track track) async {
    recentSearches.removeWhere((t) => t.id == track.id);
    recentSearches.insert(0, track);
    if (recentSearches.length > 10) {
      recentSearches = recentSearches.sublist(0, 10);
    }
    notifyListeners();
    await _persistRecentSearches();

    // Log activity
    if (isLoggedIn) {
      await _recommendationService.logActivity(track, 'search');
    }
  }

  Future<void> clearRecentSearches() async {
    recentSearches.clear();
    notifyListeners();
    await _persistRecentSearches();
  }

  Future<void> _persistRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = recentSearches.map((t) => t.toJson()).toList();
      await prefs.setString('recent_searches', jsonEncode(jsonList));
    } catch (e) {
      print("Error persisting recent searches: $e");
    }
  }

  Future<void> _restoreRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('recent_searches');
      if (jsonStr != null) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        recentSearches = jsonList.map((item) => Track.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Error restoring recent searches: $e");
    }
  }

  Future<void> incrementPlayCount(Track track) async {
    final key = track.id.toString();
    playCounts[key] = (playCounts[key] ?? 0) + 1;
    notifyListeners();
    await _persistPlayCounts();
  }

  List<Track> searchLocalSongs(String query) {
    if (query.trim().isEmpty) return songsList;
    return SearchEngine.search(
      query: query,
      tracks: songsList,
      playCounts: playCounts,
      recentSearches: recentSearches,
    );
  }

  Future<void> _persistPlayCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('play_counts', jsonEncode(playCounts));
    } catch (e) {
      print("Error persisting play counts: $e");
    }
  }

  Future<void> _restorePlayCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('play_counts');
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        playCounts = decoded.map((key, value) => MapEntry(key, value as int));
        notifyListeners();
      }
    } catch (e) {
      print("Error restoring play counts: $e");
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _processingStateSub?.cancel();
    _authStateSub?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }
}
