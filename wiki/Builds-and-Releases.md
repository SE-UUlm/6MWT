# Builds and Releases

App and visualizer are released together. Both `app/pubspec.yaml` and
`tools/6mwt_data_visualizer/pubspec.yaml` must contain the same
`version: MAJOR.MINOR.PATCH+BUILD`. These files determine the installed version;
a Git tag does not change Flutter's version. A tag `vMAJOR.MINOR.PATCH` identifies
the source commit and triggers `.github/workflows/release.yml`.

## Local builds

Install dependencies first as described in [Development](Development.md). From `app/`:

### App

```sh
flutter build apk --release
flutter build ios --release --no-codesign
```

The APK is `build/app/outputs/flutter-apk/app-release.apk`. The unsigned iOS device bundle is `build/ios/iphoneos/Runner.app` (macOS/Xcode required). CI packages it as `Payload/Runner.app` inside an IPA; the unsigned bundle requires local signing before installation. To reproduce that packaging from `app/`:

```sh
mkdir -p build/ipa-staging/Payload
cp -R build/ios/iphoneos/Runner.app build/ipa-staging/Payload/Runner.app
(cd build/ipa-staging && zip -qry ../six-minute-walk-test-unsigned.ipa Payload)
```

### Visualizer

From `tools/6mwt_data_visualizer/`, build on the matching host:

```sh
flutter build linux --release
flutter build windows --release
flutter build macos --release
```

| Target | Output to package in full |
| --- | --- |
| Linux | `build/linux/x64/release/bundle/` |
| Windows | `build/windows/x64/runner/Release/` |
| macOS | `build/macos/Build/Products/Release/6MWT Visualizer.app` |


## Prepare a release

1. Update both pubspec versions in a PR. Increase the visible version, 
   for example `1.0.0+1` → `1.0.1+1`. If the app is
   later distributed through Google Play, the App Store or TestFlight, use a
   monotonically increasing build number required by that platform instead.
2. Merge the PR into `main` and wait for the automated checks and builds.
   App and visualizer changes trigger the visualizer checks and all three desktop
   builds automatically. Download the signed main APK and desktop artifacts for
   a manual installation/startup check when needed.
3. Tag the exact merged commit and push that tag:

   ```sh
   git tag -a v1.0.0 <merge-commit-sha> -m 'Release 1.0.0'
   git push origin v1.0.0
   ```

CI validates the tag and matching pubspec versions, checks that the commit is
reachable from main, runs formatting, analysis and tests for both packages, and
builds all five downloads. No change filter can skip release checks. SDK selection
is pinned centrally in `.github/flutter-version.yaml`; update it deliberately
for all workflows together.

Only after all jobs succeed does CI create a draft, upload the complete set of
files, and publish it with generated release notes. A failed upload leaves a
draft: rerun the failed job to complete it. A published release is immutable to
this workflow; publish fixes under a new version/tag instead of moving tags or
replacing published binaries. Only stable `vX.Y.Z` tags are supported initially.

Development commits do not require version bumps. Main builds retain the pubspec
version/build number; exported app metadata includes the commit hash to identify
the exact source. Main builds are not a separately versioned update channel.
Installing an older version code over a newer release may require uninstalling.

## Development checks, builds and artifact retention

See [App and visualizer CI](Development.md#app-and-visualizer-ci) for a compact
overview of triggers, checks and builds.

All newly uploaded Actions artifacts (Android, iOS and desktop, including release
workflow intermediates) have `retention-days: 7`. GitHub automatically deletes
these artifacts seven days after upload. Caches have their own retention rules.

Downloads attached to a **published GitHub Release are separate copies** and do
not expire with the Actions artifacts. They remain until explicitly deleted.
If a failed release run is retried after its intermediate artifacts expired,
rerun all jobs to rebuild the complete set before publishing.

A manual **Actions → Release → Run workflow** run on `main` remains available for
troubleshooting or an unconditional full rehearsal. It runs all checks and builds,
using the real Android key, but only uploads seven-day Actions artifacts and never
creates a GitHub release. It is not normally needed before tagging. Manual runs
on commits outside main are rejected.

## Android key setup (once)

This has been already done for the ci and the keystore is saved in GitHub secrets.
The following information might still be useful for forks or for setting up local signed builds.

Use one permanent key for main and releases. Create it on a trusted machine, outside the repo:

```sh
keytool -genkeypair -v -keystore /secure/location/6mwt-release.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias 6mwt
```

Keep a secure backup of the keystore, alias and passwords. Losing the key prevents
updates to installations signed with it. Store these **repository Actions secrets**
in GitHub settings (the values must not be committed):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded contents of the keystore; line breaks are accepted |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias, e.g. `6mwt` |
| `ANDROID_KEY_PASSWORD` | Password for that key |

Main and release builds fail if a secret is missing. PR builds use the debug key
and receive no signing secrets. CI verifies each APK's version and signature;
trusted builds also compare the certificate with the configured keystore.
Signing files are temporary and removed even when the build fails.

For a local signed build, create the ignored `app/android/key.properties`:

```properties
storeFile=/absolute/path/to/6mwt-release.jks
storePassword=your-store-password
keyAlias=6mwt
keyPassword=your-key-password
```

Escape backslashes in Windows paths and special characters as Java properties
require. Local builds without these properties keep using the debug key. Set
`REQUIRE_RELEASE_SIGNING=true` to prohibit that fallback locally.

Existing APKs signed with a different debug key cannot be updated in place.
**Export recorded measurements before uninstalling the old app**, then install
the new signed APK. A signing-key change may also change the exported Android
device identifier. Subsequent main and release builds use the same certificate.

## Downloads and installation

See [App Installation](App-Installation.md) and [Visualizer](Visualizer.md) for requirements, download names and user instructions.

## Verification

```sh
python3 -m unittest discover -s tools/release -p 'test_*.py'
python3 tools/release/version.py --tag v1.0.0
```

For the first main build (or manual release rehearsal), download all artifacts and check:

- The Android certificate SHA-256 printed by CI matches for main and release;
  installing a newer build signed with that key preserves recorded data.
- Installed/exported version and build number match the pubspec; the commit hash
  matches the selected source commit.
- The iOS IPA contains `Payload/Runner.app`, and can be locally signed/installed.
- Each desktop archive starts outside the checkout and opens a recording. Test
  macOS on Intel and Apple Silicon. CI checks both executable architectures and
  the macOS bundle signature.
- A failed check/build prevents publication; a failed upload leaves only a draft.

Reference: [Flutter Android deployment](https://docs.flutter.dev/deployment/android),
[GitHub releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
