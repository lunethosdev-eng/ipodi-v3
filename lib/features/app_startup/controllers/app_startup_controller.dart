import 'dart:async';
import 'dart:io';

import 'package:sekaipod/core/constants/constants.dart';
import 'package:sekaipod/core/models/music_metadata.dart';
import 'package:sekaipod/core/providers/device_directory_provider.dart';
import 'package:sekaipod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:sekaipod/features/music/playlist/models/playlist_model.dart';
import 'package:sekaipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:sekaipod/features/settings/models/exclude_directory_model.dart';
import 'package:sekaipod/hive/hive_registrar.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

final appStartupControllerProvider = FutureProvider<void>((ref) async {
  await Future.wait([
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[
      // Do not lock orientation: foldables (Z Fold/Flip), tablets and landscape phones
      // should be able to resize the iPod shell naturally.
      JustAudioBackground.init(
        androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
        androidNotificationChannelName: 'SekaiPod Audio playback',
        androidNotificationChannelDescription:
            'Notification to control the currently playing music files',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_stat_name',
      ),
    ],
    if (!kIsWeb) ref.watch(deviceDirectoryProvider.future),
    ref.watch(sharedPreferencesWithCacheProvider.future),
    Hive.initFlutter("SekaiPod"),
  ]);
  Hive.registerAdapters();
  await Hive.openBox<MusicMetadata>(Constants.metadataBoxName);
  await Hive.openBox<MusicMetadata>(Constants.selectedMusicBoxName);
  await Hive.openBox<PlaylistModel>(Constants.playlistBoxName);
  await Hive.openBox<ExcludeDirectoryModel>(
    Constants.excludedDirectoriesBoxName,
  );
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    JustAudioMediaKit.ensureInitialized();
    JustAudioMediaKit.title = 'SekaiPod';
  }
  ref
      .read(settingsPreferencesControllerProvider.notifier)
      .setAudioSource(isOnlineAudioSource: kIsWeb);
  unawaited(
    ref.read(settingsPreferencesControllerProvider.notifier).setSystemUiMode(),
  );
});
