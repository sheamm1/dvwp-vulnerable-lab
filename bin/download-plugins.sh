#!/usr/bin/env bash
set -euo pipefail

# Downloads every intentionally-vulnerable plugin/theme at its vulnerable
# version straight from wordpress.org. Uses `svn export` when available,
# otherwise falls back to downloading the release zip.
#
# Run this before `docker compose up` the first time:
#   bin/download-plugins.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# kinds: plugin | theme
# slug:   wordpress.org slug (used in SVN path and release zip)
# ver:    vulnerable version to pin
PLUGINS=(
  "iwp-client 1.9.4.4"
  "social-warfare 3.5.2"
  "wp-advanced-search 3.3.3"
  "wp-file-upload 4.12.2"
  "wp-file-manager 6.0"
  "duplicator 1.3.26"
  "custom-content-type-manager 0.9.8.1"
  "wp-time-capsule 1.21.15"
)

THEMES=(
  "twentytwentyfive 1.5"
  "shapely 1.2.7"
  "sparkling 2.4.8"
)

# Install extracted content into $dest, unwrapping a single wrapper folder or
# a publisher-uploaded zip. Handles both "one top-level dir" archives and
# flat (multiple top-level entries) exports.
normalize_into() {
  local src="$1" dest="$2"
  local zipfile entries topdir sub

  # Some tags in the SVN tree only contain a release zip (e.g. wp-file-manager).
  if [ -n "$(find "$src" -mindepth 1 -maxdepth 1 -name '*.zip' 2>/dev/null)" ]; then
    zipfile="$(find "$src" -mindepth 1 -maxdepth 1 -name '*.zip' | head -n1)"
    sub="$(mktemp -d)"
    unzip -q -o "$zipfile" -d "$sub"
    rm -f "$zipfile"
    src="$sub"
  fi

  entries="$(find "$src" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
  topdir="$(find "$src" -mindepth 1 -maxdepth 1 -type d | head -n1)"

  if [ "$entries" -eq 1 ] && [ -n "$topdir" ]; then
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")"
    mv "$topdir" "$dest"
  else
    rm -rf "$dest"
    mkdir -p "$dest"
    find "$src" -mindepth 1 -maxdepth 1 -exec mv {} "$dest" \;
  fi
  rm -rf "$src"
}

download_one() {
  local kind="$1" slug="$2" ver="$3" dest="$4"
  local work svn_url
  if [ "$kind" = theme ]; then
    svn_url="https://themes.svn.wordpress.org/$slug/$ver"
  else
    svn_url="https://plugins.svn.wordpress.org/$slug/tags/$ver"
  fi
  local zip_url="https://downloads.wordpress.org/$kind/$slug.$ver.zip"

  echo "=> $kind $slug ($ver)"
  if [ -d "$dest" ]; then
    echo "   already present, skipping"
    return 0
  fi

  work="$(mktemp -d)"
  if command -v svn >/dev/null 2>&1; then
    if svn export -q --force "$svn_url" "$work" 2>/dev/null; then
      echo "   downloaded via svn"
      normalize_into "$work" "$dest"
      return 0
    fi
    echo "   svn export failed, falling back to zip"
  fi

  if curl -L -s -f -o "$work/archive.zip" "$zip_url" >/dev/null 2>&1; then
    echo "   downloaded via zip"
    unzip -q -o "$work/archive.zip" -d "$work/extracted"
    rm -f "$work/archive.zip"
    normalize_into "$work/extracted" "$dest"
    rm -rf "$work"
  else
    echo "   ERROR: could not download $kind $slug $ver" >&2
    rm -rf "$work"
    return 1
  fi
}

mkdir -p plugins themes

for entry in "${PLUGINS[@]}"; do
  set -- $entry
  download_one plugin "$1" "$2" "plugins/$1"
done

for entry in "${THEMES[@]}"; do
  set -- $entry
  download_one theme "$1" "$2" "themes/$1"
done

# PHP 8 removed curly-brace string/array offset access ($s{0}), which several
# of these legacy plugins use. Rewrite it to square-bracket syntax. This runs
# unconditionally so already-downloaded trees are patched too.
patch_php8_curly_offsets() {
  echo "=> Patching PHP 8 curly-brace offsets in plugins/themes..."
  find plugins themes -name '*.php' -print0 \
    | xargs -0 sed -i -E 's/\$([A-Za-z_][A-Za-z0-9_]*)\{([^{}]*)\}/\$\1\[\2\]/g'
}
patch_php8_curly_offsets

echo
echo "Done. Plugins/ themes downloaded into ./plugins and ./themes."