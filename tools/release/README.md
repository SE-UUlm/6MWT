# Release helpers

These scripts primarily support CI with version validation, Android signing configuration, APK verification and GitHub Release publication.

- `version.py` checks that app and Visualizer versions agree and optionally validates a release tag.
- `configure_signing.py` prepares Android signing configuration from CI secrets.
- `verify_apk.py` checks the built APK's version and signature.
- `publish.py` handles uploading the complete release asset set and publishing the release.

App and Visualizer are released together. The workflows in `.github/workflows/` invoke these scripts automatically. You can also run the applicable validation checks locally before preparing a release; signing configuration and publication still require the relevant credentials. Downloading or using a release does not require running them. Keep signing material and credentials out of the repository.

See [Builds and Releases](../../wiki/Builds-and-Releases.md) for local builds, signing, checks and publication.
