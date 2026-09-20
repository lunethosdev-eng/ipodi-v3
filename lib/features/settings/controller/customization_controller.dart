import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sekaipod/features/settings/models/customization_model.dart';
import 'package:sekaipod/features/settings/repository/customization_repository.dart';

final customizationControllerProvider =
    NotifierProvider<CustomizationController, CustomizationModel>(CustomizationController.new);

class CustomizationController extends Notifier<CustomizationModel> {
  @override
  CustomizationModel build() {
    final repo = ref.read(customizationRepositoryProvider);
    return CustomizationModel(
      accentColorValue: repo.accentColorValue,
      backgroundImagePath: repo.backgroundImagePath,
      stickerPaths: repo.stickerPaths,
      clickSound: repo.clickSound,
    );
  }

  Future<void> setAccent(int value) async {
    state = state.copyWith(accentColorValue: value);
    await ref.read(customizationRepositoryProvider).setAccent(value);
  }

  Future<void> setBackground(String? path) async {
    state = state.copyWith(backgroundImagePath: path, clearBackground: path == null);
    await ref.read(customizationRepositoryProvider).setBackground(path);
  }

  Future<void> addSticker(String path) async {
    final paths = [...state.stickerPaths, path].take(8).toList();
    state = state.copyWith(stickerPaths: paths);
    await ref.read(customizationRepositoryProvider).setStickers(paths);
  }

  Future<void> removeSticker(String path) async {
    final paths = state.stickerPaths.where((e) => e != path).toList();
    state = state.copyWith(stickerPaths: paths);
    await ref.read(customizationRepositoryProvider).setStickers(paths);
  }

  Future<void> setClickSound(String name) async {
    state = state.copyWith(clickSound: name);
    await ref.read(customizationRepositoryProvider).setClickSound(name);
  }
}
