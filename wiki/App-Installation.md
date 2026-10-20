# App Installation

Download from the [Latest Release](https://github.com/SE-UUlm/6MWT/releases/latest).

## Requirements

| Platform | Configured baseline | Hardware and permissions |
| --- | --- | --- |
| Android | Android 7.0 / API 24 (Flutter 3.44.4 default); universal APK for ARM 32-bit, ARM64 and x86-64 | Phone with location/GPS; precise location enabled; physical activity permission for steps |
| iOS | iOS 13.0 deployment target; ARM64 device IPA | iPhone with location; Location and Motion & Fitness permissions; Windows or Mac computer, Apple account and cable for initial signing/install |

These are build targets, not a tested device matrix. The current release packages and native settings were inspected during the documentation revision. Step sensors are optional: unavailable steps reduce fallback options, while unavailable GPS prevents starting a test. Allow notification/background location prompts where shown. OS power management can interrupt recording.

## Android

1. Download `6mwt-VERSION-android.apk` onto the phone.
2. Open it from Downloads. If prompted, allow **Install unknown apps** for that browser/file manager, then return and install.
3. Open **6MWT**. Enable location services and grant precise location and physical activity permissions when requested.
4. Create a profile, read the instructions and open the walking screen. Allow GPS to acquire a position before starting.

If Android specifically blocks an **unverified developer**, enable its Advanced Flow before retrying the installation:

1. Enable Developer Mode in the system settings. The exact settings path varies by device and Android version.
2. In Developer Option, select **Install apps from unverified developers** (the wording can vary slightly by device).
3. Complete the confirmation that you are enabling the option yourself.
4. Restart the phone and authenticate again when Android requests it.
5. Wait for the one-time 24-hour safety delay, then install the APK again.

This opt-in is only needed where Android enforces developer verification; it is not required for every APK installation. Google's [Advanced Flow overview](https://developer.android.com/blog/posts/android-developer-verification-balancing-openness-and-choice-with-safety) explains the security checks behind these steps.

## iOS with Sideloadly

The download is unsigned and cannot be installed by opening it on the phone.

1. Install [Sideloadly](https://sideloadly.io/) on Windows or macOS. Follow its setup instructions for Apple device drivers/iTunes and iCloud on Windows.
2. Download `6mwt-VERSION-ios-unsigned.ipa` to the computer.
3. Connect and unlock the iPhone, then accept **Trust This Computer**.
4. Open Sideloadly, select the device and IPA, enter your Apple account and start signing/installing. Complete account authentication when requested.
5. On the phone, trust the developer profile under **Settings → General → VPN & Device Management** if requested.
6. On iOS 16 or later, enable **Settings → Privacy & Security → Developer Mode** if requested, restart and confirm.
7. Open **6MWT** and grant location and Motion & Fitness access.

With a free Apple account the signature normally lasts seven days; re-sign before expiry or configure Sideloadly's automatic refresh. Keep the same account and app identity for updates. See the [Sideloadly FAQ](https://sideloadly.io/faq) for current account limits, renewal and connection troubleshooting.

## Updates and problems

- Download a newer release and install over the existing app with the same signing identity. Android release builds share a permanent key; debug builds use a separate app ID.
- **App not installed / signature conflict:** an older locally signed release may use a different key. Export recordings before any required uninstall; uninstalling removes local app data.
- **iOS app stops opening:** renew the signature; check trust and Developer Mode.
