#!/bin/sh
# Build Little CMS 2.19 from source for macos-arm64 and stage its dylib.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/build/Little-CMS-lcms2.19}"
PREFIX="$ROOT/build/prefix-macos-arm64"
DEST="$ROOT/natives/src/main/resources/lcms2-natives/macos-arm64"
BUILD="$SRC/build-macos-arm64"

cmake -S "$SRC" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DLCMS2_BUILD_SHARED=ON -DLCMS2_BUILD_STATIC=OFF \
  -DLCMS2_BUILD_TOOLS=OFF -DLCMS2_BUILD_TESTS=OFF
ninja -C "$BUILD" install

mkdir -p "$DEST"
find "$DEST" -type f -delete

dylib="$(find "$PREFIX/lib" -type f -name 'liblcms2*.dylib' | head -1)"
[ -n "$dylib" ] || { echo "installed liblcms2 dylib not found"; exit 1; }
base="$(basename "$dylib")"
cp "$dylib" "$DEST/$base"
chmod 644 "$DEST/$base"
install_name_tool -id "@loader_path/$base" "$DEST/$base"
printf '%s\n' "$base" > "$DEST/manifest.txt"
cp "$SRC/LICENSE" "$DEST/LICENSE"
{
  echo "Little CMS 2.19 (macos-arm64), built from unmodified source"
  echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ) on $(uname -sm)"
  echo "source: https://github.com/mm2/Little-CMS tag lcms2.19"
  echo "cmake flags: Release, shared library only, tools/tests/plugins disabled"
} > "$DEST/BUILD-INFO.txt"

echo "staged:"
ls -la "$DEST"

