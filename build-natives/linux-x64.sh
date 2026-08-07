#!/bin/sh
# Build Little CMS 2.19 from source for linux-x64 and stage its shared library.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/build/Little-CMS-lcms2.19}"
PREFIX="$ROOT/build/prefix-linux-x64"
DEST="$ROOT/natives/src/main/resources/lcms2-natives/linux-x64"
BUILD="$SRC/build-linux-x64"

cmake -S "$SRC" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DLCMS2_BUILD_SHARED=ON -DLCMS2_BUILD_STATIC=OFF \
  -DLCMS2_BUILD_TOOLS=OFF -DLCMS2_BUILD_TESTS=OFF
ninja -C "$BUILD" install

mkdir -p "$DEST"
find "$DEST" -type f -delete

so="$(find "$PREFIX/lib" -type f -name 'liblcms2.so*' | head -1)"
[ -n "$so" ] || { echo "installed liblcms2 shared library not found"; exit 1; }
base="$(patchelf --print-soname "$so")"
cp "$so" "$DEST/$base"
chmod 644 "$DEST/$base"
patchelf --set-rpath '$ORIGIN' "$DEST/$base"
printf '%s\n' "$base" > "$DEST/manifest.txt"

if readelf -d "$DEST/$base" | awk '/NEEDED/ {print $NF}' | tr -d '[]' \
    | grep -vE '^(libc|libm|libpthread|libdl|librt)\.so|^ld-linux'; then
  echo "ERROR: $base links non-system libraries (above)"; exit 1
fi
cp "$SRC/LICENSE" "$DEST/LICENSE"
{
  echo "Little CMS 2.19 (linux-x64), built from unmodified source"
  echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ) on $(uname -sm)"
  echo "source: https://github.com/mm2/Little-CMS tag lcms2.19"
  echo "cmake flags: Release, shared library only, tools/tests/plugins disabled"
} > "$DEST/BUILD-INFO.txt"

echo "staged:"
ls -la "$DEST"

