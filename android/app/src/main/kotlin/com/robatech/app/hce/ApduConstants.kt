package com.robatech.app.hce

/**
 * Protocol constants for the BumpShare NFC tag emulator.
 *
 * These mirror the APDU protocol implemented and hardware-verified in the
 * ExpressAnalytics "ea-nfc-demo" project (see docs/NFC_PROTOCOL.md):
 * an NFC Forum Type 4 tag (ISO/IEC 14443-4, Nfc-A carrier) exposing an NDEF
 * URI record through Host Card Emulation.
 */
object ApduConstants {

    /** Proprietary AID handled by the BumpShare HCE service (AID select by DF name). */
    val NDEF_AID: ByteArray = byteArrayOf(
        0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01
    )

    /** Capability container (CC) application file ID. */
    val FILE_ID_CC: ByteArray = byteArrayOf(0xE1.toByte(), 0x03)

    /** NDEF application file ID. */
    val FILE_ID_NDEF: ByteArray = byteArrayOf(0xE1.toByte(), 0x04)

    val SW_OK: ByteArray = byteArrayOf(0x90.toByte(), 0x00)
    val SW_FILE_NOT_FOUND: ByteArray = byteArrayOf(0x6A, 0x82.toByte())
    val SW_COMMAND_NOT_ALLOWED: ByteArray = byteArrayOf(0x69, 0x86.toByte())
    val SW_FUNCTION_NOT_SUPPORTED: ByteArray = byteArrayOf(0x6A, 0x81.toByte())
    val SW_WRONG_LENGTH: ByteArray = byteArrayOf(0x67, 0x00)

    /** MLe (Maximum length of the READ BINARY response) from the Type 4 capability container. */
    val CC_MLE: Int = 0x003B

    /** MLc (Maximum length of the READ BINARY command) from the Type 4 capability container. */
    val CC_MLC: Int = 0x0034

    /** Status words as Int pairs, for convenient comparisons in Kotlin. */
    val SW_OK_CODE: Int = 0x9000
    val SW_FILE_NOT_FOUND_CODE: Int = 0x6A82
    val SW_COMMAND_NOT_ALLOWED_CODE: Int = 0x6986
    val SW_FUNCTION_NOT_SUPPORTED_CODE: Int = 0x6A81
    val SW_WRONG_LENGTH_CODE: Int = 0x6700
}
