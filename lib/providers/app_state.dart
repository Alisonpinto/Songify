import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/track.dart';
import 'dart:async';
import 'dart:math' as math;

class AppState extends ChangeNotifier {
  int currentTab = 0; // 0 = Home, 1 = Library, 2 = Now Playing
  String searchQuery = "";
  String activeFilterChip = "All Songs";
  
  List<Track> songsList = [];
  
  int playingTrackIndex = 0;
  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();
  
  bool isPlaying = false;
  double trackProgress = 0.0;
  bool isShuffle = false;
  bool isRepeat = false;
  
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playerStateSub;
  
  Duration? _currentDuration;
  final Box _favoritesBox = Hive.box('favorites');
  final Box _albumsBox = Hive.box('albums');
  
  AppState() {
    _initAudioStreams();
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

  Future<void> requestPermissionAndFetchSongs() async {
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

    songsList = songs.where((s) => s.isMusic == true && s.data != null).map((song) {
      bool isFav = _favoritesBox.get(song.id, defaultValue: false) as bool;
      return Track(
        id: song.id,
        title: song.title,
        artist: song.artist ?? "Unknown Artist",
        duration: _formatDuration(song.duration),
        pattern: patterns[random.nextInt(patterns.length)],
        primaryColor: colors[random.nextInt(colors.length)],
        secondaryColor: colors[random.nextInt(colors.length)],
        isFavorite: isFav,
        isImported: true,
        uri: song.data,
      );
    }).toList();

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
    if (songsList.isEmpty) return Track(
      id: -1, title: "No songs found", artist: "Import some music", duration: "00:00", pattern: "waves",
      primaryColor: Colors.grey, secondaryColor: Colors.black,
    );
    return songsList[playingTrackIndex];
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
  
  void toggleFavorite(Track track) {
    track.isFavorite = !track.isFavorite;
    _favoritesBox.put(track.id, track.isFavorite);
    notifyListeners();
  }
  
  List<String> get albumNames => _albumsBox.keys.cast<String>().toList();

  void createAlbum(String name) {
    if (name.trim().isEmpty) return;
    if (!_albumsBox.containsKey(name)) {
      _albumsBox.put(name, <int>[]);
      notifyListeners();
    }
  }

  void deleteAlbum(String name) {
    _albumsBox.delete(name);
    notifyListeners();
  }

  void addTrackToAlbum(Track track, String albumName) {
    List<int> trackIds = (_albumsBox.get(albumName, defaultValue: <int>[]) as List).cast<int>();
    if (!trackIds.contains(track.id)) {
      trackIds.add(track.id);
      _albumsBox.put(albumName, trackIds);
      notifyListeners();
    }
  }

  void removeTrackFromAlbum(Track track, String albumName) {
    List<int> trackIds = (_albumsBox.get(albumName, defaultValue: <int>[]) as List).cast<int>();
    if (trackIds.contains(track.id)) {
      trackIds.remove(track.id);
      _albumsBox.put(albumName, trackIds);
      notifyListeners();
    }
  }

  List<Track> getTracksForAlbum(String albumName) {
    List<int> trackIds = (_albumsBox.get(albumName, defaultValue: <int>[]) as List).cast<int>();
    return songsList.where((track) => trackIds.contains(track.id)).toList();
  }
  
  Future<List<Track>> searchOnline(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final response = await http.get(Uri.parse('https://api.audius.co/v1/tracks/search?query=${Uri.encodeComponent(query)}&app_name=SongifyApp'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['data'];
        final List<Track> tracks = [];
        
        final patterns = ['waves', 'vinyl', 'spheres', 'grid'];
        final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange];
        final random = math.Random();
        
        for (var trackData in results) {
          tracks.add(Track(
            id: trackData['id'].hashCode,
            title: trackData['title'] ?? 'Unknown',
            artist: trackData['user']?['name'] ?? 'Unknown Artist',
            duration: _formatDuration((trackData['duration'] ?? 0) * 1000), // Audius duration is in seconds
            pattern: patterns[random.nextInt(patterns.length)],
            primaryColor: colors[random.nextInt(colors.length)],
            secondaryColor: colors[random.nextInt(colors.length)],
            isFavorite: false,
            isImported: false,
            youtubeId: trackData['id'], // We'll store the Audius track ID here
            thumbnailUrl: trackData['artwork']?['150x150'] ?? trackData['artwork']?['480x480'],
          ));
        }
        return tracks;
      }
    } catch (e) {
      print("Error fetching from Audius: $e");
    }
    return [];
  }
  
  Future<void> addTrackAndPlay(Track track) async {
    // Mostly unused now since we load all songs automatically
    if (!songsList.any((t) => t.id == track.id)) {
      songsList.insert(0, track);
    }
    playingTrackIndex = songsList.indexOf(track);
    _playCurrentTrack();
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
    if (songsList.isEmpty) return;
    if (isShuffle) {
      playingTrackIndex = math.Random().nextInt(songsList.length);
    } else {
      playingTrackIndex = (playingTrackIndex + 1) % songsList.length;
    }
    _playCurrentTrack();
  }
  
  void prevTrack() {
    if (songsList.isEmpty) return;
    playingTrackIndex = playingTrackIndex - 1 < 0 ? songsList.length - 1 : playingTrackIndex - 1;
    _playCurrentTrack();
  }
  
  void _playCurrentTrack() async {
    if (currentTrack.id == -1) return;
    try {
      AudioSource? source;
      
      if (currentTrack.youtubeId != null) {
        currentTrack.uri = 'https://api.audius.co/v1/tracks/${currentTrack.youtubeId}/stream?app_name=SongifyApp';

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
    audioPlayer.dispose();
    super.dispose();
  }
}

