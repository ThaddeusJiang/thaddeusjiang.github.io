#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

snapshot_tiddlers() {
  find tiddlers -type f -print | LC_ALL=C sort | while IFS= read -r file; do
    printf '%s  %s\n' "$(git hash-object "$file")" "$file"
  done
}

count_gyazo_references() {
  { find tiddlers -type f -name '*.tid' -exec grep -ho 'https://i\.gyazo\.com/' {} + 2>/dev/null || true; } \
    | wc -l \
    | tr -d ' '
}

list_expected_images() {
  find tiddlers -type f \( \
    -iname '*.avif' -o \
    -iname '*.bmp' -o \
    -iname '*.gif' -o \
    -iname '*.ico' -o \
    -iname '*.jpg' -o \
    -iname '*.jpeg' -o \
    -iname '*.png' -o \
    -iname '*.svg' -o \
    -iname '*.webp' \
  \) -print0 | while IFS= read -r -d '' image; do
    metadata="$image.meta"
    title=$(basename "$image")

    if [[ -f "$metadata" ]]; then
      metadata_title=$(sed -n 's/^title:[[:space:]]*//p' "$metadata" | head -n 1)
      title=${metadata_title:-$title}
    fi

    [[ "$title" == '$:/'* ]] && continue

    nub -e 'process.stdout.write(`${encodeURIComponent(process.argv[1])}\n`)' "$title"
  done
}

cd "$REPO_ROOT"

TIDDLERS_BEFORE=$(snapshot_tiddlers)
GYAZO_BEFORE=$(count_gyazo_references)

./build

TIDDLERS_AFTER=$(snapshot_tiddlers)
GYAZO_AFTER=$(count_gyazo_references)

[[ "$TIDDLERS_AFTER" == "$TIDDLERS_BEFORE" ]] || fail 'build modified source tiddlers'
[[ "$GYAZO_AFTER" == "$GYAZO_BEFORE" ]] || fail 'build modified Gyazo references'

[[ -f docs/index.html ]] || fail 'docs/index.html was not generated'
[[ -f docs/tiddlyjam/index.html ]] || fail 'docs/tiddlyjam/index.html was not generated'
[[ -d docs/assets ]] || fail 'docs/assets was not generated'
[[ -d docs/tiddlyjam/assets ]] || fail 'docs/tiddlyjam/assets was not generated'
[[ ! -e docs/images ]] || fail 'legacy docs/images was generated'
[[ ! -e docs/tiddlyjam/images ]] || fail 'legacy docs/tiddlyjam/images was generated'

EXPECTED_IMAGES=()

while IFS= read -r image; do
  EXPECTED_IMAGES+=("$image")
done < <(list_expected_images)

[[ "${#EXPECTED_IMAGES[@]}" -gt 0 ]] || fail 'no source images were discovered'

for image in "${EXPECTED_IMAGES[@]}"; do
  [[ -f "docs/assets/$image" ]] || fail "missing docs/assets/$image"
  [[ -f "docs/tiddlyjam/assets/$image" ]] || fail "missing docs/tiddlyjam/assets/$image"
done

ASSET_COUNT=$(find docs/assets -maxdepth 1 -type f | wc -l | tr -d ' ')
TIDDLYJAM_ASSET_COUNT=$(find docs/tiddlyjam/assets -maxdepth 1 -type f | wc -l | tr -d ' ')

[[ "$ASSET_COUNT" == "${#EXPECTED_IMAGES[@]}" ]] || fail "docs/assets contains $ASSET_COUNT files"
[[ "$TIDDLYJAM_ASSET_COUNT" == "${#EXPECTED_IMAGES[@]}" ]] || fail "docs/tiddlyjam/assets contains $TIDDLYJAM_ASSET_COUNT files"

grep -Fq '"_canonical_uri":"./assets/Stop%2520Losing%2520Solutions%2520Again.png"' docs/index.html \
  || fail 'index.html does not contain the expected canonical image URI'

grep -RFl 'src="./assets/Dont-become-like-this.png"' docs/tiddlyjam --include='*.html' >/dev/null \
  || fail 'TiddlyJam did not emit a root-relative external asset URI'

if grep -RFl 'src="../assets/' docs/tiddlyjam --include='*.html' >/dev/null; then
  fail 'TiddlyJam still points images at ../assets, which 404s when served as the site root'
fi

grep -RFl 'src="./assets/2026-08-27-zeabur-%25E5%25AE%2589%25E5%2585%25A8%25E4%25BA%258B%25E4%25BB%25B6.jpg"' docs/tiddlyjam --include='*.html' >/dev/null \
  || fail 'TiddlyJam did not emit the CJK article image URI'

EMBEDDED_PREFIX=$(base64 < tiddlers/Dont-become-like-this.png | tr -d '\n' | cut -c1-80)

if grep -Fq "$EMBEDDED_PREFIX" docs/index.html; then
  fail 'index.html still embeds content image data'
fi

printf 'PASS: external images are published under assets without changing tiddlers or Gyazo references\n'
