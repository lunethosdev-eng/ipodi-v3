import 'package:sekaipod/core/constants/constants.dart';
import 'package:sekaipod/core/extensions/build_context_extensions.dart';
import 'package:sekaipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeviceScreen extends ConsumerWidget {
  final Widget child;

  const DeviceScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTouchScreenEnabled = ref.watch(
      settingsPreferencesControllerProvider.select(
        (e) => e.isTouchScreenEnabled,
      ),
    );

    final size = MediaQuery.sizeOf(context);

    // Always allow touch on onboarding / add-music so setup buttons work
    // even if the user previously disabled the touchscreen setting.
    final location = GoRouterState.of(context).uri.path;
    final forceTouch =
        location.contains('onboarding') || location.contains('addMusic');
    final absorb = !forceTouch && !isTouchScreenEnabled;

    return AbsorbPointer(
      absorbing: absorb,
      child: Container(
        height: Constants.screenHeight + 10,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.appDeviceScreenBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.appDeviceScreenBorderColor,
            width: 5,
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(size: Size(size.width - 40 - 10, Constants.screenHeight)),
          child: child,
        ),
      ),
    );
  }
}
