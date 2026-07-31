import 'dart:math' as math;
import '../models/track.dart';

class SearchEngine {
  /// Computes the Levenshtein distance between two strings.
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v0[t.length];
  }

  static int _min3(int a, int b, int c) {
    int m = a < b ? a : b;
    return m < c ? m : c;
  }

  /// Searches and ranks [tracks] based on [query].
  static List<Track> search({
    required String query,
    required List<Track> tracks,
    required Map<String, int> playCounts,
    required List<Track> recentSearches,
  }) {
    final cleanedQuery = query.trim().toLowerCase();
    if (cleanedQuery.isEmpty) return tracks;

    final queryWords = cleanedQuery.split(RegExp(r'\s+'));
    final List<MapEntry<Track, double>> scoredTracks = [];

    for (var track in tracks) {
      double score = 0.0;
      final title = track.title.toLowerCase();
      final artist = track.artist.toLowerCase();

      // 1. RELEVANCE SCORES
      
      // Exact matches
      if (title == cleanedQuery) {
        score += 150.0;
      } else if (title.startsWith(cleanedQuery)) {
        score += 80.0;
      } else if (title.contains(cleanedQuery)) {
        score += 50.0;
      }

      if (artist == cleanedQuery) {
        score += 100.0;
      } else if (artist.contains(cleanedQuery)) {
        score += 30.0;
      }

      // Word-level matching
      for (var word in queryWords) {
        if (title.contains(word)) {
          score += 15.0;
        }
        if (artist.contains(word)) {
          score += 8.0;
        }
      }

      // Typo-tolerance (Levenshtein)
      // Only do typo matching if query is somewhat long
      if (cleanedQuery.length >= 3) {
        // Compare query with track title
        final titleDistance = _levenshtein(cleanedQuery, title);
        final maxLenTitle = math.max(cleanedQuery.length, title.length);
        final titleSimilarity = 1.0 - (titleDistance / maxLenTitle);

        if (titleSimilarity > 0.6) {
          score += titleSimilarity * 40.0;
        }

        // Compare query with artist
        final artistDistance = _levenshtein(cleanedQuery, artist);
        final maxLenArtist = math.max(cleanedQuery.length, artist.length);
        final artistSimilarity = 1.0 - (artistDistance / maxLenArtist);

        if (artistSimilarity > 0.6) {
          score += artistSimilarity * 25.0;
        }
        
        // Word level typo tolerance
        final titleWords = title.split(RegExp(r'\s+'));
        for (var tWord in titleWords) {
          if (tWord.length >= 3) {
            for (var qWord in queryWords) {
              if (qWord.length >= 3) {
                final wordDist = _levenshtein(qWord, tWord);
                final maxWLen = math.max(qWord.length, tWord.length);
                final wordSim = 1.0 - (wordDist / maxWLen);
                if (wordSim > 0.7) {
                  score += wordSim * 15.0;
                }
              }
            }
          }
        }
      }

      // 2. POPULARITY SCORE (Play counts)
      final playCount = playCounts[track.id.toString()] ?? 0;
      if (playCount > 0) {
        // Logarithmic scale so high play counts don't dominate completely
        score += math.log(playCount + 1) * 12.0;
      }

      // 3. HISTORY BOOST (Recent searches)
      final recentIndex = recentSearches.indexWhere((t) => t.id == track.id);
      if (recentIndex != -1) {
        // Higher boost for more recent searches
        score += (10 - recentIndex).clamp(0, 10) * 3.0;
      }

      // Only include if there is some level of match
      if (score > 5.0) {
        scoredTracks.add(MapEntry(track, score));
      }
    }

    // Sort by score in descending order
    scoredTracks.sort((a, b) => b.value.compareTo(a.value));

    return scoredTracks.map((entry) => entry.key).toList();
  }
}
