# SekaiPod

SekaiPod is a Flutter/Android iPod-style launcher built from the ClassiPod codebase and adapted to use the Sekai Music server as its primary catalog.

## API

The app loads the complete catalog with one request:

`GET https://sekai-music-server.onrender.com/api/v1/catalog`

The response is expected to contain a `catalog` array. The adapter accepts common field names for title, artist, album, duration, lyrics, HD artwork, and remote audio URLs so the launcher can tolerate small catalog-schema changes.

## Important audio note

`just_audio` needs a directly playable HTTP(S) audio/stream URL. If an item contains a normal YouTube webpage URL rather than a resolved audio stream, the server should expose a playable audio URL (for example `audioUrl`/`streamUrl`). The launcher does not scrape YouTube pages inside the APK.

## GitHub Actions

The repository includes the existing Flutter GitHub workflow. Push this project to GitHub and run the production workflow to build the Android APK. A release keystore can be supplied through the repository's existing signing configuration; without signing secrets, use a debug build for testing.

## Branding

- App: **SekaiPod**
- Android application ID: `com.sekai.sekaipod`
- Package internals remain under the original Dart import namespace to minimize risk while migrating the ClassiPod codebase.

## GitHub launcher build

`.github/workflows/sekai-pod-android.yml` builds `SekaiPod-Android.apk` automatically on pushes to `main`/`master` and also supports manual runs. The workflow uploads the APK as a GitHub Actions artifact. If release-signing secrets are not configured, the Gradle configuration falls back to the debug key so the CI build remains installable for testing.
