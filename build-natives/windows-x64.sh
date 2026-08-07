#!/bin/sh
# Build Little CMS 2.19 from source in an MSYS2 MINGW64 shell and stage its DLL.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$ROOT/build/Little-CMS-lcms2.19}"
PREFIX="$ROOT/build/prefix-windows-x64"
DEST="$ROOT/natives/src/main/resources/lcms2-natives/windows-x64"
BUILD="$SRC/build-windows-x64"

cmake -S "$SRC" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DLCMS2_BUILD_SHARED=ON -DLCMS2_BUILD_STATIC=OFF \
  -DLCMS2_BUILD_TOOLS=OFF -DLCMS2_BUILD_TESTS=OFF
ninja -C "$BUILD" install

mkdir -p "$DEST"
find "$DEST" -type f -delete
: > "$DEST/manifest.txt"

dll="$(find "$PREFIX" -type f -iname 'lcms2*.dll' | head -1)"
[ -n "$dll" ] || { echo "installed lcms2 DLL not found"; exit 1; }
for runtime in libwinpthread-1.dll libgcc_s_seh-1.dll; do
  if [ -f "/mingw64/bin/$runtime" ] && objdump -p "$dll" | grep -qi "DLL Name: $runtime"; then
    cp "/mingw64/bin/$runtime" "$DEST/$runtime"
    echo "$runtime" >> "$DEST/manifest.txt"
  fi
done
base="$(basename "$dll")"
cp "$dll" "$DEST/$base"
echo "$base" >> "$DEST/manifest.txt"

ALLOWED='lcms2|libwinpthread|libgcc_s_seh|KERNEL32|USER32|ADVAPI32|msvcrt|ntdll|api-ms-'
for file in "$DEST"/*.dll; do
  if objdump -p "$file" | awk '/DLL Name:/{print $3}' | grep -viE "^($ALLOWED)"; then
    echo "ERROR: $file imports unexpected DLLs (above)"; exit 1
  fi
done
cp "$SRC/LICENSE" "$DEST/LICENSE"
{
  echo "Little CMS 2.19 (windows-x64), built from unmodified source with MSYS2 mingw-w64"
  echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "source: https://github.com/mm2/Little-CMS tag lcms2.19"
  echo "cmake flags: Release, shared library only, tools/tests/plugins disabled"
} > "$DEST/BUILD-INFO.txt"

echo "staged:"
ls -la "$DEST"

