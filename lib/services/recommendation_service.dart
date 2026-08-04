import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jiosaavn/jiosaavn.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/track.dart';

/// Model representing a user's aggregate interaction statistics for a specific song.
class UserSongStats {
  final String userId;
  final int trackId;
  final int playCount;
  final int completedCount;
  final int skippedCount;
  final bool isLiked;
  final bool isInPlaylist;
  final int searchCount;
  final DateTime? lastPlayedAt;
  final int lastPositionMs;
  final Track? track;

  UserSongStats({
    required this.userId,
    required this.trackId,
    required this.playCount,
    required this.completedCount,
    required this.skippedCount,
    required this.isLiked,
    required this.isInPlaylist,
    required this.searchCount,
    this.lastPlayedAt,
    required this.lastPositionMs,
    this.track,
  });

  factory UserSongStats.fromJson(Map<String, dynamic> json, {Track? track}) {
    return UserSongStats(
      userId: json['user_id']?.toString() ?? '',
      trackId: (json['track_id'] as num).toInt(),
      playCount: (json['play_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      skippedCount: (json['skipped_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] == true,
      isInPlaylist: json['is_in_playlist'] == true,
      searchCount: (json['search_count'] as num?)?.toInt() ?? 0,
      lastPlayedAt: json['last_played_at'] != null 
          ? DateTime.tryParse(json['last_played_at'].toString()) 
          : null,
      lastPositionMs: (json['last_position_ms'] as num?)?.toInt() ?? 0,
      track: track,
    );
  }
}

/// Interface for calculating recommendation scores.
/// Allows swapping out simple heuristic scoring with AI/ML logic in the future.
abstract class RecommendationScorer {
  double calculateScore(UserSongStats stats);
}

/// Default scoring engine based on interaction weights.
class DefaultRecommendationScorer implements RecommendationScorer {
  // Weights: Like = +5, Full Play = +3, Playlist Add = +4, Repeat Play = +6, Recent Play = +2, Skip = -2
  @override
  double calculateScore(UserSongStats stats) {
    double score = 0.0;

    // 1. Like Weight (+5)
    if (stats.isLiked) score += 5.0;

    // 2. Playlist Add Weight (+4)
    if (stats.isInPlaylist) score += 4.0;

    // 3. Full Play Weight (+3 per completion)
    score += stats.completedCount * 3.0;

    // 4. Repeat Play Weight (+6 if played more than once)
    if (stats.playCount > 1) score += 6.0;

    // 5. Recent Play Weight (+2 if played within last 48 hours)
    if (stats.lastPlayedAt != null) {
      final difference = DateTime.now().difference(stats.lastPlayedAt!);
      if (difference.inHours <= 48) {
        score += 2.0;
      }
    }

    // 6. Skip Weight (-2 per skip)
    score += stats.skippedCount * -2.0;

    return score;
  }
}

/// Service that interacts with Supabase and JioSaavn to retrieve recommendations.
class RecommendationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final JioSaavnClient _jio = JioSaavnClient();
  final RecommendationScorer _scorer = DefaultRecommendationScorer();

  // Stable list of default genre tags
  static const List<String> genres = [
    'Pop', 'Rock', 'Lofi', 'Hip Hop', 'Romantic', 'Party', 'Classical'
  ];

  /// Generates a deterministic genre for a track to enable genre recommendations.
  String getGenreForTrack(Track track) {
    final index = (track.title.hashCode + track.artist.hashCode).abs() % genres.length;
    return genres[index];
  }

  /// Logs a user activity event in Supabase.
  /// Uses a high-performance DB RPC first, with a client-side query fallback.
  Future<void> logActivity(Track track, String actionType, {int positionMs = 0}) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // 1. Ensure track metadata is cached in the DB first (to satisfy FK references)
      final trackJson = track.toJson();
      await _supabase.from('saved_tracks').upsert(trackJson);

