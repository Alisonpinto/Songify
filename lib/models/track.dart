import 'package:flutter/material.dart';

class Track {
  final int id;
  final String title;
  final String artist;
  final String duration;
  final String pattern;
  final Color primaryColor;
  final Color secondaryColor;
  bool isFavorite;
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
    this.isFavorite = false,
    this.isImported = false,
    this.uri,
    this.artworkBytes,
    this.youtubeId,
    this.thumbnailUrl,
  });
}
