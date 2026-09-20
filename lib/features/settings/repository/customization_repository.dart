
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sekaipod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final customizationRepositoryProvider = Provider<CustomizationRepository>((ref) {
  return CustomizationRepository(ref.read(sharedPreferencesWithCacheProvider).requireValue);
});

class CustomizationRepository {
  final SharedPreferencesWithCache prefs;
  const CustomizationRepository(this.prefs);

  static const _accent = 'customization.accent';
  static const _background = 'customization.background';
  static const _stickers = 'customization.stickers';
  static const _sound = 'customization.sound';

  int get accentColorValue => prefs.getInt(_accent) ?? 0xFF007AFF;
  String? get backgroundImagePath => prefs.getString(_background);
  List<String> get stickerPaths => prefs.getStringList(_stickers) ?? const [];
  String get clickSound => prefs.getString(_sound) ?? 'soft_click';

  Future<void> setAccent(int value) => prefs.setInt(_accent, value);
  Future<void> setBackground(String? path) async {
    if (path == null) {
      await prefs.remove(_background);
    } else {
      await prefs.setString(_background, path);
    }
  }
  Future<void> setStickers(List<String> paths) => prefs.setStringList(_stickers, paths);
  Future<void> setClickSound(String name) => prefs.setString(_sound, name);
}
