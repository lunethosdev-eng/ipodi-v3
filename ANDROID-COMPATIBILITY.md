# SekaiPod Android compatibility

SekaiPod is shipped as two APK tracks because the current Flutter engine no longer supports very old Android releases.

- `SekaiPod-Android7-16.apk`: Flutter build, minSdk 24 (Android 7.0), target/compile API 36 (Android 16).
- `SekaiPod-Legacy-Android4.1-6.apk`: small native Android fallback, minSdk 16 (Android 4.1), target API 28. It uses the same Sekai Music catalog endpoint and Android MediaPlayer for direct audio URLs.

The legacy APK is intentionally lightweight. It can install/run on API 16-23, but old Android TLS/certificate stacks may prevent access to modern HTTPS servers on some devices. This is an OS networking limitation, not an app UI issue.

The GitHub Actions workflow builds both artifacts.
