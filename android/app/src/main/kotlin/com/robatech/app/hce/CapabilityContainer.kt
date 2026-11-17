package com.robatech.app.hce

/**
 * Capability container (CC) for the emulated NFC Forum Type 4 tag.
 *
 * Ported from the EA NFC demo. The container declares the NDEF application
 * file (E1 04) to readers implementing the Type 4 / NDEF file system profile.
 */
object CapabilityContainer {
    val BYTES: ByteArray = byteArrayOf(
        0x00, 0x0F,                       // CCLEN
        0x10,                             // mapping version 1.0 (broader device compatibility)
        0x00, 0x3B,                       // MLe (max read response)
        0x00, 0x34,                       // MLc (max command)
        0x04, 0x06,                       // NDEF File Control TLV (T, L)
        0xE1.toByte(), 0x04,              // NDEF file ID
        0xFF.toByte(), 0xFE.toByte(),     // max NDEF size
        0x00,                             // read access (free)
        0xFF.toByte()                     // write access (no write)
    )
}
