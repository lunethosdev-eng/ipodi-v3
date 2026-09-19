import 'package:sekaipod/core/models/music_metadata.dart';
import 'package:sekaipod/features/music/playlist/models/playlist_model.dart';
import 'package:sekaipod/features/settings/models/exclude_directory_model.dart';
import 'package:hive_ce/hive.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([
  AdapterSpec<MusicMetadata>(),
  AdapterSpec<PlaylistModel>(),
  AdapterSpec<ExcludeDirectoryModel>(),
])
class HiveAdapters {}
