import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_stock/data/services/youtube_service.dart';

void _log(String m) => debugPrint('[FEED] $m');

class FeedItem {
  final String id, title, url, imageUrl, source;
  final DateTime? date;
  final bool isVideo;
  FeedItem({
    required this.id,
    required this.title,
    required this.url,
    this.imageUrl = '',
    this.source = '',
    this.date,
    this.isVideo = false,
  });
}

/// Result of loading ONE channel / feed source.
class FeedResult {
  final String link;          // the saved link or feed URL
  final List<FeedItem> items;
  final Object? error;        // non-null when this source failed
  const FeedResult(this.link, this.items, [this.error]);

  /// Channel name reported by the feed ('' when unknown).
  String get name =>
      items.isNotEmpty && items.first.source.isNotEmpty ? items.first.source : '';
}

class ChannelFeedService {
  static const _headers = {
    'User-Agent':
    'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
    'Cookie': 'CONSENT=YES+1',
  };

  // Static so the resolved channel id survives widget rebuilds.
  static final Map<String, String> _idCache = {};

  static bool supports(String platform) =>
      const {'youtube', 'telegram', 'tiktok', 'instagram', 'facebook'}.contains(platform);

  Future<List<FeedItem>> fetch(String platform, String link,
      {String youtubeApiKey = ''}) async {
    _log('fetch start platform=$platform rawLink="$link"');
    final sw = Stopwatch()..start();
    try {
      final items = platform == 'youtube'
          ? await _youtube(link, youtubeApiKey)
          : platform == 'telegram'
          ? await _telegram(link)
          : await _feed(link);
      _log('fetch OK platform=$platform items=${items.length} in ${sw.elapsedMilliseconds}ms');
      for (final i in items.take(3)) {
        _log('  sample: id=${i.id} date=${i.date} title="${_short(i.title)}" img=${i.imageUrl.isNotEmpty}');
      }
      return items;
    } catch (e, st) {
      _log('fetch FAILED platform=$platform after ${sw.elapsedMilliseconds}ms: $e');
      _log('stack: ${st.toString().split('\n').take(4).join(' | ')}');
      rethrow;
    }
  }

  String _short(String s) => s.length > 60 ? '${s.substring(0, 60)}...' : s;

