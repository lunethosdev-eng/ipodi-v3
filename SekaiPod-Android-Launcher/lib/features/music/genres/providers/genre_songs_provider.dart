import 'package:sekaipod/core/models/music_metadata.dart';
import 'package:sekaipod/core/providers/filtered_audio_files_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final genreSongsMetadataListProvider = Provider.autoDispose
    .family<List<MusicMetadata>, String>((ref, genreName) {
      final List<MusicMetadata> genreSongsMetadataList = [];

      ref.read(filteredAudioFilesProvider).requireValue.forEach((metadata) {
        if (metadata.genres.contains(genreName)) {
          genreSongsMetadataList.add(metadata);
        }
      });

      return genreSongsMetadataList;
    });
