import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sekaipod/core/models/music_metadata.dart';

/// Remote catalog client for Sekai Music.
///
/// The launcher intentionally loads the complete catalog with one request and
/// keeps the parsed result in memory for the current app session.
class SekaiMusicApi {
  SekaiMusicApi({http.Client? client}) : _client = client ?? http.Client();

  static const String catalogUrl =
      'https://sekai-music-server.onrender.com/api/v1/catalog';

  final http.Client _client;
  List<MusicMetadata>? _catalogCache;

  Future<List<MusicMetadata>> getCatalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _catalogCache != null) {
      return List.unmodifiable(_catalogCache!);
    }

    final response = await _client.get(
      Uri.parse(catalogUrl),
      headers: const {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Sekai Music returned HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Sekai Music catalog response.');
    }

    final rawCatalog = decoded['catalog'];
    if (rawCatalog is! List) {
      throw const FormatException('The catalog field is not an array.');
    }

    final result = <MusicMetadata>[];
    for (var index = 0; index < rawCatalog.length; index++) {
      final item = rawCatalog[index];
      if (item is! Map) continue;
      final metadata = _toMusicMetadata(
        Map<String, dynamic>.from(item),
        index,
      );
      if (metadata != null) result.add(metadata);
    }

    _catalogCache = result;
    return List.unmodifiable(result);
  }

  void clearCache() => _catalogCache = null;

  void dispose() => _client.close();

  MusicMetadata? _toMusicMetadata(Map<String, dynamic> item, int index) {
    final metadata = _asMap(item['metadata']) ?? item;

    final title = _string(metadata, const [
          'trackName',
          'title',
          'name',
          'song',
          'songName',
        ]) ??
        _string(item, const ['trackName', 'title', 'name', 'song']);

    final artistValue = _value(metadata, const [
          'trackArtistNames',
          'artist',
          'artists',
          'artistName',
          'author',
        ]) ??
        _value(item, const ['artist', 'artists', 'artistName', 'author']);

    final album = _string(metadata, const [
          'albumName',
          'album',
          'albumTitle',
        ]) ??
        _string(item, const ['album', 'albumName']);

    final audioUrl = _findUrl(item, const [
      'audioUrl',
      'audio',
      'streamUrl',
      'stream',
      'playUrl',
      'url',
      'soundcloudUrl',
      'soundcloud',
      'youtubeAudioUrl',
    ]);

    if (title == null || audioUrl == null || !audioUrl.startsWith('http')) {
      return null;
    }

    final artistNames = _artists(artistValue);
    final artUrl = _findUrl(item, const [
      'artHD',
      'artHd',
      'artworkHD',
      'artworkUrl',
      'artwork',
      'coverUrl',
      'cover',
      'thumbnailUrl',
      'thumbnail',
      'image',
    ]);

    final lyrics = _string(item, const ['lyrics', 'lyric', 'text']) ??
        _string(metadata, const ['lyrics', 'lyric', 'text']);

    return MusicMetadata(
      trackName: title,
      trackArtistNames: artistNames.isEmpty ? const ['Unknown Artist'] : artistNames,
      albumName: album ?? 'Unknown Album',
      albumArtistName: artistNames.isEmpty ? 'Unknown Artist' : artistNames.first,
      trackNumber: _int(metadata, const ['trackNumber', 'track', 'trackIndex']),
      albumLength: _int(metadata, const ['albumLength', 'trackTotal']),
      year: _int(metadata, const ['year']),
      genres: _strings(_value(metadata, const ['genres', 'genre'])),
      discNumber: _int(metadata, const ['discNumber', 'disc']),
      mimeType: _string(metadata, const ['mimeType', 'mime', 'contentType']),
      trackDuration: _durationMs(metadata, item),
      bitrate: _int(metadata, const ['bitrate']),
      filePath: audioUrl,
      thumbnailPath: artUrl,
      originalSongIndex: index,
      isOnDevice: false,
      lyrics: lyrics,
    );
  }

  dynamic _value(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) return map[key];
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _string(Map<String, dynamic> map, List<String> keys) {
    final value = _value(map, keys);
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return null;
  }

  int? _int(Map<String, dynamic> map, List<String> keys) {
    final value = _value(map, keys);
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.round();
    return null;
  }

  int? _durationMs(Map<String, dynamic> metadata, Map<String, dynamic> item) {
    final value = _value(metadata, const ['trackDuration', 'duration', 'durationMs', 'length']) ??
        _value(item, const ['duration', 'durationMs']);
    if (value is int) return value < 10000 ? value * 1000 : value;
    if (value is num) {
      final number = value.toDouble();
      return (number < 10000 ? number * 1000 : number).round();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return (parsed < 10000 ? parsed * 1000 : parsed).round();
      final parts = value.split(':').map(int.tryParse).toList();
      if (parts.length == 2 && parts.every((e) => e != null)) {
        return ((parts[0]! * 60) + parts[1]!) * 1000;
      }
    }
    return null;
  }

  List<String> _artists(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e is Map ? (e['name'] ?? e['artist'] ?? '').toString() : e.toString())
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'\s*(?:,|;|•|&| feat\. | ft\. )\s*', caseSensitive: false))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<String> _strings(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    if (value is String && value.trim().isNotEmpty) {
      return value.split(RegExp(r'\s*[,;|]\s*')).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  String? _findUrl(Map<String, dynamic> map, List<String> preferredKeys) {
    for (final key in preferredKeys) {
      final found = _findValue(map[key]);
      if (found != null) return found;
    }

    // Be forgiving about future API naming while still requiring a URL.
    for (final entry in map.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains('audio') || key.contains('stream') || key.contains('soundcloud')) {
        final found = _findValue(entry.value);
        if (found != null) return found;
      }
    }
    return null;
  }

  String? _findValue(dynamic value) {
    if (value is String && value.startsWith('http')) return value;
    if (value is Map) {
      for (final key in const ['url', 'audioUrl', 'streamUrl', 'src', 'href']) {
        final nested = value[key];
        if (nested is String && nested.startsWith('http')) return nested;
      }
    }
    if (value is List) {
      for (final item in value) {
        final found = _findValue(item);
        if (found != null) return found;
      }
    }
    return null;
  }
}
