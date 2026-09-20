import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sekaipod/core/models/music_metadata.dart';
import 'package:sekaipod/core/services/audio_files_service.dart';
import 'package:sekaipod/core/services/audio_player_service.dart';
import 'package:sekaipod/core/services/offline_music_service.dart';
import 'package:sekaipod/core/services/sekai_music_api.dart';
import 'package:sekaipod/features/music/album/providers/album_details_provider.dart';
import 'package:sekaipod/features/music/artists/providers/artist_names_provider.dart';
import 'package:sekaipod/features/music/genres/providers/genres_provider.dart';
import 'package:sekaipod/features/music/songs/provider/songs_provider.dart';
import 'package:sekaipod/features/music/playlist/providers/playlists_provider.dart';
import 'package:sekaipod/core/services/selected_music_service.dart';
import 'package:sekaipod/features/status_bar/widgets/status_bar.dart';
import 'package:sekaipod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:sekaipod/core/navigation/routes.dart';

final addMusicCatalogProvider = FutureProvider<List<MusicMetadata>>((ref) async {
  return ref.read(sekaiMusicApiProvider).getCatalog();
});

class AddMusicScreen extends ConsumerStatefulWidget {
  final bool fromOnboarding;
  const AddMusicScreen({super.key, this.fromOnboarding = false});

  @override
  ConsumerState<AddMusicScreen> createState() => _AddMusicScreenState();
}

class _AddMusicScreenState extends ConsumerState<AddMusicScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MusicMetadata> _filter(List<MusicMetadata> catalog) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return catalog;
    return catalog.where((song) {
      final haystack = [
        song.getTrackName,
        song.getTrackArtistNames,
        song.getAlbumName,
        ...song.genres,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  Future<void> _syncPlayer() async {
    final songs = ref.read(selectedMusicServiceProvider).toList();
    await ref.read(audioPlayerServiceProvider.notifier).setAudioSource(musicMetadataList: songs);
    ref.invalidate(songsProvider);
    ref.invalidate(albumDetailsProvider);
    ref.invalidate(artistNamesProvider);
    ref.invalidate(genresProvider);
    ref.invalidate(playlistsProvider);
  }

  Future<void> _download(MusicMetadata song) async {
    try {
      final updated = await const OfflineMusicService().download(song);
      await ref.read(selectedMusicServiceProvider.notifier).replace(song, updated);
      await _syncPlayer();
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Available offline'),
            content: const Text('This song is now stored on this device.'),
            actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Offline download unavailable'),
          content: Text('$e'),
          actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
        ),
      );
    }
  }

  Future<void> _toggle(MusicMetadata song, bool selected) async {
    final service = ref.read(selectedMusicServiceProvider.notifier);
    if (selected) {
      await service.remove(song);
    } else {
      await service.add(song);
    }

    // The library selection is the primary action. Rebuilding the audio
    // queue is secondary and must not make the button appear unresponsive.
    try {
      await _syncPlayer();
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Song saved'),
          content: Text(
            selected
                ? 'The song was removed from My Music. The player could not refresh: $e'
                : 'The song was added to My Music. The player could not refresh: $e',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(addMusicCatalogProvider);
    final selected = ref.watch(selectedMusicServiceProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.fromOnboarding ? 'Choose your music' : 'Add More Music'),
        trailing: widget.fromOnboarding
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  await _syncPlayer();
                  await ref.read(sharedPreferencesWithCacheProvider).requireValue.setBool('sekaipod.onboardingComplete', true);
                  if (context.mounted) context.goNamed(Routes.menu.name);
                },
                child: const Text('Done'),
              )
            : null,
      ),
      child: SafeArea(
        child: catalogState.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load Sekai Music.'),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () => ref.invalidate(addMusicCatalogProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (catalog) {
            final filtered = _filter(catalog);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Search songs, artists, albums…',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      Text('${filtered.length} results'),
                      const Spacer(),
                      Text('${selected.length} in My Music'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final song = filtered[index];
                      final isSelected = selected.any((e) => e.filePath == song.filePath);
                      return _CatalogSongTile(
                        song: song,
                        selected: isSelected,
                        onTap: () => _toggle(song, isSelected),
                        onDownload: isSelected ? () => _download(song) : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CatalogSongTile extends StatelessWidget {
  final MusicMetadata song;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  const _CatalogSongTile({required this.song, required this.selected, required this.onTap, this.onDownload});

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      leading: song.thumbnailPath == null
          ? const Icon(CupertinoIcons.music_note)
          : ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.network(
                song.thumbnailPath!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.music_note),
              ),
            ),
      title: Text(song.getTrackName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.getTrackArtistNames ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDownload != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onDownload,
              child: const Icon(CupertinoIcons.arrow_down_circle),
            ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onTap,
            child: Icon(selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.add_circled),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
