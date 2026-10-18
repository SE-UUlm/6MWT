# Releases

App and visualizer are released together. Both `app/pubspec.yaml` and
`tools/6mwt_data_visualizer/pubspec.yaml` must contain the same
`version: MAJOR.MINOR.PATCH+BUILD`. These files determine the installed version;
a Git tag does not change Flutter's version. A tag `vMAJOR.MINOR.PATCH` identifies
the source commit and triggers `.github/workflows/release.yml`.

## Prepare a release

1. Update both pubspec versions in a PR. Increase the build number for each new
   release; never reset it when the visible version changes. For example,
   `1.0.0+1` → `1.0.1+2` for a fix, then `1.1.0+3` for a feature release.
   The first release can use the current `1.0.0+1`.
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
these artifacts seven days after upload. Existing artifacts keep their original
retention; this change does not retroactively delete them. Caches have their own
retention rules.

Downloads attached to a **published GitHub Release are separate copies** and do
not expire with the Actions artifacts. They remain until explicitly deleted.
If a failed release run is retried after its intermediate artifacts expired,
rerun all jobs to rebuild the complete set before publishing.

A manual **Actions → Release → Run workflow** run on `main` remains available for
troubleshooting or an unconditional full rehearsal. It runs all checks and builds,
using the real Android key, but only uploads seven-day Actions artifacts and never
creates a GitHub release. It is not normally needed before tagging. Manual runs
on commits outside main are rejected.

## Android key setup (once, before merging the workflow)

Use one permanent key for main and releases. If an existing production key is
available, reuse it. Otherwise create it on a trusted machine, outside the repo:

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

- **Android:** `6mwt-VERSION-android.apk`, a universal APK signed with the permanent
  key. Enable installation from the download source on the Android device.
- **iOS:** `6mwt-VERSION-ios-unsigned.ipa`. Sign/install with Sideloadly or AltStore
  using your Apple account. This is not a directly installable App Store IPA;
  local provisioning restrictions and expiry apply.
- **Windows x64:** `6mwt-visualizer-VERSION-windows-x64.zip`. Extract the entire
  archive and run `six_mwt_visualizer.exe`. Keep DLLs and `data` alongside it.
  The Microsoft Visual C++ 2015–2022 x64 runtime may need installing.
- **Linux x64:** `6mwt-visualizer-VERSION-linux-x64.tar.gz`. Built on Ubuntu 24.04;
  use Ubuntu 24.04 or a compatible system with GTK 3 and the C++ runtime installed.
  Extract the whole bundle and run `./six_mwt_visualizer`. The archive is not a
  fully static executable and does not bundle system GTK/glibc libraries.
- **macOS:** `6mwt-visualizer-VERSION-macos-universal.zip`. Extract the `.app` for
  Intel or Apple Silicon. It uses ad-hoc signing, with no Developer ID or Apple
  notarization. macOS may require allowing it through Privacy & Security after
  the first launch attempt; managed machines may prohibit this.

Visualizer archives contain the app and its runtime files, not this repository's
recordings. Open your own recordings using its folder/file picker. Desktop
installers and store distribution are outside this release workflow.

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
