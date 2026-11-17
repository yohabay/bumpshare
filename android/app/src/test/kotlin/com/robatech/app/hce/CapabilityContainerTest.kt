package com.robatech.app.hce

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class CapabilityContainerTest {

    @Test
    fun bytesMatchType4Reference() {
        val expected = byteArrayOf(
            0x00, 0x0F,                       // CCLEN
            0x10,                             // mapping version 1.0
            0x00, 0x3B,                       // MLe (max read response)
            0x00, 0x34,                       // MLc (max command)
            0x04, 0x06,                       // NDEF File Control TLV (T, L)
            0xE1.toByte(), 0x04,              // NDEF file ID
            0xFF.toByte(), 0xFE.toByte(),     // max NDEF size
            0x00,                             // read access (free)
            0xFF.toByte()                     // write access (no write)
        )
        assertThat(CapabilityContainer.BYTES).isEqualTo(expected)
    }

    @Test
    fun lengthIs15Bytes() {
        assertThat(CapabilityContainer.BYTES.size).isEqualTo(15)
    }
}
