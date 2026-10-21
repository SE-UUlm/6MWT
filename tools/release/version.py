"""Validate the shared release version without third-party dependencies."""

import argparse
import re
from pathlib import Path

VERSION = r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)"


def read_version(path):
    matches = re.findall(r"^version:\s*([^\s#]+)\s*(?:#.*)?$", path.read_text(), re.M)

    if len(matches) != 1 or not re.fullmatch(VERSION + r"\+[1-9][0-9]*", matches[0]):
        raise ValueError(
            f"{path}: expected one version: MAJOR.MINOR.PATCH+BUILD (positive build number)"
        )

    return matches[0]


def validate(root, tag=None):
    app = read_version(root / "app/pubspec.yaml")
    visualizer = read_version(root / "tools/6mwt_data_visualizer/pubspec.yaml")

    if app != visualizer:
        raise ValueError(f"App ({app}) and visualizer ({visualizer}) versions differ")

    version, build = app.split("+")
    if tag is not None and (
        not re.fullmatch("v" + VERSION, tag) or tag != "v" + version
    ):
        raise ValueError(f"Tag {tag!r} must equal v{version}")
    return version, build


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root", type=Path, default=Path(__file__).resolve().parents[2]
    )
    parser.add_argument("--tag")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    try:
        version, build = validate(args.root, args.tag)
    except ValueError as error:
        parser.exit(1, f"{error}\n")

    print(f"Validated {version}+{build}")

    if args.output:
        with args.output.open("a") as output:
            output.write(f"version={version}\nbuild={build}\n")
