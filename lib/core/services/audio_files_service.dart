import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:sekaipod/core/constants/constants.dart';
import 'package:sekaipod/core/models/music_metadata.dart';
import 'package:sekaipod/core/providers/device_directory_provider.dart';
import 'package:sekaipod/core/services/sekai_music_api.dart';
import 'package:sekaipod/core/services/selected_music_service.dart';
import 'package:sekaipod/core/repositories/metadata_reader_repository.dart';
import 'package:sekaipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';

final sekaiMusicApiProvider = Provider<SekaiMusicApi>((ref) {
  final api = SekaiMusicApi();
  ref.onDispose(api.dispose);
  return api;
});

final audioFilesServiceProvider =
    AsyncNotifierProvider<
      AudioFilesServiceNotifier,
      UnmodifiableListView<MusicMetadata>
    >(AudioFilesServiceNotifier.new);

class AudioFilesServiceNotifier
    extends AsyncNotifier<UnmodifiableListView<MusicMetadata>> {
  @override
  Future<UnmodifiableListView<MusicMetadata>> build() async {
    return getAudioFilesMetadata();
  }

  Future<UnmodifiableListView<MusicMetadata>> getAudioFilesMetadata() async {
    state = const AsyncLoading();
    try {
      if (ref.read(settingsPreferencesControllerProvider).fetchOnlineMusic) {
        // The remote catalog is only a discovery source. The user's library
        // contains only songs they explicitly selected.
        final selected = ref.read(selectedMusicServiceProvider);
        return UnmodifiableListView(selected);
      }
      // Fetch metadata from local files
      else {
        final Box<MusicMetadata> metadataBox = Hive.box<MusicMetadata>(
          Constants.metadataBoxName,
        );
        // Check if the metadata box is empty
        if (metadataBox.isEmpty) {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            final newDirectory = await FilePicker.getDirectoryPath(
              dialogTitle: "Select Music Directory",
              lockParentWindow: true,
              initialDirectory: ref
                  .read(deviceDirectoryProvider)
                  .requireValue
                  .musicFolderPath,
            );
            if (newDirectory != null) {
              final result = await compute(
                ref
                    .read(metadataReaderRepositoryProvider)
                    .extractMetadataFromDirectory,
                newDirectory,
              );
              await metadataBox.addAll(result);
              return UnmodifiableListView(result);
            } else {
              return UnmodifiableListView([]);
            }
          } else if (Platform.isIOS) {
            final pickedFiles = await FilePicker.pickFiles(
              allowMultiple: true,
              dialogTitle: "Pick Song Files",
            );

            if (pickedFiles == null || pickedFiles.files.isEmpty) {
              return UnmodifiableListView([]);
            }

            final result = await compute(
              ref
                  .read(metadataReaderRepositoryProvider)
                  .extractMetadataFromFiles,
              pickedFiles.files.map((f) => f.path!).toList(),
            );

            await metadataBox.addAll(result);
            return UnmodifiableListView(result);
          }
          // On Android Automatically Fetch Music Files
          else {
            final OnAudioQuery audioQuery = OnAudioQuery();
            final queriedSongs = await audioQuery.querySongs();

            final result = await compute(
              ref
                  .read(metadataReaderRepositoryProvider)
                  .extractMetadataFromFiles,
              queriedSongs.map((e) => e.data).toList(growable: false),
            );
            await metadataBox.addAll(result);
            return UnmodifiableListView(result);
          }
        }
        // Return cached metadata
        else {
          return UnmodifiableListView(metadataBox.values);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[SekaiPod] Audio library error: $e\n$stackTrace');
      rethrow;
    }
  }
}
