"""Export desktop icons from the master with ImageMagick 7; not needed to build."""

from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets/branding/app_icon.png"


def export(path, size, *options):
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        "magick", str(MASTER), "-resize", f"{size}x{size}",
        "-alpha", "off", "-strip", *options, str(path),
    ], check=True)


for size in (16, 32, 64, 128, 256, 512, 1024):
    export(ROOT / f"macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{size}.png", size)
export(ROOT / "windows/runner/resources/app_icon.ico", 256,
       "-define", "icon:auto-resize=256,128,64,48,32,16")
export(ROOT / "linux/runner/resources/app_icon.png", 512)
