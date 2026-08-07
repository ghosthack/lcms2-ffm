package io.github.ghosthack.lcms2ffm;

import io.github.ghosthack.lcms2ffm.lcms2.Lcms2;
import org.junit.jupiter.api.Test;

import java.lang.foreign.Arena;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.ValueLayout;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

/** End-to-end proof that the bundled native loads and performs a color transform. */
class Lcms2SmokeTest {

    @Test
    void bundledNativeReportsExpectedVersion() {
        assertEquals(2190, Lcms2.cmsGetEncodedCMMversion());
        assertEquals(2190, Lcms2.LCMS_VERSION());
    }

    @Test
    void createsProfilesAndTransformsRgbPixels() {
        MemorySegment inputProfile = Lcms2.cmsCreate_sRGBProfile();
        MemorySegment outputProfile = Lcms2.cmsCreate_sRGBProfile();
        assertNotEquals(MemorySegment.NULL, inputProfile);
        assertNotEquals(MemorySegment.NULL, outputProfile);
        try {
            MemorySegment transform = Lcms2.cmsCreateTransform(inputProfile, Lcms2.TYPE_RGB_8(),
                    outputProfile, Lcms2.TYPE_RGB_8(), Lcms2.INTENT_RELATIVE_COLORIMETRIC(), 0);
            assertNotEquals(MemorySegment.NULL, transform);
            try (Arena arena = Arena.ofConfined()) {
                MemorySegment input = arena.allocateFrom(ValueLayout.JAVA_BYTE,
                        (byte) 0x12, (byte) 0x80, (byte) 0xf0,
                        (byte) 0xff, (byte) 0x00, (byte) 0x40);
                MemorySegment output = arena.allocate(6);
                Lcms2.cmsDoTransform(transform, input, output, 2);
                assertEquals(input.get(ValueLayout.JAVA_BYTE, 0), output.get(ValueLayout.JAVA_BYTE, 0));
                assertEquals(input.get(ValueLayout.JAVA_BYTE, 1), output.get(ValueLayout.JAVA_BYTE, 1));
                assertEquals(input.get(ValueLayout.JAVA_BYTE, 2), output.get(ValueLayout.JAVA_BYTE, 2));
                assertEquals(input.get(ValueLayout.JAVA_BYTE, 3), output.get(ValueLayout.JAVA_BYTE, 3));
                assertEquals(input.get(ValueLayout.JAVA_BYTE, 4), output.get(ValueLayout.JAVA_BYTE, 4));
                assertEquals(input.get(ValueLayout.JAVA_BYTE, 5), output.get(ValueLayout.JAVA_BYTE, 5));
            } finally {
                Lcms2.cmsDeleteTransform(transform);
            }
        } finally {
            Lcms2.cmsCloseProfile(outputProfile);
            Lcms2.cmsCloseProfile(inputProfile);
        }
    }
}

