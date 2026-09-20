import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sekaipod/core/constants/constants.dart';
import 'package:sekaipod/core/models/music_metadata.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class OfflineMusicService {
  const OfflineMusicService();

  Future<MusicMetadata> download(MusicMetadata song) async {
    final source = song.filePath;
    if (source == null || source.isEmpty) {
      throw const FormatException('This song has no audio URL.');
    }

    final uri = Uri.tryParse(source);
    if (uri == null || !uri.hasScheme) {
      throw const FormatException('Invalid audio URL.');
    }

    final host = uri.host.toLowerCase();
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      throw StateError(
        'Offline download needs a direct audio/stream URL. The catalog currently exposes a YouTube page URL for this item.',
      );
    }

    final response = await http.get(uri).timeout(const Duration(seconds: 60));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Audio server returned HTTP ${response.statusCode}.');
    }

    final directory = await getApplicationSupportDirectory();
    final offlineDirectory = Directory('${directory.path}/offline_music');
    await offlineDirectory.create(recursive: true);
    final rawName = '${song.getTrackName}_${song.getMainArtistName}';
    final normalizedName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    final safeName = normalizedName.substring(0, normalizedName.length.clamp(1, 80));
    final extension = _extension(uri.path) ?? 'audio';
    final file = File('${offlineDirectory.path}/$safeName.$extension');
    await file.writeAsBytes(response.bodyBytes, flush: true);

    final updated = song.copyWith(filePath: file.path, isOnDevice: true);
    final box = Hive.box<MusicMetadata>(Constants.selectedMusicBoxName);
    for (final entry in box.toMap().entries) {
      if (entry.value.filePath == song.filePath) {
        await box.put(entry.key, updated);
        break;
      }
    }
    return updated;
  }

  String? _extension(String path) {
    final name = path.split('/').last.split('?').first;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return null;
    final ext = name.substring(dot + 1).toLowerCase();
    if (ext.length > 5) return null;
    return ext;
  }
}
