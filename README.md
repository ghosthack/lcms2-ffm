# lcms2-ffm

Panama FFM (jextract) bindings for the public **Little CMS 2.19** API with
bundled, from-source native libraries. No JNI and no system lcms2 installation
is required.

```xml
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>lcms2-ffm</artifactId>
  <version>2.19-0.1.0</version>
</dependency>
<dependency>
  <groupId>io.github.ghosthack</groupId>
  <artifactId>lcms2-ffm-natives</artifactId>
  <version>2.19-0.1.0</version>
  <classifier>macos-arm64</classifier> <!-- or windows-x64 / linux-x64 -->
  <scope>runtime</scope>
</dependency>
```

```java
import io.github.ghosthack.lcms2ffm.lcms2.Lcms2;

MemorySegment inputProfile = Lcms2.cmsOpenProfileFromMem(profileBytes, profileSize);
MemorySegment outputProfile = Lcms2.cmsCreate_sRGBProfile();
MemorySegment transform = Lcms2.cmsCreateTransform(
        inputProfile, Lcms2.TYPE_RGB_8(),
        outputProfile, Lcms2.TYPE_BGRA_8(),
        Lcms2.INTENT_RELATIVE_COLORIMETRIC(), 0);
Lcms2.cmsDoTransform(transform, inputPixels, outputPixels, pixelCount);
```

Close transforms with `cmsDeleteTransform` and profiles with `cmsCloseProfile`.
The API is a direct jextract binding: C pointers and opaque handles are
`MemorySegment` values, public C structs have generated layout/accessor classes,
and callback typedefs have generated upcall helpers. All portable declarations
from `lcms2.h` are generated; the C-runtime helper `cmsfilelength` is omitted
because its `long` ABI differs between Unix and Windows.

When using the module path, declare `requires lcms2.ffm;` and run with
`--enable-native-access=lcms2.ffm`. On the class path use
`--enable-native-access=ALL-UNNAMED` (JDK 22+).

## Library resolution

`Lcms2Libs.lookup()` resolves, in order:

1. `-Dlcms2ffm.libdir=<dir>` / `LCMS2_FFM_LIBDIR`;
2. the platform's `lcms2-ffm-natives` classifier jar, extracted once to
   `~/.cache/lcms2-ffm/<version>-<platform>/`;
3. already loaded and platform-default native symbols.

Classifier jars are built for `macos-arm64`, `windows-x64`, and `linux-x64`.

## Building

Fetch the matching source release, build the current platform native, regenerate
bindings on macOS, and test:

```sh
mkdir -p build
curl -fsSL https://github.com/mm2/Little-CMS/archive/refs/tags/lcms2.19.tar.gz \
  -o build/lcms2.19.tar.gz
tar -xzf build/lcms2.19.tar.gz -C build
build-natives/macos-arm64.sh
jextract/gen-bindings.sh
mvn clean install
```

The Linux and Windows scripts follow the same layout. `jextract` defaults to the
JDK 22 distribution in sibling `../ffmpeg-ffm`; set `JEXTRACT` to override it.

## Licensing

The bindings and bundled Little CMS library are MIT licensed. See
[THIRD-PARTY.md](THIRD-PARTY.md) for native provenance.
