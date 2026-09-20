import 'dart:ui';

class CustomizationModel {
  final int accentColorValue;
  final String? backgroundImagePath;
  final List<String> stickerPaths;
  final String clickSound;

  const CustomizationModel({
    required this.accentColorValue,
    required this.backgroundImagePath,
    required this.stickerPaths,
    required this.clickSound,
  });

  Color get accentColor => Color(accentColorValue);

  CustomizationModel copyWith({
    int? accentColorValue,
    String? backgroundImagePath,
    bool clearBackground = false,
    List<String>? stickerPaths,
    String? clickSound,
  }) {
    return CustomizationModel(
      accentColorValue: accentColorValue ?? this.accentColorValue,
      backgroundImagePath: clearBackground ? null : (backgroundImagePath ?? this.backgroundImagePath),
      stickerPaths: stickerPaths ?? this.stickerPaths,
      clickSound: clickSound ?? this.clickSound,
    );
  }
}
