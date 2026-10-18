"""Write private signing files on the Android CI runner; never print secrets."""

import base64
import os
from pathlib import Path


def property_escape(value):
    # java.util.Properties uses ISO-8859-1 and treats backslashes specially.
    escaped = []
    for char in value:
        if ord(char) > 126:
            units = char.encode("utf-16-be")
            escaped.extend(
                "\\u%04x" % int.from_bytes(units[i : i + 2], "big")
                for i in range(0, len(units), 2)
            )
        elif char in "\\ :=#!":
            escaped.append("\\" + char)
        else:
            escaped.append({"\n": "\\n", "\r": "\\r", "\t": "\\t"}.get(char, char))
    return "".join(escaped)


def main():
    names = [
        "ANDROID_KEYSTORE_BASE64",
        "ANDROID_KEYSTORE_PASSWORD",
        "ANDROID_KEY_ALIAS",
        "ANDROID_KEY_PASSWORD",
    ]
    if any(not os.environ.get(name) for name in names):
        raise SystemExit(
            "Release signing requires all four ANDROID_* secrets; see wiki/Releases.md"
        )
    try:
        keystore = base64.b64decode(
            "".join(os.environ[names[0]].split()), validate=True
        )
    except ValueError:
        raise SystemExit("ANDROID_KEYSTORE_BASE64 is not valid base64") from None

    os.umask(0o077)
    path = Path(os.environ["RUNNER_TEMP"]) / "release-keystore.jks"
    path.write_bytes(keystore)

    values = {
        "storeFile": str(path),
        "storePassword": os.environ[names[1]],
        "keyAlias": os.environ[names[2]],
        "keyPassword": os.environ[names[3]],
    }
    Path("android/key.properties").write_text(
        "".join(f"{key}={property_escape(value)}\n" for key, value in values.items()),
        encoding="ascii",
    )


if __name__ == "__main__":
    main()
