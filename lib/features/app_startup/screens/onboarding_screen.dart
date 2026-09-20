import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sekaipod/core/navigation/routes.dart';
import 'package:sekaipod/core/providers/shared_preferences_with_cache_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int page = 0;

  Future<void> _openHomeSettings() async {
    try {
      await const MethodChannel('com.sekai.sekaipod/system').invokeMethod('openHomeSettings');
    } on PlatformException catch (error) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Choose your Home app'),
          content: Text('Android did not open the Home app selector. You can choose SekaiPod later in Settings.\n\n$error'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Could not open Home settings'),
          content: Text('$error'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _finish() async {
    await ref.read(sharedPreferencesWithCacheProvider).requireValue.setBool('sekaipod.onboardingComplete', true);
    if (mounted) context.goNamed(Routes.menu.name);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _IntroPage(
        icon: CupertinoIcons.music_note_2,
        title: 'Welcome to SekaiPod',
        text: 'A personal iPod-style launcher. You choose what belongs in your music library.',
      ),
      _IntroPage(
        icon: CupertinoIcons.house,
        title: 'Make it your Home',
        text: 'You can set SekaiPod as your Android Home app. You can also skip this and do it later.',
        action: CupertinoButton.filled(onPressed: _openHomeSettings, child: const Text('Set default launcher')),
      ),
      _IntroPage(
        icon: CupertinoIcons.music_albums,
        title: 'Choose your music',
        text: 'The Sekai Music catalog is only used for discovery. Only songs you add are saved to My Music.',
        action: CupertinoButton.filled(
          onPressed: () => context.pushNamed(Routes.addMusic.name, queryParameters: const {'onboarding': '1'}),
          child: const Text('Choose songs'),
        ),
      ),
    ];

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: pages[page]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) => Padding(
                padding: const EdgeInsets.all(5),
                child: Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: i == page ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4)),
              )),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(onPressed: _finish, child: const Text('Skip')),
                if (page < pages.length - 1)
                  CupertinoButton.filled(onPressed: () => setState(() => page++), child: const Text('Next'))
                else
                  CupertinoButton.filled(onPressed: _finish, child: const Text('Finish')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  const _IntroPage({required this.icon, required this.title, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 76, color: CupertinoColors.activeBlue),
            const SizedBox(height: 24),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel)),
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    );
  }
}
