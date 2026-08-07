#!/bin/sh
# Generate the complete public Little CMS 2 API while excluding declarations
# inherited from stdio/time/system headers. Generated lookup code is redirected
# to Lcms2Libs so the same Java sources work with every native classifier.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JX="${JEXTRACT:-$ROOT/../ffmpeg-ffm/tools/jextract-22/bin/jextract}"
PREFIX="${LCMS2_PREFIX:-$ROOT/build/prefix-macos-arm64}"
OUT="$ROOT/core/src/main/java"
PKG="io.github.ghosthack.lcms2ffm.lcms2"
HEADER="$PREFIX/include/lcms2.h"
DUMP="$ROOT/build/lcms2-jextract-includes.txt"

[ -x "$JX" ] || { echo "jextract not found at $JX (set JEXTRACT=)"; exit 1; }
[ -f "$HEADER" ] || { echo "run build-natives/macos-arm64.sh first (or set LCMS2_PREFIX)"; exit 1; }
mkdir -p "$ROOT/build"

"$JX" --dump-includes "$DUMP" -I "$PREFIX/include" "$ROOT/jextract/lcms2_api.h" >/dev/null 2>&1

# Convert only declarations attributed to lcms2.h into exact jextract options.
# Exclude cmsfilelength because its C 'long' return ABI differs on Windows.
set --
while read -r option name rest; do
  case "$option:$name" in
    --include-function:cmsfilelength) continue ;;
  esac
  set -- "$@" "$option" "$name"
done <<EOF
$(awk -v header="$HEADER" '$0 ~ "# header: " header "$" { print $1, $2 }' "$DUMP")
EOF

GEN_DIR="$OUT/$(echo "$PKG" | tr . /)"
if [ -d "$GEN_DIR" ]; then
  find "$GEN_DIR" -type f -name '*.java' -delete
fi

"$JX" --output "$OUT" -t "$PKG" \
  --header-class-name Lcms2 \
  -I "$PREFIX/include" \
  -l ":$PREFIX/lib/liblcms2.dylib" \
  "$@" "$ROOT/jextract/lcms2_api.h"

perl -0777 -pi -e \
  's/static final SymbolLookup SYMBOL_LOOKUP = .*?;/static final SymbolLookup SYMBOL_LOOKUP = io.github.ghosthack.lcms2ffm.Lcms2Libs.lookup();/s' \
  "$GEN_DIR"/Lcms2*.java

if grep -rn "$PREFIX" "$GEN_DIR" >/dev/null; then
  echo "ERROR: build-prefix paths survived in generated stubs"; exit 1
fi
grep -q 'Lcms2Libs.lookup()' "$GEN_DIR"/Lcms2*.java || { echo "ERROR: lookup patch did not apply"; exit 1; }
echo "Generated $(find "$GEN_DIR" -name '*.java' | wc -l | tr -d ' ') Java files into $GEN_DIR"
