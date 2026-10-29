# App screenshots

Regenerate the app screenshots shown in the repository README with synthetic data on a running Android emulator.

`main.dart` starts the app with an in-memory database, a synthetic profile and a simulated walk; it lives in the app project because it builds on the app's code and assets. `take_screenshots.py` builds it once per screen, captures the emulator with a clean status bar and rounds the corners with ImageMagick 7.

Run from `app/`:

```sh
python3 tool/screenshots/take_screenshots.py
```

**Overwrites `wiki/assets/app-*.png`.** See [App screenshots](../../../wiki/Data-and-Tools.md#app-screenshots) for requirements and details.
