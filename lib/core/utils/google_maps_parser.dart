import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A latitude / longitude pair read from a Google Maps link or text.
class MapsCoords {
  final double lat;
  final double lng;
  const MapsCoords(this.lat, this.lng);

  @override
  String toString() => '$lat, $lng';
}

/// Turns whatever the admin pastes into exact coordinates.
///
/// Understands:
///  • full Google Maps links  (…/place/…!3d9.01!4d38.76, …/@9.01,38.76,17z, ?q=9.01,38.76)
///  • short share links       (https://maps.app.goo.gl/…, https://goo.gl/maps/…)  — followed
///  • plain coordinates       ("9.0305, 38.7449")
///  • degrees-minutes-seconds ("9°01'49.8"N 38°44'41.7"E")
///
/// No packages needed: short links are followed with dart:io.
class GoogleMapsParser {
  GoogleMapsParser._();

  /// Priority order: the exact pin (!3d…!4d…) beats the map's viewport
  /// centre (@lat,lng), which beats generic query parameters.
  static final List<RegExp> _patterns = [
    RegExp(r'!3d(-?\d{1,3}\.\d+)!4d(-?\d{1,3}\.\d+)'),
    RegExp(r'@(-?\d{1,3}\.\d+),(-?\d{1,3}\.\d+)'),
    RegExp(
        r'[?&](?:q|ll|query|center|destination|daddr|sll)=(-?\d{1,3}\.\d+)(?:,|%2C)\s*(-?\d{1,3}\.\d+)'),
    RegExp(
        r'^\s*\(?\s*(-?\d{1,3}(?:\.\d+)?)\s*[,;\s]\s*(-?\d{1,3}(?:\.\d+)?)\s*\)?\s*$'),
  ];

  static final RegExp _dms = RegExp(
    r'''(\d{1,3})\s*°\s*(\d{1,2})\s*['′]\s*(\d{1,2}(?:\.\d+)?)\s*["″”]?\s*([NSEWnsew])''',
  );

  static bool _valid(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  /// Reads coordinates straight out of text/URL (no network).
  static MapsCoords? parseText(String input) {
    var text = input;
    try {
      text = Uri.decodeFull(input);
    } catch (_) {}

    for (final p in _patterns) {
      final m = p.firstMatch(text);
      if (m == null) continue;
      final lat = double.tryParse(m.group(1)!);
      final lng = double.tryParse(m.group(2)!);
      if (lat != null && lng != null && _valid(lat, lng)) {
        return MapsCoords(lat, lng);
      }
    }
    return _parseDms(text);
  }

  static MapsCoords? _parseDms(String text) {
    final matches = _dms.allMatches(text).toList();
    if (matches.length < 2) return null;

    double conv(RegExpMatch x) {
      final v = double.parse(x.group(1)!) +
          double.parse(x.group(2)!) / 60 +
          double.parse(x.group(3)!) / 3600;
      final h = x.group(4)!.toUpperCase();
      return (h == 'S' || h == 'W') ? -v : v;
    }

    double? lat, lng;
    for (final x in matches.take(2)) {
      final h = x.group(4)!.toUpperCase();
      if (h == 'N' || h == 'S') {
        lat = conv(x);
      } else {
        lng = conv(x);
      }
    }
    if (lat == null || lng == null || !_valid(lat, lng)) return null;
    return MapsCoords(lat, lng);
  }

  /// Full pipeline: text → coordinates, following short links if needed.
  /// Returns null when nothing usable is found.
  static Future<MapsCoords?> resolve(String input) async {
    final text = input.trim();
    if (text.isEmpty) return null;

    final direct = parseText(text);
    if (direct != null) return direct;

    final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(text);
    if (urlMatch == null) return null;
    var url = urlMatch.group(0)!;

    for (int hop = 0; hop < 6; hop++) {
      final here = parseText(url);
      if (here != null) return here;

      // Consent / interstitial pages wrap the real link in ?continue=
      final cont = Uri.tryParse(url)?.queryParameters['continue'];
      if (cont != null && cont.startsWith('http')) {
        url = cont;
        continue;
      }

      final step = await _follow(url);
      if (step == null) return null;
      if (step.coords != null) return step.coords;
      if (step.next == null) return null;
      url = step.next!;
    }
    return null;
  }

  static Future<_Hop?> _follow(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.followRedirects = false;
      req.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
      );
      final res = await req.close().timeout(const Duration(seconds: 10));

      final loc = res.headers.value(HttpHeaders.locationHeader);
      if (loc != null && loc.isNotEmpty) {
        await res.drain<void>();
        return _Hop(next: Uri.parse(url).resolve(loc).toString());
      }

      // No redirect: scan the start of the page for coordinates.
      final sb = StringBuffer();
      await for (final chunk in res.transform(const Utf8Decoder(allowMalformed: true))) {
        sb.write(chunk);
        if (sb.length > 400000) break;
      }
      final found = parseText(sb.toString().replaceAll('&amp;', '&'));
      return _Hop(coords: found);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

class _Hop {
  final String? next;
  final MapsCoords? coords;
  const _Hop({this.next, this.coords});
}