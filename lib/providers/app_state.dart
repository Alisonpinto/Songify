import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jiosaavn/jiosaavn.dart';
import '../models/track.dart';
import 'dart:async';
import 'dart:math' as math;

class AppState extends ChangeNotifier {
  int currentTab = 0; // 0 = Home, 1 = Library, 2 = Now Playing
  String searchQuery = "";
  String activeFilterChip = "All Songs";
  
  // User Profile Data
  String? userId;
  String userName = "Music Lover";
  String userHandle = "@musiclover";
  String? userProfileImage;
  
  List<Track> songsList = [];
  List<Track> currentQueue = [];
  
  int playingTrackIndex = 0;
  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final JioSaavnClient _jio = JioSaavnClient();
  
  bool isPlaying = false;
  double trackProgress = 0.0;
  bool isShuffle = false;
  bool isRepeat = false;
  
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playerStateSub;
  
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
    
    requestPermissionAndFetchSongs();
  }

  void _initAudioStreams() {
    _positionSub = audioPlayer.positionStream.listen((position) {
      if (_currentDuration != null && _currentDuration!.inMilliseconds > 0) {
        trackProgress = position.inMilliseconds / _currentDuration!.inMilliseconds;
        notifyListeners();
      }
    });
    
    _durationSub = audioPlayer.durationStream.listen((duration) {
      _currentDuration = duration;
    });
    
    _playerStateSub = audioPlayer.playerStateStream.listen((state) {
      isPlaying = state.playing;
      
      if (state.processingState == ProcessingState.completed) {
        handleTrackEnd();
      }
      notifyListeners();
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
        notifyListeners(); // Update UI with user info immediately
      }

      // 2. Fetch saved tracks (only tracks that are in albums)
      final tracksResponse = await _supabase.from('saved_tracks').select();
      for (var row in tracksResponse) {
        try {
          final track = Track.fromJson(row);
          if (songsList.indexWhere((t) => t.id == track.id) == -1) {
             songsList.add(track);
          }
        } catch (e) {
          print("Error parsing saved track: $e");
        }
      }
      
      // 3. Fetch albums and their tracks
      try {
        final albumsResponse = await _supabase.from('albums').select('name');
        _albumNamesCache = albumsResponse.map((a) => a['name'] as String).toList();
        
        final albumTracksResponse = await _supabase.from('album_tracks').select();
        _albumTracksCache.clear();
        for (var row in albumTracksResponse) {
          String albumName = row['album_name'];
          int trackId = row['track_id'];
          if (!_albumTracksCache.containsKey(albumName)) {
             _albumTracksCache[albumName] = [];
          }
          _albumTracksCache[albumName]!.add(trackId);
        }
      } catch (e) {
        print("Error fetching albums: $e");
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
          ));
        }
        return tracks;
      }
    } catch (e) {
      print("Error fetching from JioSaavn: $e");
    }
    return [];
  }
  
  Future<void> addTrackAndPlay(Track track) async {
    final existingIndex = songsList.indexWhere((t) => t.id == track.id);
    if (existingIndex == -1) {
      songsList.insert(0, track);
    }
    currentQueue = List.from(songsList);
    playingTrackIndex = currentQueue.indexWhere((t) => t.id == track.id);
    if (playingTrackIndex == -1) playingTrackIndex = 0;
    
    if (audioPlayer.playing) await audioPlayer.pause();
    _playCurrentTrack();
    notifyListeners();
  }
  
  void playFromQueue(List<Track> queue, Track track) {
    if (queue.isEmpty) return;
    currentQueue = List.from(queue);
    playingTrackIndex = currentQueue.indexOf(track);
    if (playingTrackIndex == -1) playingTrackIndex = 0;
    
    if (audioPlayer.playing) audioPlayer.pause();
    _playCurrentTrack();
    notifyListeners();
  }
  
  void shuffleQueue(List<Track> queue) {
    if (queue.isEmpty) return;
    currentQueue = List.from(queue);
    isShuffle = true;
    playingTrackIndex = math.Random().nextInt(currentQueue.length);
    
    if (audioPlayer.playing) audioPlayer.pause();
    _playCurrentTrack();
    notifyListeners();
  }
  
  void togglePlayPause() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      if (currentTrack.uri != null && currentTrack.id != -1) {
        if (audioPlayer.processingState == ProcessingState.idle) {
          _playCurrentTrack();
        } else {
          audioPlayer.play();
        }
      }
    }
    notifyListeners();
  }
  
  void nextTrack() {
    if (currentQueue.isEmpty) return;
    if (isShuffle) {
      playingTrackIndex = math.Random().nextInt(currentQueue.length);
    } else {
      playingTrackIndex = (playingTrackIndex + 1) % currentQueue.length;
    }
    _playCurrentTrack();
  }
  
  void prevTrack() {
    if (currentQueue.isEmpty) return;
    playingTrackIndex = playingTrackIndex - 1 < 0 ? currentQueue.length - 1 : playingTrackIndex - 1;
    _playCurrentTrack();
  }
  
  void _playCurrentTrack() async {
    if (currentTrack.id == -1) return;
    try {
      AudioSource? source;
      
      if (!currentTrack.isImported && currentTrack.uri != null) {
        // Online tracks from JioSaavn provide direct streaming URLs
        source = AudioSource.uri(
          Uri.parse(currentTrack.uri!),
          tag: MediaItem(
            id: currentTrack.id.toString(),
            album: "Online",
            title: currentTrack.title,
            artist: currentTrack.artist,
            artUri: currentTrack.thumbnailUrl != null ? Uri.parse(currentTrack.thumbnailUrl!) : null,
          ),
        );
      } else if (currentTrack.uri != null) {
        source = AudioSource.uri(
          Uri.file(currentTrack.uri!),
          tag: MediaItem(
            id: currentTrack.id.toString(),
            album: "Local Music",
            title: currentTrack.title,
            artist: currentTrack.artist,
          ),
        );
      }
      
      if (source == null) return;

      await audioPlayer.setAudioSource(source);
      audioPlayer.play();
    } catch (e) {
      print("Error loading audio: $e");
    }
    notifyListeners();
  }
  
  void handleTrackEnd() {
    if (isRepeat) {
      audioPlayer.seek(Duration.zero);
      audioPlayer.play();
    } else {
      nextTrack();
    }
  }
  
  void toggleShuffle() {
    isShuffle = !isShuffle;
    notifyListeners();
  }
  
  void toggleRepeat() {
    isRepeat = !isRepeat;
    notifyListeners();
  }
  
  void seek(double progress) {
    trackProgress = progress;
    if (_currentDuration != null) {
      final ms = (progress * _currentDuration!.inMilliseconds).toInt();
      audioPlayer.seek(Duration(milliseconds: ms));
    }
    notifyListeners();
  }
  
  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _authStateSub?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }
}
