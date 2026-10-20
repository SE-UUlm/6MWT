# Development

## Toolchains and checkout

CI and release builds use **Flutter 3.44.4 stable**, pinned in [the shared CI configuration](../.github/flutter-version.yaml). Use that version for reproducible local checks; newer stable versions may work but are not validated by CI. No separate Dart installation is required. Install Git and the native tooling for your target:

- Android: Android SDK and Java 17; an emulator or a phone with USB debugging.
- iOS/macOS: macOS and Xcode with the relevant platform SDK; device signing for local iPhone runs.
- Linux: clang, CMake, Ninja, pkg-config, GTK 3 development headers and the C++ development library. CI uses Ubuntu 24.04 packages `clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev`.
- Windows: Visual Studio with Desktop development with C++ and a Windows SDK.
- Python 3 for release and branding helpers; ImageMagick 7 only when regenerating icons.

```sh
git clone https://github.com/SE-UUlm/6MWT.git
cd 6MWT
```

### App
```sh
cd app
flutter devices
flutter run
```

Run `flutter doctor -v` when Flutter setup, a target device or a build does not work as expected.

### Visualizer

Keep the complete checkout: the Visualizer depends on the app through `../../app`.
From the repository root:

```sh
cd tools/6mwt_data_visualizer
flutter run -d linux
```

Use `-d macos` or `-d windows` on those hosts. Native desktop builds require the corresponding host OS. For optional authenticated satellite tiles, create an ignored `arcgis.local.json` in the Visualizer directory with `{"ARCGIS_ACCESS_TOKEN":"YOUR_TOKEN"}` and start with `--dart-define-from-file=arcgis.local.json`. The token requires the `premium:user:basemaps` (Basemap Styles Service) privilege. Without a token the app uses the anonymous endpoint, which can throttle requests. Never commit tokens.

## Generation and checks

Run these in each package after dependency installation:

```sh
dart run build_runner build
dart format .
flutter analyze
flutter test
```

