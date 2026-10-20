"""Prepare repository links for GitHub Wiki publication."""

import argparse
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]

# Inline Markdown links/images and HTML image/link attributes used by our docs.
LINK = re.compile(
    r'(?P<md>!?\[[^\]\n]*\]\()(?P<url><[^>]+>|[^\s)]+)(?P<end>\))|(?P<html>(?:src|href)=")(?P<attr>[^"]+)(?P<quote>")'
)


def prepare(output):
    source = ROOT / "wiki"
    output = output.resolve()

    if (
        output == source
        or output.is_relative_to(source)
        or source.is_relative_to(output)
    ):
        raise SystemExit("Publish to a separate staging directory.")

    shutil.copytree(source, output, dirs_exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    base = "https://github.com/SE-UUlm/6MWT"

    for page in source.glob("*.md"):

        def replace(match):
            url = (match["url"] or match["attr"]).strip("<>")
            parts = urlsplit(url)

            if parts.scheme or parts.netloc or not parts.path:
                return match.group(0)

            target = (page.parent / unquote(parts.path)).resolve()
            suffix = ("?" + parts.query if parts.query else "") + (
                "#" + parts.fragment if parts.fragment else ""
            )

            if target.is_relative_to(source):
                # The publishing action keeps the Wiki's directory structure.
                # It also handles page links and README -> Home.
                return match.group(0)
            else:
                kind = "tree" if target.is_dir() else "blob"
                rewritten = f"{base}/{kind}/main/" + quote(
                    target.relative_to(ROOT).as_posix()
                )

            return (
                (match["md"] or match["html"])
                + rewritten
                + suffix
                + (match["end"] or match["quote"])
            )

        text = LINK.sub(replace, page.read_text())

        if not page.name.startswith("_"):
            edit = f"{base}/edit/main/wiki/{quote(page.name)}"
            text = (
                f"_Published automatically on {timestamp}. [Edit the repository source]({edit}); direct Wiki edits will be overwritten._\n\n"
                + text
            )

        (output / page.name).write_text(text)

    print(f"Wiki staged in {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="Separate staging directory")
    args = parser.parse_args()

    prepare(args.output)
