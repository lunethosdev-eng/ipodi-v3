import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:sekaipod/core/constants/constants.dart';
import 'package:sekaipod/core/models/music_metadata.dart';

final selectedMusicServiceProvider =
    NotifierProvider<SelectedMusicServiceNotifier, UnmodifiableListView<MusicMetadata>>(
  SelectedMusicServiceNotifier.new,
);

class SelectedMusicServiceNotifier
    extends Notifier<UnmodifiableListView<MusicMetadata>> {
  Box<MusicMetadata> get _box => Hive.box<MusicMetadata>(Constants.selectedMusicBoxName);

  @override
  UnmodifiableListView<MusicMetadata> build() {
    return UnmodifiableListView(_sorted(_box.values));
  }

  List<MusicMetadata> _sorted(Iterable<MusicMetadata> songs) {
    final list = songs.toList();
    list.sort((a, b) => a.getTrackName.toLowerCase().compareTo(b.getTrackName.toLowerCase()));
    return list;
  }

  bool contains(MusicMetadata song) => _box.values.any((other) => _sameSong(song, other));

  bool _sameSong(MusicMetadata a, MusicMetadata b) {
    if (a.filePath != null && b.filePath != null) return a.filePath == b.filePath;
    return a.trackName == b.trackName && a.getTrackArtistNames == b.getTrackArtistNames;
  }

  Future<void> add(MusicMetadata song) async {
    if (contains(song)) return;
    await _box.add(song);
    state = UnmodifiableListView(_sorted(_box.values));
  }

  Future<void> replace(MusicMetadata oldSong, MusicMetadata updatedSong) async {
    for (final entry in _box.toMap().entries) {
      if (_sameSong(oldSong, entry.value)) {
        await _box.put(entry.key, updatedSong);
        state = UnmodifiableListView(_sorted(_box.values));
        return;
      }
    }
  }

  Future<void> remove(MusicMetadata song) async {
    dynamic key;
    for (final entry in _box.toMap().entries) {
      if (_sameSong(song, entry.value)) {
        key = entry.key;
        break;
      }
    }
    if (key != null) await _box.delete(key);
    state = UnmodifiableListView(_sorted(_box.values));
  }

  Future<void> clear() async {
    await _box.clear();
    state = UnmodifiableListView(const <MusicMetadata>[]);
  }
}
