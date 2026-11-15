import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ─────────────────────────────────────────────────────────────────────────
///  YOUTUBE CHANNEL FEED — YouTube Data API v3
///
///  The owner pastes (a) their channel handle e.g. "@SadatMejlis" or a
///  channel id "UCxxxx..." and (b) a free YouTube Data API key in the admin
///  Social Links screen. The Media Hub then lists the channel's uploads
///  automatically — when they post on YouTube, the app shows it.
///
///  TikTok/Instagram/Facebook have no open feed API, so those tabs in the
///  Media Hub show the admin-tagged posts uploaded through the app's own
///  post composer (photo or video), plus a button that opens the real
///  channel. This is documented in the admin screen as well.
/// ─────────────────────────────────────────────────────────────────────────

class YouTubeVideo {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String publishedAt;
  final String description;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.publishedAt,
    this.description = '',
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
}

class YouTubeService {
  static const String _base = 'https://www.googleapis.com/youtube/v3';
  static const Duration _timeout = Duration(seconds: 10);

  /// Accepts "@handle", "handle", full channel URLs, or "UC..." channel ids.
  static String? extractChannelRef(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    // Full URL forms
    final uri = Uri.tryParse(s.startsWith('http') ? s : 'https://$s');
    if (uri != null && (uri.host.contains('youtube.com') || uri.host.contains('youtu.be'))) {
      // youtube.com/@handle
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first.startsWith('@')) {
        return uri.pathSegments.first; // "@handle"
      }
      // youtube.com/channel/UCxxxx
      final idx = uri.pathSegments.indexOf('channel');
      if (idx != -1 && idx + 1 < uri.pathSegments.length) {
        return uri.pathSegments[idx + 1];
      }
      // youtube.com/c/Name or /user/Name — not resolvable via API directly
    }
    if (s.startsWith('UC') && s.length >= 20) return s;
    if (s.startsWith('@')) return s;
    if (s.contains(' ')) return null;
    return '@$s';
  }

  /// Resolves a channel ref to its uploads playlist id.
  Future<String> resolveUploadsPlaylist({
    required String channelRef,
    required String apiKey,
  }) async {
    final isChannelId = channelRef.startsWith('UC') && !channelRef.startsWith('@');
    final uri = isChannelId
        ? Uri.parse('$_base/channels?part=contentDetails&id=$channelRef&key=$apiKey')
        : Uri.parse('$_base/channels?part=contentDetails&forHandle=${Uri.encodeComponent(channelRef)}&key=$apiKey');

    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('YouTube API error ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    final items = data['items'] as List?;
    if (items == null || items.isEmpty) {
      throw Exception('Channel not found');
    }
    final uploads = items.first['contentDetails']['relatedPlaylists']['uploads'];
    if (uploads == null || uploads.toString().isEmpty) {
      throw Exception('No public uploads playlist');
    }
    return uploads.toString();
  }

  /// Latest uploads of a channel's uploads playlist.
  Future<List<YouTubeVideo>> fetchVideos({
    required String uploadsPlaylistId,
    required String apiKey,
    int maxResults = 24,
  }) async {
    final uri = Uri.parse(
      '$_base/playlistItems?part=snippet,contentDetails'
      '&playlistId=$uploadsPlaylistId&maxResults=${maxResults.clamp(1, 50)}&key=$apiKey',
    );
    final res = await http.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('YouTube API error ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    final items = (data['items'] as List?) ?? [];
    final videos = <YouTubeVideo>[];
    for (final item in items) {
      try {
        final snippet = item['snippet'];
        final videoId = item['contentDetails']['videoId']?.toString() ?? '';
        if (videoId.isEmpty) continue;
        final thumbs = snippet['thumbnails'] as Map<String, dynamic>?;
        String thumb = '';
        for (final q in ['maxres', 'high', 'medium', 'default']) {
          if (thumbs != null && thumbs[q] != null) {
            thumb = thumbs[q]['url'].toString();
            break;
          }
        }
        // Privacy-deleted items have odd titles — keep them but they simply
        // render with fallback art.
        videos.add(YouTubeVideo(
          videoId: videoId,
          title: snippet['title']?.toString() ?? '',
          thumbnailUrl: thumb,
          publishedAt: snippet['publishedAt']?.toString() ?? '',
          description: snippet['description']?.toString() ?? '',
        ));
      } catch (e) {
        debugPrint('Skipping malformed YouTube item: $e');
      }
    }
    return videos;
  }
}
