"""Verify embedded APK metadata and, for trusted builds, the signing certificate."""

import hashlib
import os
import re
import subprocess
from pathlib import Path

from version import read_version


def run(*args):
    return subprocess.check_output(args, text=True)


def main():
    sdk = Path(os.environ["ANDROID_HOME"]) / "build-tools"
    versions = [p for p in sdk.iterdir() if re.fullmatch(r"\d+\.\d+\.\d+", p.name)]
    tools = max(versions, key=lambda p: tuple(map(int, p.name.split("."))))
    apk = "build/app/outputs/flutter-apk/app-release.apk"

    signature = run(str(tools / "apksigner"), "verify", "--print-certs", apk)

    version, build = read_version(Path("pubspec.yaml")).split("+")
    metadata = run(str(tools / "aapt"), "dump", "badging", apk)

    if (
        f"versionCode='{build}'" not in metadata
        or f"versionName='{version}'" not in metadata
    ):
        raise SystemExit("APK version does not match pubspec.yaml")

    if os.environ.get("SIGNED") == "true":
        certificate = subprocess.check_output(
            [
                "keytool",
                "-exportcert",
                "-keystore",
                str(Path(os.environ["RUNNER_TEMP"]) / "release-keystore.jks"),
                "-alias",
                os.environ["ANDROID_KEY_ALIAS"],
                "-storepass:env",
                "ANDROID_KEYSTORE_PASSWORD",
            ]
        )
        fingerprint = hashlib.sha256(certificate).hexdigest()

        if f"certificate SHA-256 digest: {fingerprint}" not in signature:
            raise SystemExit("APK certificate does not match the configured keystore")

        print(f"Confirmed release certificate SHA-256: {fingerprint}")
    print(f"Confirmed APK version {version}+{build} and valid signature")


if __name__ == "__main__":
    main()
