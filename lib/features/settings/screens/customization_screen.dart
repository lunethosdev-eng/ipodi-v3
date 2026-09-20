import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sekaipod/features/settings/controller/customization_controller.dart';

class CustomizationScreen extends ConsumerWidget {
  const CustomizationScreen({super.key});

  Future<String?> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'webp', 'jpg', 'jpeg'],
    );
    return result?.files.single.path;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customization = ref.watch(customizationControllerProvider);
    final controller = ref.read(customizationControllerProvider.notifier);
    const colors = <Color>[
      Color(0xFF007AFF), Color(0xFF5E5CE6), Color(0xFFFF2D55),
      Color(0xFFFF9500), Color(0xFFFFCC00), Color(0xFF34C759),
      Color(0xFF64D2FF), Color(0xFFAF52DE), Color(0xFF111111),
    ];

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Customize SekaiPod')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const Text('Accent color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colors.map((color) {
                final selected = customization.accentColorValue == color.value;
                return GestureDetector(
                  onTap: () => controller.setAccent(color.value),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? CupertinoColors.black : CupertinoColors.transparent,
                        width: 3,
                      ),
                    ),
                    child: selected ? const Icon(CupertinoIcons.checkmark, size: 20, color: CupertinoColors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            CupertinoListSection.insetGrouped(
              header: const Text('Decorations'),
              children: [
                CupertinoListTile(
                  title: const Text('Background image'),
                  subtitle: Text(customization.backgroundImagePath == null ? 'None' : 'Custom image selected'),
                  trailing: const Icon(CupertinoIcons.photo),
                  onTap: () async {
                    final path = await _pickImage();
                    if (path != null) await controller.setBackground(path);
                  },
                ),
                if (customization.backgroundImagePath != null)
                  CupertinoListTile(
                    title: const Text('Remove background'),
                    trailing: const Icon(CupertinoIcons.delete),
                    onTap: () => controller.setBackground(null),
                  ),
                CupertinoListTile(
                  title: const Text('Add transparent sticker / PNG'),
                  subtitle: Text('${customization.stickerPaths.length}/8 stickers'),
                  trailing: const Icon(CupertinoIcons.add_circled),
                  onTap: customization.stickerPaths.length >= 8 ? null : () async {
                    final path = await _pickImage();
                    if (path != null) await controller.addSticker(path);
                  },
                ),
                for (final sticker in customization.stickerPaths)
                  CupertinoListTile(
                    title: Text(File(sticker).uri.pathSegments.last),
                    trailing: const Icon(CupertinoIcons.minus_circled),
                    onTap: () => controller.removeSticker(sticker),
                  ),
              ],
            ),
            CupertinoListSection.insetGrouped(
              header: const Text('Click sound'),
              children: [
                for (final sound in const ['soft_click', 'classic_click', 'bubble_click'])
                  CupertinoListTile(
                    title: Text(sound.replaceAll('_', ' ')),
                    trailing: customization.clickSound == sound
                        ? const Icon(CupertinoIcons.checkmark)
                        : null,
                    onTap: () => controller.setClickSound(sound),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'PNG/WebP images with transparent backgrounds work especially well for stickers. Up to 8 stickers can be layered over the iPod frame.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
