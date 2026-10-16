#!/bin/sh
set -eu

# Run on every native build, including incremental builds and archives.
commit_hash=$(git -C "$SRCROOT" rev-parse --verify HEAD 2>/dev/null || true)
case "$commit_hash" in
  ''|*[!0-9a-f]*) commit_hash='' ;;
esac
if [ "${#commit_hash}" -ne 40 ] && [ "${#commit_hash}" -ne 64 ]; then
  commit_hash=''
fi
metadata_dir="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"
mkdir -p "$metadata_dir"
if [ -n "$commit_hash" ]; then
  printf '{"commitHash":"%s"}\n' "$commit_hash" > "$metadata_dir/build_metadata.json"
else
  echo 'warning: Git commit unavailable; exporting null commitHash' >&2
  printf '{"commitHash":null}\n' > "$metadata_dir/build_metadata.json"
fi