  /// Fetches every source in parallel and merges them newest-first.
  /// Only throws when ALL sources fail, so one broken channel doesn't
  /// hide the others.
  Future<List<FeedItem>> fetchMany(String platform, List<String> sources,
      {String youtubeApiKey = ''}) async {
    Object? lastError;
    var failures = 0;
    final lists = await Future.wait<List<FeedItem>>(sources.map((s) async {
      try {
        return await fetch(platform, s, youtubeApiKey: youtubeApiKey);
      } catch (e) {
        failures++;
        lastError = e;
        return <FeedItem>[];
      }
    }));
    if (failures == sources.length && lastError != null) throw lastError!;

    final all = lists.expand((l) => l).toList()
      ..sort((a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)));
    return all;
  }


  Future<List<FeedResult>> fetchEach(String platform, List<String> sources,
      {String youtubeApiKey = ''}) {
    return Future.wait<FeedResult>(sources.map((s) async {
      try {
        final items = await fetch(platform, s, youtubeApiKey: youtubeApiKey);
        items.sort((a, b) =>
            (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)));
        return FeedResult(s, items);
      } catch (e) {
        return FeedResult(s, const <FeedItem>[], e);
      }
    }));
  }
  // ─────────────── Generic RSS / Atom / JSON Feed (TikTok, Instagram, Facebook) ───────────────

  Future<List<FeedItem>> _feed(String link) async {
    final url = link.startsWith('http') ? link : 'https://$link';
    _log('feed: GET $url');
    final res = await http.get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _log('feed: status=${res.statusCode} bytes=${res.bodyBytes.length}');
    if (res.statusCode != 200) throw Exception('Feed error ${res.statusCode}');
    final body = utf8.decode(res.bodyBytes, allowMalformed: true);
    return body.trimLeft().startsWith('{') ? _parseJsonFeed(body) : _parseXmlFeed(body);
  }

  String _s(dynamic v) => v?.toString() ?? '';
  String _first(List<String> c) => c.firstWhere((e) => e.trim().isNotEmpty, orElse: () => '');
  String _plain(String s) =>
      _unescape(_unescape(s).replaceAll(RegExp(r'<[^>]+>'), '')).trim();
  String _firstImg(String html) =>
      RegExp(r'''<img[^>]+src=["']([^"']+)["']''').firstMatch(_unescape(html))?.group(1) ?? '';

  DateTime? _parseDate(String s) {
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    // RFC-822, e.g. "Tue, 10 Jun 2025 12:00:00 +0000" (RSS pubDate)
    final m = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?')
        .firstMatch(s);
    if (m == null) return null;
    const months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
    final mon = months.indexOf(m.group(2)!.toLowerCase()) + 1;
    if (mon == 0) return null;
    return DateTime.utc(int.parse(m.group(3)!), mon, int.parse(m.group(1)!),
        int.parse(m.group(4)!), int.parse(m.group(5)!), int.parse(m.group(6) ?? '0'));
  }

  List<FeedItem> _parseJsonFeed(String body) {
    final data = jsonDecode(body);
    final source = _plain(_s(data['title']));
    final out = <FeedItem>[];
    for (final raw in (data['items'] as List?) ?? const []) {
      final i = raw as Map<String, dynamic>;
      final html = _s(i['content_html']);
      final url = _first([_s(i['url']), _s(i['external_url'])]);
      if (url.isEmpty) continue;
      out.add(FeedItem(
        id: _first([_s(i['id']), url]),
        title: _plain(_first([_s(i['title']), _s(i['content_text']), html])),
        url: url,
        imageUrl: _first([_s(i['image']), _s(i['banner_image']), _firstImg(html)]),
        source: source,
        date: _parseDate(_s(i['date_published'])),
        isVideo: url.contains('/video/') || url.contains('/reel'),
      ));
    }
    return out;
  }

  List<FeedItem> _parseXmlFeed(String xml) {
    String? tag(String src, String name) {
      final m = RegExp('<$name(?:\\s[^>]*)?>(.*?)</$name>', dotAll: true).firstMatch(src);
      return m?.group(1)?.replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '').trim();
    }

    String? attr(String src, String name, String attribute) =>
        RegExp('<$name\\b[^>]*\\b$attribute="([^"]+)"').firstMatch(src)?.group(1);

    final head = xml.split(RegExp(r'<(?:item|entry)[\s>]')).first;
    final source = _plain(tag(head, 'title') ?? '');
    final out = <FeedItem>[];

    for (final m in RegExp(r'<(item|entry)[\s>](.*?)</\1>', dotAll: true).allMatches(xml)) {
      final b = m.group(2)!;
      // XML escapes '&' as '&amp;' inside URLs: decode it, otherwise signed
      // image links (TikTok) are corrupted and return 403.
      final url = _unescape(attr(b, 'link', 'href') ?? tag(b, 'link') ?? '');
      if (url.isEmpty) continue;
      final text = tag(b, 'description') ?? tag(b, 'content') ?? tag(b, 'summary') ?? '';
      final img = _unescape(attr(b, 'media:content', 'url') ??
          attr(b, 'media:thumbnail', 'url') ??
          attr(b, 'enclosure', 'url') ??
          _firstImg(text));
      out.add(FeedItem(
        id: tag(b, 'guid') ?? tag(b, 'id') ?? url,
        title: _plain(tag(b, 'title') ?? text),
        url: url,
        imageUrl: img,
        source: source,
        date: _parseDate(tag(b, 'pubDate') ?? tag(b, 'published') ??
            tag(b, 'updated') ?? tag(b, 'dc:date') ?? ''),
        isVideo: b.contains('medium="video"') || b.contains('type="video') ||
            url.contains('/video/') || url.contains('/reel'),
      ));
    }
    return out;
  }

  String _normalize(String platform, String link) {
    final l = link.trim();
    String out;
    if (l.startsWith('http://') || l.startsWith('https://')) {
      out = l;
    } else if (platform == 'youtube') {
      if (l.startsWith('@')) {
        out = 'https://www.youtube.com/$l';
      } else if (RegExp(r'^UC[\w-]{22}$').hasMatch(l)) {
        out = 'https://www.youtube.com/channel/$l';
      } else if (l.contains('youtube.com') || l.contains('youtu.be')) {
        out = 'https://$l';
      } else {
        out = 'https://www.youtube.com/@$l';
      }
    } else if (platform == 'telegram') {
      out = l.contains('t.me/') ? 'https://$l' : 'https://t.me/${l.replaceFirst('@', '')}';
    } else {
      out = 'https://$l';
    }
    _log('normalize $platform "$link" -> "$out"');
    return out;
  }

  // ───────────────────────── YouTube ─────────────────────────

  String? _videoId(String url) {
    final u = Uri.parse(url);
    if (u.host.contains('youtu.be')) {
      return u.pathSegments.isNotEmpty ? u.pathSegments.first : null;
    }
    if (u.queryParameters['v'] != null) return u.queryParameters['v'];
    final s = u.pathSegments;
    if (s.length >= 2 && (s[0] == 'shorts' || s[0] == 'live' || s[0] == 'embed')) {
      return s[1];
    }
    if (s.length == 1 && RegExp(r'^[\w-]{11}$').hasMatch(s[0])) return s[0];
    return null;
  }

  /// Streams the channel page and stops as soon as the channel id appears,
  /// so we never download the whole (very large) page.
  Future<String?> _scanForChannelId(String url) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url))..headers.addAll(_headers);
      final resp = await client.send(req).timeout(const Duration(seconds: 30));
      _log('youtube: page status=${resp.statusCode} finalUrl=${resp.request?.url}');
      if (resp.statusCode != 200) {
        throw Exception('YouTube page error ${resp.statusCode} for $url');
      }

      final patterns = <String, RegExp>{
        'canonical': RegExp(
            r'rel="canonical" href="https://www\.youtube\.com/channel/(UC[\w-]{22})"'),
        'itemprop': RegExp(r'itemprop="(?:channelId|identifier)" content="(UC[\w-]{22})"'),
        'channelId': RegExp(r'"channelId":"(UC[\w-]{22})"'),
        'externalId': RegExp(r'"externalId":"(UC[\w-]{22})"'),
        'channel_id=': RegExp(r'channel_id=(UC[\w-]{22})'),
      };

      var window = '';
      var bytes = 0;
      await for (final chunk in resp.stream.timeout(const Duration(seconds: 30))) {
        bytes += chunk.length;
        window += utf8.decode(chunk, allowMalformed: true);
        for (final e in patterns.entries) {
          final m = e.value.firstMatch(window);
          if (m != null) {
            _log('youtube: found id via "${e.key}" after only $bytes bytes');
            return m.group(1);
          }
        }
        // keep only a small overlap so matches split across chunks still work
        if (window.length > 200) window = window.substring(window.length - 200);
      }
      _log('youtube: stream ended after $bytes bytes, no id found');
      return null;
    } finally {
      client.close();
    }
  }

  Future<String> _youtubeChannelId(String link) async {
    var url = _normalize('youtube', link);

    final direct = RegExp(r'/channel/(UC[\w-]{22})').firstMatch(url);
    if (direct != null) {
      _log('youtube: channel id taken directly from link: ${direct.group(1)}');
      return direct.group(1)!;
    }

    // A video link: find the video's channel through oEmbed.
    final vid = _videoId(url);
    if (vid != null) {
      _log('youtube: link is a VIDEO ($vid), resolving its channel via oEmbed');
      final r = await http
          .get(Uri.parse(
          'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$vid&format=json'))
          .timeout(const Duration(seconds: 30));
      _log('youtube: oembed status=${r.statusCode}');
      final author = r.statusCode == 200
          ? RegExp(r'"author_url":"([^"]+)"').firstMatch(r.body)?.group(1)
          : null;
      if (author == null) {
        throw Exception('That looks like a video link and its channel could not be found. '
            'Use your channel link: youtube.com/@yourhandle');
      }
      url = author.replaceAll(r'\/', '/');
      _log('youtube: video belongs to channel page $url');
    }

    if (_idCache[url] != null) {
      _log('youtube: channel id from cache: ${_idCache[url]}');
      return _idCache[url]!;
    }

    _log('youtube: scanning $url for channel id');
    final id = await _scanForChannelId(url);
    if (id == null) {
      throw Exception('Could not find the YouTube channel id at $url. '
          'Use https://youtube.com/channel/UC... instead.');
    }
    _log('youtube: >>> PERMANENT LINK, put this in Social Links: https://youtube.com/channel/$id');
    return _idCache[url] = id;
  }

  Future<List<FeedItem>> _youtube(String link, String apiKey) async {
    final id = await _youtubeChannelId(link);
    final feedUrl = 'https://www.youtube.com/feeds/videos.xml?channel_id=$id';

    // YouTube's RSS endpoint sometimes answers 404/5xx for hours:
    // retry briefly, then fall back to the official API if a key is saved.
    http.Response? res;
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      _log('youtube: GET $feedUrl (attempt $attempt)');
      try {
        res = await http.get(Uri.parse(feedUrl), headers: _headers)
            .timeout(const Duration(seconds: 20));
        _log('youtube: feed status=${res.statusCode} bytes=${res.bodyBytes.length}');
        if (res.statusCode == 200) break;
      } catch (e) {
        lastError = e;
        _log('youtube: feed request failed: $e');
      }
      if (attempt < 3) await Future.delayed(Duration(milliseconds: 600 * attempt));
    }

    if (res == null || res.statusCode != 200) {
      if (apiKey.isNotEmpty) {
        _log('youtube: RSS unavailable, falling back to YouTube Data API');
        return _youtubeViaApi(id, apiKey);
      }
      _log('youtube: RSS unavailable and no API key saved (admin Social Links > YouTube API key)');
      if (res == null && lastError != null) throw lastError!;
      throw Exception('YouTube feed error ${res?.statusCode}');
    }

    String? tag(String src, String name) =>
        RegExp('<$name>(.*?)</$name>', dotAll: true).firstMatch(src)?.group(1);

    final channelTitle = _unescape(tag(res.body.split('<entry>').first, 'title') ?? '');
    final entries =
    RegExp(r'<entry>(.*?)</entry>', dotAll: true).allMatches(res.body).toList();
    _log('youtube: <entry> blocks found=${entries.length}');
    return entries.map((m) {
      final e = m.group(1)!;
      final vid = tag(e, 'yt:videoId') ?? '';
      return FeedItem(
        id: vid,
        title: _unescape(tag(e, 'title') ?? ''),
        url: 'https://www.youtube.com/watch?v=$vid',
        imageUrl: 'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
        source: channelTitle,
        date: DateTime.tryParse(tag(e, 'published') ?? ''),
        isVideo: true,
      );
    }).where((i) => i.id.isNotEmpty).toList();
  }

  Future<List<FeedItem>> _youtubeViaApi(String channelId, String apiKey) async {
    // A channel's uploads playlist id is its channel id with "UC" swapped for "UU".
    final playlist = 'UU${channelId.substring(2)}';
    final videos = await YouTubeService().fetchVideos(
      uploadsPlaylistId: playlist,
      apiKey: apiKey,
    );
    _log('youtube: API returned ${videos.length} videos');
    return videos
        .map((v) => FeedItem(
      id: v.videoId,
      title: v.title,
      url: v.watchUrl,
      imageUrl: v.thumbnailUrl.isNotEmpty
          ? v.thumbnailUrl
          : 'https://i.ytimg.com/vi/${v.videoId}/hqdefault.jpg',
      date: DateTime.tryParse(v.publishedAt),
      isVideo: true,
    ))
        .toList();
  }

  // ───────────────────────── Telegram ─────────────────────────

  Future<List<FeedItem>> _telegram(String link) async {
    final uri = Uri.parse(_normalize('telegram', link));
    final segs = uri.pathSegments.where((s) => s.isNotEmpty && s != 's').toList();
    _log('telegram: path segments=$segs');
    if (segs.isEmpty || segs.first.startsWith('+') || segs.first == 'joinchat') {
      throw Exception('Telegram feed needs a public channel link (t.me/yourchannel)');
    }
    final name = segs.first;
    final url = 'https://t.me/s/$name';
    _log('telegram: GET $url');
    final res = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 30));
    _log('telegram: status=${res.statusCode} bytes=${res.bodyBytes.length} finalUrl=${res.request?.url}');
    if (res.statusCode != 200) throw Exception('Telegram error ${res.statusCode}');

    final blocks = res.body.split('tgme_widget_message_wrap').skip(1).toList();
    _log('telegram: message blocks found=${blocks.length}');
    if (blocks.isEmpty) {
      _log('telegram: no messages. Channel may be private or have web preview disabled. '
          'body start: ${_short(res.body.replaceAll('\n', ' '))}');
    }

    final items = <FeedItem>[];
    var skipped = 0;
    for (final b in blocks) {
      final post = RegExp(r'data-post="([^"]+)"').firstMatch(b)?.group(1);
      if (post == null) {
        skipped++;
        continue;
      }
      final textHtml = RegExp(
          r'class="tgme_widget_message_text[^"]*"[^>]*>(.*?)</div>',
          dotAll: true)
          .firstMatch(b)
          ?.group(1) ??
          '';
      final text = _unescape(textHtml
          .replaceAll(RegExp(r'<br\s*/?>'), '\n')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .trim());
      final photo = RegExp(
          r"tgme_widget_message_photo_wrap[^>]*background-image:url\('([^']+)'\)")
          .firstMatch(b)
          ?.group(1) ??
          '';
      final video = b.contains('tgme_widget_message_video');
      if (text.isEmpty && photo.isEmpty) {
        skipped++;
        continue;
      }
      items.add(FeedItem(
        id: post,
        title: text,
        url: 'https://t.me/$post',
        imageUrl: photo,
        source: '@$name',
        date: DateTime.tryParse(
            RegExp(r'datetime="([^"]+)"').firstMatch(b)?.group(1) ?? ''),
        isVideo: video,
      ));
    }
    _log('telegram: parsed=${items.length} skipped(no text/photo)=$skipped');
    return items.reversed.toList();
  }

  String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#036;', r'$');
}