"""Create/resume a draft; never replace an already published release."""

import json
import os
import subprocess
from pathlib import Path


def gh(*args):
    return subprocess.check_output(["gh", *args], text=True)


def main():
    tag = os.environ["RELEASE_TAG"]

    # Listing (with pagination) distinguishes missing releases from API/auth failures.
    pages = json.loads(
        gh(
            "api",
            "--paginate",
            "--slurp",
            f"repos/{os.environ['GH_REPO']}/releases?per_page=100",
        )
    )
    release = next((r for page in pages for r in page if r["tag_name"] == tag), None)
    if release and not release["draft"]:
        raise SystemExit(f"{tag} is already published; refusing to modify it")

    if release is None:
        gh(
            "release",
            "create",
            tag,
            "--verify-tag",
            "--draft",
            "--title",
            tag,
            "--generate-notes",
        )

    files = sorted(str(p) for p in Path("dist").iterdir() if p.is_file())
    if len(files) != 5:
        raise SystemExit("Expected exactly five release files")

    gh("release", "upload", tag, *files, "--clobber")

    # Only the draft is mutable. Publication is the final operation.
    gh("release", "edit", tag, "--draft=false")


if __name__ == "__main__":
    main()
