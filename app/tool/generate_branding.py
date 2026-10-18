"""Export native branding sizes from the checked-in master using ImageMagick 7."""

import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets/branding/app_icon.png"
RES = ROOT / "android/app/src/main/res"
CATALOG = ROOT / "ios/Runner/Assets.xcassets"


def export(path, size, artwork_size=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    artwork_size = artwork_size or size
    subprocess.run(
        [
            "magick", str(MASTER), "-resize", f"{artwork_size}x{artwork_size}",
            "-background", "white", "-gravity", "center", "-extent", f"{size}x{size}",
            "-alpha", "remove", "-alpha", "off", "-strip", f"PNG24:{path}",
        ],
        check=True,
    )


for density, scale in [("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2), ("xxhdpi", 3), ("xxxhdpi", 4)]:
    export(RES / f"mipmap-{density}/ic_launcher.png", round(48 * scale))
    # Keep the complete illustration within adaptive-icon and splash safe areas.
    export(RES / f"drawable-{density}/ic_launcher_foreground.png", round(108 * scale), round(66 * scale))
    export(RES / f"drawable-{density}/launch_image.png", round(240 * scale))
    export(RES / f"drawable-{density}/splash_icon.png", round(288 * scale), round(180 * scale))

icons = CATALOG / "AppIcon.appiconset"
for item in json.loads((icons / "Contents.json").read_text())["images"]:
    size = round(float(item["size"].split("x")[0]) * float(item["scale"].rstrip("x")))
    export(icons / item["filename"], size)

for scale in (1, 2, 3):
    suffix = "" if scale == 1 else f"@{scale}x"
    export(CATALOG / f"LaunchImage.imageset/LaunchImage{suffix}.png", 240 * scale)
