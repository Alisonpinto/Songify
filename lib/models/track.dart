import 'package:flutter/material.dart';

class Track {
  final int id;
  final String title;
  final String artist;
  final String duration;
  final String pattern;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isImported;
  String? uri; // We use path string for uri or http url
  // We can't directly store ImageBitmap like Compose, we can store bytes
  final List<int>? artworkBytes;
  
  final String? youtubeId;
  final String? thumbnailUrl;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.pattern,
    required this.primaryColor,
    required this.secondaryColor,
    this.isImported = false,
    this.uri,
    this.artworkBytes,
    this.youtubeId,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration': duration,
      'pattern': pattern,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'isImported': isImported,
      'uri': uri,
      'youtubeId': youtubeId,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory Track.fromJson(Map<dynamic, dynamic> json) {
    return Track(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? 'Unknown',
      artist: json['artist']?.toString() ?? 'Unknown',
      duration: json['duration']?.toString() ?? '00:00',
      pattern: json['pattern']?.toString() ?? 'waves',
      primaryColor: Color((json['primaryColor'] as num).toInt()),
      secondaryColor: Color((json['secondaryColor'] as num).toInt()),
      isImported: json['isImported'] == true,
      uri: json['uri']?.toString(),
      youtubeId: json['youtubeId']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
    );
  }
}
