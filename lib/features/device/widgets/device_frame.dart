import 'package:sekaipod/core/constants/assets.dart';
import 'package:sekaipod/core/constants/keys.dart';
import 'package:sekaipod/features/device/widgets/device_controls.dart';
import 'package:sekaipod/features/device/widgets/device_screen.dart';
import 'package:sekaipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:sekaipod/features/settings/controller/customization_controller.dart';
import 'package:sekaipod/features/settings/models/device_color.dart';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceFrame extends ConsumerWidget {
  final Widget child;

  const DeviceFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final DeviceColor deviceColor = ref.watch(
      settingsPreferencesControllerProvider.select((e) => e.deviceColor),
    );
    final deviceColorStyle = deviceColor.style;
    final customization = ref.watch(customizationControllerProvider);
    final solidFrameColor = deviceColorStyle.solidFrameColor;
    final maxDeviceWidth = size.width >= 700 ? 560.0 : 450.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: solidFrameColor,
        image: solidFrameColor == null
            ? DecorationImage(
                image: const AssetImage(Assets.noiseImage),
                fit: BoxFit.cover,
                opacity: deviceColorStyle.noiseOpacity,
              )
            : null,
        gradient: solidFrameColor == null
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: deviceColorStyle.frameGradientColors,
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (customization.backgroundImagePath != null && File(customization.backgroundImagePath!).existsSync())
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.24,
                  child: Image.file(File(customization.backgroundImagePath!), fit: BoxFit.cover),
                ),
              ),
            ),
          for (var i = 0; i < customization.stickerPaths.length; i++)
            if (File(customization.stickerPaths[i]).existsSync())
              Positioned(
                top: 70 + (i % 4) * 88,
                right: 12 + (i % 2) * 8,
                width: 58,
                height: 58,
                child: IgnorePointer(
                  child: Image.file(File(customization.stickerPaths[i]), fit: BoxFit.contain),
                ),
              ),
          Positioned(
            top: 0,
            child: SizedBox(
              height: 20,
              width: size.width,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(blurRadius: 100, spreadRadius: 1)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: SizedBox(
              height: 20,
              width: size.width,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(blurRadius: 100, spreadRadius: 1)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            child: SizedBox(
              height: size.height,
              width: 20,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(blurRadius: 100, spreadRadius: 1)],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: SizedBox(
              height: size.height,
              width: 20,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(blurRadius: 100, spreadRadius: 1)],
                ),
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 960,
                  maxWidth: maxDeviceWidth,
                ),
                child: Column(
                  children: [
                    DeviceScreen(key: deviceScreenGlobalKey, child: child),
                    const Spacer(flex: 2),
                    DeviceControls(key: deviceControlsGlobalKey),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