      // 2. Call Supabase RPC
      await _supabase.rpc('log_user_activity', params: {
        'p_track_id': track.id,
        'p_action_type': actionType,
        'p_position_ms': positionMs,
      });
    } catch (rpcError) {
      print("Supabase RPC log error, falling back to direct query: $rpcError");
      try {
        final userId = currentUser.id;
        final trackId = track.id;

        // Log to activity log table
        await _supabase.from('user_activity_log').insert({
          'user_id': userId,
          'track_id': trackId,
          'action_type': actionType,
          'position_ms': positionMs,
        });

        // Fetch existing stats for manual client-side upsert
        final existing = await _supabase
            .from('user_song_stats')
            .select()
            .eq('user_id', userId)
            .eq('track_id', trackId)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('user_song_stats').insert({
            'user_id': userId,
            'track_id': trackId,
            'play_count': actionType == 'play' ? 1 : 0,
            'completed_count': actionType == 'complete' ? 1 : 0,
            'skipped_count': actionType == 'skip' ? 1 : 0,
            'is_liked': actionType == 'like',
            'is_in_playlist': actionType == 'playlist_add',
            'search_count': actionType == 'search' ? 1 : 0,
            'last_played_at': actionType == 'play' ? DateTime.now().toIso8601String() : null,
            'last_position_ms': ['play', 'skip'].contains(actionType) ? positionMs : 0,
          });
        } else {
          final stats = UserSongStats.fromJson(existing);
          await _supabase.from('user_song_stats').update({
            'play_count': stats.playCount + (actionType == 'play' ? 1 : 0),
            'completed_count': stats.completedCount + (actionType == 'complete' ? 1 : 0),
            'skipped_count': stats.skippedCount + (actionType == 'skip' ? 1 : 0),
            'is_liked': actionType == 'like' ? true : (actionType == 'unlike' ? false : stats.isLiked),
            'is_in_playlist': actionType == 'playlist_add' ? true : (actionType == 'playlist_remove' ? false : stats.isInPlaylist),
            'search_count': stats.searchCount + (actionType == 'search' ? 1 : 0),
            'last_played_at': actionType == 'play' ? DateTime.now().toIso8601String() : stats.lastPlayedAt?.toIso8601String(),
            'last_position_ms': ['play', 'skip'].contains(actionType) ? positionMs : (actionType == 'complete' ? 0 : stats.lastPositionMs),
          }).eq('user_id', userId).eq('track_id', trackId);
        }
      } catch (fallbackError) {
        print("Fallback DB query failed: $fallbackError");
      }
    }
  }

  /// Helper to convert Supabase rows to a list of Tracks
  List<Track> _parseTracksFromStats(List<dynamic> rows) {
    final List<Track> tracks = [];
    for (var row in rows) {
      if (row['saved_tracks'] != null) {
        try {
          tracks.add(Track.fromJson(row['saved_tracks'] as Map<dynamic, dynamic>));
        } catch (e) {
          print("Error parsing joined track: $e");
        }
      }
    }
    return tracks;
  }

  /// 1. CONTINUE LISTENING
  /// Show recently played songs that were not finished.
  Future<List<Track>> getContinueListening(String userId) async {
    try {
      final response = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)')
          .eq('user_id', userId)
          .gt('last_position_ms', 0)
          .order('last_played_at', ascending: false)
          .limit(10);
      return _parseTracksFromStats(response);
    } catch (e) {
      print("Error in getContinueListening: $e");
      return [];
    }
  }

  /// Helper to convert JioSaavn search or recommendations to local Track format.
  List<Track> _convertSaavnTracks(List<SongResponse> detailedSongs) {
    final List<Track> tracks = [];
    final patterns = ['waves', 'vinyl', 'spheres', 'grid'];
    final random = math.Random();

    int generateStableId(String stringId) {
      int hash = 0;
      for (int i = 0; i < stringId.length; i++) {
        hash = 31 * hash + stringId.codeUnitAt(i);
      }
      return hash;
    }

    String formatDuration(int? milliseconds) {
      if (milliseconds == null) return "00:00";
      Duration d = Duration(milliseconds: milliseconds);
      String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
      String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
      return "$minutes:$seconds";
    }

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
        id: generateStableId(song.id),
        title: song.name ?? 'Unknown',
        artist: artistName,
        duration: formatDuration(durationSeconds * 1000),
        pattern: patterns[random.nextInt(patterns.length)],
        primaryColor: const Color(0xFFE91E63),
        secondaryColor: const Color(0xFFF48FB1),
        isImported: false,
        uri: streamUrl,
        thumbnailUrl: imageUrl,
        youtubeId: song.id,
      ));
    }
    return tracks;
  }

  /// 2. BECAUSE YOU LIKED
  /// Recommend songs similar to songs the user has liked.
  Future<List<Track>> getBecauseYouLiked(String userId) async {
    try {
      // Fetch user's top liked tracks
      final response = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)')
          .eq('user_id', userId)
          .eq('is_liked', true)
          .order('last_played_at', ascending: false)
          .limit(3);
      
      final likedTracks = _parseTracksFromStats(response);
      if (likedTracks.isEmpty) return [];

      final List<Track> recommendations = [];
      final Set<int> addedIds = {};

      for (var track in likedTracks) {
        if (track.youtubeId == null) continue;
        try {
          final res = await _jio.search.dio.get(
            "/",
            queryParameters: {
              '__call': 'reco.getreco',
              'pid': track.youtubeId,
              'api_version': 4,
              '_format': 'json',
              '_marker': '0',
              'ctx': 'wap6dot0',
            },
          );
          
          var data = res.data;
          if (data is String) data = jsonDecode(data);
          if (data is List && data.isNotEmpty) {
            final List<SongResponse> detailed = data.map((item) => SongResponse.fromJson(item as Map<String, dynamic>)).toList();
            final converted = _convertSaavnTracks(detailed);
            for (var rec in converted) {
              if (!addedIds.contains(rec.id) && rec.id != track.id) {
                addedIds.add(rec.id);
                recommendations.add(rec);
              }
            }
          }
        } catch (_) {}
      }
      return recommendations.take(15).toList();
    } catch (e) {
      print("Error in getBecauseYouLiked: $e");
      return [];
    }
  }

  /// 3. YOUR TOP SONGS
  /// Display the user's most-played songs.
  Future<List<Track>> getTopSongs(String userId) async {
    try {
      final response = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)')
          .eq('user_id', userId)
          .gt('play_count', 0)
          .order('play_count', ascending: false)
          .limit(20);
      return _parseTracksFromStats(response);
    } catch (e) {
      print("Error in getTopSongs: $e");
      return [];
    }
  }

  /// 4. RECENTLY PLAYED
  /// Show listening history.
  Future<List<Track>> getRecentlyPlayed(String userId) async {
    try {
      final response = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)')
          .eq('user_id', userId)
          .gt('play_count', 0)
          .order('last_played_at', ascending: false)
          .limit(20);
      return _parseTracksFromStats(response);
    } catch (e) {
      print("Error in getRecentlyPlayed: $e");
      return [];
    }
  }

  /// 5. TRENDING NOW
  /// Recommend songs that are currently popular across all users.
  Future<List<Track>> getTrendingSongs() async {
    try {
      // Fetch top plays across all users (grouped sum play_count in Dart)
      final response = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)');
      
      final playCounts = <int, int>{};
      final trackMap = <int, Track>{};

      for (var row in response) {
        if (row['saved_tracks'] != null) {
          try {
            final track = Track.fromJson(row['saved_tracks'] as Map<dynamic, dynamic>);
            final count = (row['play_count'] as num?)?.toInt() ?? 0;
            playCounts[track.id] = (playCounts[track.id] ?? 0) + count;
            trackMap[track.id] = track;
          } catch (_) {}
        }
      }

      final sortedIds = playCounts.keys.toList()
        ..sort((a, b) => playCounts[b]!.compareTo(playCounts[a]!));
      
      return sortedIds.map((id) => trackMap[id]!).take(15).toList();
    } catch (e) {
      print("Error in getTrendingSongs: $e");
      return [];
    }
  }

  /// 6. MORE FROM THIS ARTIST
  /// Recommend additional songs from artists the user frequently listens to.
  Future<List<Track>> getSongsByArtist(String userId, List<Track> allLocalSongs) async {
    try {
      // Find favorite artist (from top played songs)
      final response = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)')
          .eq('user_id', userId)
          .gt('play_count', 0)
          .order('play_count', ascending: false)
          .limit(10);
      
      final topTracks = _parseTracksFromStats(response);
      if (topTracks.isEmpty) return [];

      final artistCounts = <String, int>{};
      for (var track in topTracks) {
        artistCounts[track.artist] = (artistCounts[track.artist] ?? 0) + 1;
      }
      final sortedArtists = artistCounts.keys.toList()
        ..sort((a, b) => artistCounts[b]!.compareTo(artistCounts[a]!));
      
      if (sortedArtists.isEmpty) return [];
      final favoriteArtist = sortedArtists.first;

      // Fetch other songs by this artist
      // 1. Try local match first
      final List<Track> recommendations = [];
      recommendations.addAll(
        allLocalSongs.where((t) => t.artist.toLowerCase().contains(favoriteArtist.toLowerCase())).take(5)
      );

      // 2. Fetch online search for the artist
      try {
        final searchResult = await _jio.search.songs(favoriteArtist);
        if (searchResult.results.isNotEmpty) {
          final ids = searchResult.results.map((s) => s.id).whereType<String>().take(10).toList();
          final detailed = await _jio.songs.detailsById(ids);
          final converted = _convertSaavnTracks(detailed);
          for (var track in converted) {
            if (recommendations.indexWhere((t) => t.title.toLowerCase() == track.title.toLowerCase()) == -1) {
              recommendations.add(track);
            }
          }
        }
      } catch (_) {}

      return recommendations.take(15).toList();
    } catch (e) {
      print("Error in getSongsByArtist: $e");
      return [];
    }
  }

  /// 7. SIMILAR GENRE
  /// Recommend songs from genres the user listens to most.
  Future<List<Track>> getSongsByGenre(String userId, List<Track> allLocalSongs) async {
    try {
      // Find top genre based on top played songs
      final response = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)')
          .eq('user_id', userId)
          .gt('play_count', 0)
          .order('play_count', ascending: false)
          .limit(15);
      
      final topTracks = _parseTracksFromStats(response);
      if (topTracks.isEmpty) return [];

      final genreCounts = <String, int>{};
      for (var track in topTracks) {
        final g = getGenreForTrack(track);
        genreCounts[g] = (genreCounts[g] ?? 0) + 1;
      }
      final sortedGenres = genreCounts.keys.toList()
        ..sort((a, b) => genreCounts[b]!.compareTo(genreCounts[a]!));
      
      if (sortedGenres.isEmpty) return [];
      final favoriteGenre = sortedGenres.first;

      // Recommend songs matching this genre (via online search of genre keywords)
      final List<Track> recommendations = [];
      recommendations.addAll(
        allLocalSongs.where((t) => getGenreForTrack(t) == favoriteGenre).take(5)
      );

      // Search online for the genre term to find matching popular songs
      try {
        final searchResult = await _jio.search.songs('$favoriteGenre hits');
        if (searchResult.results.isNotEmpty) {
          final ids = searchResult.results.map((s) => s.id).whereType<String>().take(10).toList();
          final detailed = await _jio.songs.detailsById(ids);
          final converted = _convertSaavnTracks(detailed);
          for (var track in converted) {
            if (recommendations.indexWhere((t) => t.id == track.id) == -1) {
              recommendations.add(track);
            }
          }
        }
      } catch (_) {}

      return recommendations.take(15).toList();
    } catch (e) {
      print("Error in getSongsByGenre: $e");
      return [];
    }
  }

  /// 8. DISCOVER NEW MUSIC
  /// Recommend songs the user has never played but match their favorite genres and artists.
  Future<List<Track>> getDiscoverSongs(String userId, List<Track> allLocalSongs) async {
    try {
      // Find favorite artist and genre
      final response = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)')
          .eq('user_id', userId)
          .gt('play_count', 0)
          .order('play_count', ascending: false)
          .limit(20);
      
      final topTracks = _parseTracksFromStats(response);
      final playedIds = topTracks.map((t) => t.id).toSet();

      // Find top artist and top genre
      final artistCounts = <String, int>{};
      final genreCounts = <String, int>{};
      for (var track in topTracks) {
        artistCounts[track.artist] = (artistCounts[track.artist] ?? 0) + 1;
        final g = getGenreForTrack(track);
        genreCounts[g] = (genreCounts[g] ?? 0) + 1;
      }
      
      final sortedArtists = artistCounts.keys.toList()..sort((a, b) => artistCounts[b]!.compareTo(artistCounts[a]!));
      final sortedGenres = genreCounts.keys.toList()..sort((a, b) => genreCounts[b]!.compareTo(genreCounts[a]!));

      final List<Track> candidateSongs = [];

      // Fetch candidates online based on favorite artist & genre
      if (sortedArtists.isNotEmpty) {
        final artist = sortedArtists.first;
        try {
          final searchResult = await _jio.search.songs(artist);
          if (searchResult.results.isNotEmpty) {
            final ids = searchResult.results.map((s) => s.id).whereType<String>().take(5).toList();
            final detailed = await _jio.songs.detailsById(ids);
            candidateSongs.addAll(_convertSaavnTracks(detailed));
          }
        } catch (_) {}
      }

      if (sortedGenres.isNotEmpty) {
        final genre = sortedGenres.first;
        try {
          final searchResult = await _jio.search.songs(genre);
          if (searchResult.results.isNotEmpty) {
            final ids = searchResult.results.map((s) => s.id).whereType<String>().take(5).toList();
            final detailed = await _jio.songs.detailsById(ids);
            candidateSongs.addAll(_convertSaavnTracks(detailed));
          }
        } catch (_) {}
      }

      // Filter out songs already played
      final discoverSongs = candidateSongs.where((t) => !playedIds.contains(t.id)).toList();
      return discoverSongs.take(15).toList();
    } catch (e) {
      print("Error in getDiscoverSongs: $e");
      return [];
    }
  }

  /// 9. USERS ALSO LISTEN TO
  /// Collaborative filtering based on play history overlaps.
  Future<List<Track>> getUsersAlsoListenTo(String userId) async {
    try {
      // 1. Fetch user's top played songs
      final response = await _supabase
          .from('user_song_stats')
          .select('track_id')
          .eq('user_id', userId)
          .gt('play_count', 0)
          .order('play_count', ascending: false)
          .limit(3);
      
      final topTrackIds = response.map((row) => (row['track_id'] as num).toInt()).toList();
      if (topTrackIds.isEmpty) return [];

      // 2. Query other users who listened to these top songs
      final otherUsersResponse = await _supabase
          .from('user_song_stats')
          .select('user_id')
          .inFilter('track_id', topTrackIds)
          .neq('user_id', userId)
          .limit(40);
      
      final otherUserIds = otherUsersResponse.map((row) => row['user_id']?.toString()).whereType<String>().toSet().toList();
      if (otherUserIds.isEmpty) return [];

      // 3. Query top songs listened to by these overlapping users
      final otherSongsResponse = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)')
          .inFilter('user_id', otherUserIds)
          .gt('play_count', 0)
          .limit(80);
      
      // 4. Score tracks based on frequency of listens by overlapping users
      final frequencyMap = <int, int>{};
      final trackMap = <int, Track>{};

      for (var row in otherSongsResponse) {
        if (row['saved_tracks'] != null) {
          try {
            final track = Track.fromJson(row['saved_tracks'] as Map<dynamic, dynamic>);
            // Skip songs already listened to by the active user
            final userCheck = await _supabase
                .from('user_song_stats')
                .select('play_count')
                .eq('user_id', userId)
                .eq('track_id', track.id)
                .maybeSingle();
            
            if (userCheck != null && ((userCheck['play_count'] as num?)?.toInt() ?? 0) > 0) {
              continue; // Exclude songs already played
            }

            frequencyMap[track.id] = (frequencyMap[track.id] ?? 0) + 1;
            trackMap[track.id] = track;
          } catch (_) {}
        }
      }

      final sortedIds = frequencyMap.keys.toList()
        ..sort((a, b) => frequencyMap[b]!.compareTo(frequencyMap[a]!));
      
      return sortedIds.map((id) => trackMap[id]!).take(15).toList();
    } catch (e) {
      print("Error in getUsersAlsoListenTo: $e");
      return [];
    }
  }

  /// Dynamic general recommendations calculated on the client side using scorers.
  Future<List<Track>> getGeneralScoredRecommendations(String userId) async {
    try {
      final response = await _supabase
          .from('user_song_stats')
          .select('*, saved_tracks(*)')
          .eq('user_id', userId);
      
      final List<MapEntry<Track, double>> scoredTracks = [];
      for (var row in response) {
        if (row['saved_tracks'] != null) {
          try {
            final track = Track.fromJson(row['saved_tracks'] as Map<dynamic, dynamic>);
            final stats = UserSongStats.fromJson(row);
            final score = _scorer.calculateScore(stats);
            scoredTracks.add(MapEntry(track, score));
          } catch (_) {}
        }
      }

      scoredTracks.sort((a, b) => b.value.compareTo(a.value));
      return scoredTracks.map((entry) => entry.key).take(15).toList();
    } catch (e) {
      print("Error in getGeneralScoredRecommendations: $e");
      return [];
    }
  }
}
