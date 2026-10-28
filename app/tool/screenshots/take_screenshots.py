"""Regenerate the README app screenshots in wiki/assets/ on a running Android emulator.

Builds tool/screenshots/main.dart once per screen as a release APK, captures it
with a clean demo-mode status bar and rounds the corners with ImageMagick 7.
Run from app/ with exactly one emulator connected:

    python3 tool/screenshots/take_screenshots.py [screen ...]
"""

import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT.parent / "wiki/assets"
APK = ROOT / "build/app/outputs/flutter-apk/app-release.apk"
PACKAGE = "de.uniulm.in.se.sixmwt"
SCREENS = ["home", "instructions", "profile", "walk", "result", "history"]

WIDTH = 860
RADIUS = 74
BORDER = "#d0d7de"


def adb(*args):
    return subprocess.run(["adb", *args], check=True, capture_output=True).stdout


def shell(*args):
    return adb("shell", *args).decode()


def match(pattern, text):
    found = re.search(pattern, text)
    if found is None:
        sys.exit(f"Not found on screen: {pattern}")
    return found.groups()


def center(node):
    x1, y1, x2, y2 = map(int, match(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', node))
    return (x1 + x2) // 2, (y1 + y2) // 2


def ui_nodes():
    shell("uiautomator", "dump", "/sdcard/screenshots.xml")
    return re.findall(r"<node [^>]*>", shell("cat", "/sdcard/screenshots.xml"))


def demo(command, **extras):
    args = ["am", "broadcast", "-a", "com.android.systemui.demo", "-e", "command", command]
    for key, value in extras.items():
        args += ["-e", key, value]
    shell(*args)


def enter_demo_mode():
    shell("settings", "put", "global", "sysui_demo_allowed", "1")
    demo("enter")
    demo("clock", hhmm="0941")
    demo("battery", level="100", plugged="false", powersave="false")
    demo("network", wifi="show", level="4", fully="true")
    # A shown mobile icon stays invisible on the emulator but keeps its slot,
    # which separates the Wi-Fi and battery icons.
    demo("network", mobile="hide", sims="0")
    demo("notifications", visible="false")
    demo("status", volume="hide", bluetooth="hide", location="hide", alarm="hide", sync="hide", mute="hide")


def screen_size():
    width, height = match(r"(\d+)x(\d+)", shell("wm", "size"))
    return int(width), int(height)


def edit_text_centers():
    """Centers of the visible text fields, top to bottom, from the accessibility tree."""
    fields = [center(node) for node in ui_nodes() if 'class="android.widget.EditText"' in node]
    return sorted(fields, key=lambda field: field[1])


def fill_profile():
    for (x, y), text in zip(edit_text_centers(), ["Demo", "30", "170", "65"]):
        shell("input", "tap", str(x), str(y))
        time.sleep(0.8)
        shell("input", "text", text)
        # Submitting closes the keyboard and removes the focus border.
        shell("input", "keyevent", "KEYCODE_ENTER")
        time.sleep(0.8)
    other = next(node for node in ui_nodes() if 'content-desc="Other/Prefer not to say"' in node)
    shell("input", "tap", *map(str, center(other)))
    time.sleep(0.8)


def show_walk_details():
    width, height = screen_size()
    shell("input", "swipe", str(width * 4 // 5), str(height // 2), str(width // 6), str(height // 2), "300")
    time.sleep(1.5)


def capture(screen, raw):
    subprocess.run(
        ["flutter", "build", "apk", "--release", "-t", "tool/screenshots/main.dart", f"--dart-define=SCREEN={screen}"],
        cwd=ROOT, check=True, stdout=subprocess.DEVNULL,
    )
    adb("install", "-r", str(APK))
    shell("am", "force-stop", PACKAGE)
    shell("monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(4)
    if screen == "profile":
        fill_profile()
    elif screen == "walk":
        show_walk_details()
    raw.write_bytes(adb("exec-out", "screencap", "-p"))


def round_corners(raw, target):
    subprocess.run(
        [
            "magick", str(raw), "-resize", f"{WIDTH}x", "-alpha", "set",
            "(", "+clone", "-alpha", "transparent", "-fill", "white",
            "-draw", f"roundrectangle 0,0 %[fx:w-1],%[fx:h-1] {RADIUS},{RADIUS}", ")",
            "-compose", "DstIn", "-composite",
            # A thin outline keeps the white screens apart from a light page.
            "(", "+clone", "-alpha", "transparent", "-fill", "none", "-stroke", BORDER, "-strokewidth", "3",
            "-draw", f"roundrectangle 1.5,1.5 %[fx:w-2.5],%[fx:h-2.5] {RADIUS - 1},{RADIUS - 1}", ")",
            "-compose", "Over", "-composite",
            "-strip", "-define", "png:compression-level=9", str(target),
        ],
        check=True,
    )


def main():
    screens = sys.argv[1:] or SCREENS
    unknown = set(screens) - set(SCREENS)
    if unknown:
        sys.exit(f"Unknown screens: {', '.join(sorted(unknown))}")
    # The screenshot build replaces an installed release app.
    if f"package:{PACKAGE}" in shell("pm", "list", "packages", PACKAGE).split():
        sys.exit(f"Uninstall {PACKAGE} first; the screenshot build would replace it.")

    enter_demo_mode()
    try:
        with tempfile.TemporaryDirectory() as tmp:
            for screen in screens:
                print(f"Capturing {screen}")
                raw = Path(tmp) / f"{screen}.png"
                capture(screen, raw)
                round_corners(raw, ASSETS / f"app-{screen}.png")
    finally:
        demo("exit")
        subprocess.run(["adb", "uninstall", PACKAGE], capture_output=True)


main()
