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
  bool _openingHomeSettings = false;
  bool _openingSongs = false;

  Future<void> _openHomeSettings() async {
    if (_openingHomeSettings) return;
    setState(() => _openingHomeSettings = true);
    try {
      final opened = await const MethodChannel('com.sekai.sekaipod/system')
          .invokeMethod<bool>('openHomeSettings');
      if (!mounted) return;
      if (opened != true) {
        _showActionMessage(
          'No se pudo abrir el selector de app de inicio.\n\n'
          'Puedes hacerlo manualmente:\n'
          'Ajustes → Apps → Apps predeterminadas → App de inicio → SekaiPod',
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        _showActionMessage(
          'No se pudo abrir el selector de inicio: ${e.message ?? 'error desconocido'}\n\n'
          'Hazlo manualmente en Ajustes → Apps predeterminadas → App de inicio.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showActionMessage(
          'No se pudo abrir el selector de inicio: $e\n\n'
          'Hazlo manualmente en Ajustes → Apps predeterminadas → App de inicio.',
        );
      }
    } finally {
      if (mounted) setState(() => _openingHomeSettings = false);
    }
  }

  void _showActionMessage(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('SekaiPod'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openChooseSongs() async {
    if (_openingSongs) return;
    setState(() => _openingSongs = true);
    try {
      // go() always works even inside DeviceFrame shell
      ref.read(routerProvider).go('/addMusic?onboarding=1');
    } catch (e1) {
      try {
        if (!mounted) return;
        context.go('/addMusic?onboarding=1');
      } catch (e2) {
        try {
          if (!mounted) return;
          await context.push('/addMusic?onboarding=1');
        } catch (e3) {
          if (mounted) {
            _showActionMessage(
              'No se pudo abrir la pantalla de canciones.\n\n'
              'Detalle: $e3\n\n'
              'Prueba reiniciar o ve a Música → Añadir después del onboarding.',
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => _openingSongs = false);
    }
  }

  Future<void> _finish() async {
    await ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue
        .setBool('sekaipod.onboardingComplete', true);
    if (mounted) context.goNamed(Routes.menu.name);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _IntroPage(
        icon: CupertinoIcons.music_note_2,
        title: 'Bienvenido a SekaiPod',
        text:
            'Un launcher estilo iPod personal. Tú eliges qué canciones van en tu biblioteca.',
      ),
      _IntroPage(
        icon: CupertinoIcons.house,
        title: 'Ponlo como pantalla de inicio',
        text:
            'Puedes configurar SekaiPod como tu app de inicio de Android. También puedes saltarte este paso y hacerlo más tarde en Ajustes.',
        action: CupertinoButton.filled(
          onPressed: _openingHomeSettings ? null : _openHomeSettings,
          child: _openingHomeSettings
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Text('Establecer launcher predeterminado'),
        ),
      ),
      _IntroPage(
        icon: CupertinoIcons.music_albums,
        title: 'Elige tu música',
        text:
            'El catálogo de Sekai Music solo sirve para descubrir. Solo las canciones que agregues se guardan en Mi Música.\n\nPuedes saltar y elegir después desde el menú Música.',
        action: CupertinoButton.filled(
          onPressed: _openingSongs ? null : _openChooseSongs,
          child: _openingSongs
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Text('Elegir canciones'),
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
              children: List.generate(
                pages.length,
                (i) => Padding(
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == page
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey4,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: _finish,
                  child: const Text('Saltar'),
                ),
                if (page < pages.length - 1)
                  CupertinoButton.filled(
                    onPressed: () => setState(() => page++),
                    child: const Text('Siguiente'),
                  )
                else
                  CupertinoButton.filled(
                    onPressed: _finish,
                    child: const Text('Terminar'),
                  ),
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

  const _IntroPage({
    required this.icon,
    required this.title,
    required this.text,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 76, color: CupertinoColors.activeBlue),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 22),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
