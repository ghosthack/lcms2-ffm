package io.github.ghosthack.lcms2ffm;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.lang.foreign.Arena;
import java.lang.foreign.Linker;
import java.lang.foreign.SymbolLookup;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;

/** Resolves the Little CMS shared library used by the generated stubs. */
public final class Lcms2Libs {

    private static final Arena LIBRARY_ARENA = Arena.ofAuto();
    private static volatile SymbolLookup lookup;

    private Lcms2Libs() {}

    /**
     * Resolves from {@code lcms2ffm.libdir}/{@code LCMS2_FFM_LIBDIR}, bundled
     * platform natives, and finally already-loaded/default native libraries.
     */
    public static SymbolLookup lookup() {
        SymbolLookup current = lookup;
        if (current == null) {
            synchronized (Lcms2Libs.class) {
                current = lookup;
                if (current == null) {
                    lookup = current = resolve();
                }
            }
        }
        return current;
    }

    private static SymbolLookup resolve() {
        String override = System.getProperty("lcms2ffm.libdir", System.getenv("LCMS2_FFM_LIBDIR"));
        SymbolLookup resolved = override != null ? fromDirectory(Path.of(override)) : fromBundle();
        SymbolLookup fallback = SymbolLookup.loaderLookup().or(Linker.nativeLinker().defaultLookup());
        return resolved != null ? resolved.or(fallback) : fallback;
    }

    private static SymbolLookup fromDirectory(Path dir) {
        if (!Files.isDirectory(dir)) {
            throw new IllegalStateException("lcms2ffm.libdir does not exist: " + dir);
        }
        List<Path> libraries = new ArrayList<>();
        try (var files = Files.list(dir)) {
            files.filter(Lcms2Libs::isLcms2Library).sorted().forEach(libraries::add);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        if (libraries.isEmpty()) {
            throw new IllegalStateException("no Little CMS shared library found in " + dir);
        }
        return chain(libraries);
    }

    private static boolean isLcms2Library(Path path) {
        String name = path.getFileName().toString().toLowerCase();
        boolean shared = name.endsWith(".dylib") || name.endsWith(".dll") || name.contains(".so");
        return shared && name.contains("lcms2");
    }

    private static SymbolLookup fromBundle() {
        String classifier = classifier();
        String base = "lcms2-natives/" + classifier + "/";
        List<String> manifest = readManifest(base);
        if (manifest == null) {
            return null;
        }
        Path cacheDir = Path.of(System.getProperty("user.home"), ".cache", "lcms2-ffm",
                Version.VERSION + "-" + classifier);
        try {
            Files.createDirectories(cacheDir);
            List<Path> libraries = new ArrayList<>();
            for (String name : manifest) {
                libraries.add(extract(base + name, cacheDir.resolve(name)));
            }
            return chain(libraries);
        } catch (IOException e) {
            throw new UncheckedIOException("failed to extract bundled Little CMS native to " + cacheDir, e);
        }
    }

    private static List<String> readManifest(String base) {
        try (InputStream in = Lcms2Libs.class.getClassLoader().getResourceAsStream(base + "manifest.txt")) {
            if (in == null) {
                return null;
            }
            return new String(in.readAllBytes(), StandardCharsets.UTF_8).lines()
                    .map(String::trim).filter(line -> !line.isEmpty()).toList();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private static Path extract(String resource, Path target) throws IOException {
        try (InputStream in = Lcms2Libs.class.getClassLoader().getResourceAsStream(resource)) {
            if (in == null) {
                throw new IOException("missing classpath resource " + resource);
            }
            byte[] bytes = in.readAllBytes();
            if (Files.exists(target) && Files.size(target) == bytes.length) {
                return target;
            }
            Path temporary = Files.createTempFile(target.getParent(), target.getFileName().toString(), ".tmp");
            Files.write(temporary, bytes);
            try {
                Files.move(temporary, target, StandardCopyOption.REPLACE_EXISTING,
                        StandardCopyOption.ATOMIC_MOVE);
            } catch (java.nio.file.AtomicMoveNotSupportedException ignored) {
                Files.move(temporary, target, StandardCopyOption.REPLACE_EXISTING);
            }
            return target;
        }
    }

    private static SymbolLookup chain(List<Path> libraries) {
        SymbolLookup result = null;
        for (Path library : libraries) {
            SymbolLookup one = SymbolLookup.libraryLookup(library.toAbsolutePath().toString(), LIBRARY_ARENA);
            result = result == null ? one : result.or(one);
        }
        return result;
    }

    static String classifier() {
        String os = System.getProperty("os.name", "").toLowerCase();
        String arch = System.getProperty("os.arch", "").toLowerCase();
        String osPart = os.contains("mac") ? "macos" : os.contains("win") ? "windows" : "linux";
        String archPart = arch.equals("aarch64") || arch.equals("arm64") ? "arm64" : "x64";
        return osPart + "-" + archPart;
    }
}