Generate after changes to annotated Riverpod providers or Drift models and commit generated files. App localization uses `flutter gen-l10n` after editing `lib/l10n/*.arb`; see [Localization](Architecture.md#localization). Follow [Database Migrations](Database-Migrations.md) for schema changes. See [Builds and Releases](Builds-and-Releases.md) for build commands and outputs.

## App and visualizer CI

Checks mean **formatting, static analysis and automated tests**. Workflow files
are in `.github/workflows/`.

| Workflow | Trigger | Checks / builds |
| --- | --- | --- |
| `flutter-ci.yml` | Push (including feature branches) | App checks, for relevant app/CI/SDK changes |
| `flutter-builds.yml` | PR; push to `main` | Android APK + unsigned iOS IPA; relevant changes only on PRs, always on `main` |
| `visualizer-ci.yml` | PR; push to `main` | Visualizer checks; additionally Windows/Linux/macOS builds on `main`; relevant changes only |
| `release-checks.yml` | PR; push to `main` | Shared version validation and release-script tests, when versions or release/CI configuration change |
| `release.yml` | Push of `vX.Y.Z` tag | All app/visualizer checks and all five builds; publish GitHub Release only after success |
| `release.yml` | Manual “Run workflow” | Same checks/builds, without publishing; selected commit must belong to `main` history |

Visualizer-relevant changes include `tools/6mwt_data_visualizer/**`, `app/**`,
`data/**`, release helpers and relevant workflow/SDK configuration. Release runs
never skip work based on changed paths. 

Android uses the debug key on PRs and the permanent keystore on `main` and release
runs. iOS stays unsigned. Actions downloads expire after **7 days**; published
release downloads remain. See [Builds and Releases](Builds-and-Releases.md) for setup and tagging.

### Required PR checks

For the `main` ruleset, require `Format`, `Analyze`, `Test`, `Visualizer Format`,
`Visualizer Analyze`, `Visualizer Test`, `Commitlint - all PR commits` and
`PR builds` (source: GitHub Actions). Keep existing security checks as appropriate.
`PR builds` is the stable summary of the Android/iOS builds, including deliberate
skips for unrelated changes.

## Pedometer workaround

In `pedometer` 4.2.0, Android's `_androidStream` has an internal subscription
without an error handler. `PedometerSource` uses `runZonedGuarded` to log errors
that bypass its normal stream handlers.

After package updates, check `_androidStream` in `lib/pedometer.dart` before
removing the workaround. Verify error handling on Android with an unavailable
step sensor or an injected channel error: escaping errors should be logged and
GPS tracking should remain usable. Device verification remains necessary after changing this workaround.

## Commit Messages

We are following [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for our commit messages.

Format: `<type>[optional scope]: <description>`

* Example 1: `feat: implement settings screen`
* Example 2: `docs: add docs for our gps outlier algorithm`

### Possible types:
* **feat**: A new feature for the user, not a new feature for a build script.
* **fix**: A bug fix for the user, not a fix to a build script.
* **docs**: Changes to only the documentation (e.g. Markdown files, inline code comments).
* **test**: Adding missing tests or correcting existing tests (no production code changes).
* **refactor**: A code change that neither fixes a bug nor adds a feature (e.g. rewriting code for readability or structure).
* **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc.).
* **perf**: A code change that improves performance.
* **build**: Changes that affect the build system or external dependencies (e.g. Pub, npm, Gradle).
* **ci**: Changes to our CI configuration files and scripts (e.g. GitHub Actions).
* **chore**: Other changes that don't modify src or test files (e.g., updating `.gitignore` or repository maintenance).
* **revert**: Reverts a previous commit. (e.g., `revert: feat: implement settings screen`).

Message Format is checked in CI/CD Pipeline. Last Commit Message can be checked locally using (nodejs required):

```
npx --package @commitlint/cli --package @commitlint/config-conventional commitlint --last --verbose
```

## Contribution workflow

1. Open an issue describing the change.
2. Create a branch from `main`, for example `feat/23-settings` or `docs/wiki-installation`.
3. Commit with Conventional Commits and run relevant checks.
4. Open a pull request targeting `main`, link the issue, and describe changes and verification.
5. Merge after review and passing checks.

## Branding

Android and iOS use `6MWT` for Release/Profile and `6MWT Debug` for Debug.
The IDs are `de.uniulm.in.se.sixmwt` and `de.uniulm.in.se.sixmwt.debug`.
The native launch screen uses the walking illustration on white, without a delay.

The icon master is `assets/branding/app_icon.png`, prepared from the existing
`assets/images/logo.png` with the built-in image generation tool. The original
in-app illustration is retained. To regenerate native PNG sizes with ImageMagick 7:

```sh
python3 tool/generate_branding.py
```

Phone orientation is portrait-up, configured both before Flutter starts and in
native Android/iPhone settings. iPad configuration is unchanged. Android 16+
can ignore orientation locks on displays at least 600 dp wide; see the
[Flutter orientation documentation](https://api.flutter.dev/flutter/services/SystemChrome/setPreferredOrientations.html).

The native app and window name is **6MWT Visualizer** on macOS, Windows and Linux. 
The checked-in master is `assets/branding/app_icon.png`. 
It was created using the main app icon as a reference.

All native icon files are checked in; builds do not need image-generation tools.
To regenerate them after editing the master, install ImageMagick 7 and run:

```sh
python3 tool/generate_branding.py
```

Linux embeds the icon into the executable for direct launches. The build bundle
also includes `share/applications/de.uniulm.in.se.sixmwt.visualizer.desktop` and
`share/icons/hicolor/512x512/apps/de.uniulm.in.se.sixmwt.visualizer.png`.
For an application-menu entry (including Wayland dock icons), copy those into the
matching directories under `~/.local/share/`. Set the copied desktop entry's
`Exec` field to the quoted absolute path of the executable in the retained bundle,
or make `six_mwt_visualizer` available on `PATH`. Keep the bundle's `data/` and
`lib/` directories beside the executable. Building does not install a menu entry
or modify your desktop settings.

## Documentation checks and publishing

CI checks links in all markdown files and all wiki pages. The source entry page is `wiki/README.md`, which GitHub displays when browsing that folder. The publishing action renames it to `Home.md` in GitHub Wiki and converts normal Markdown page links.

The small `prepare_wiki.py` helper stages the files and converts links outside `wiki/` to absolute URLs, and adds a notice linking to the editable repository source. It leaves source files, page names, 
assets in `wiki/` and normal page links unchanged. To preview its output from the repository root:

```sh
python3 .github/scripts/prepare_wiki.py /tmp/6mwt-wiki-preview
```

This command only prepares files; a push to `main` triggers the action's preprocessing and publication.

Keep source links relative (for example `App-Installation.md` or `../app/`) and images in `wiki/assets/`.
