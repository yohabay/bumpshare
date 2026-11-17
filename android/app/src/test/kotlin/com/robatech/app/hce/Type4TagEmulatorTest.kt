package com.robatech.app.hce

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class Type4TagEmulatorTest {

    private fun emulator(uri: String = URI, onTap: () -> Unit = {}) =
        Type4TagEmulator(uriProvider = { uri }, onTapCompleted = onTap)

    private fun ByteArray.statusWord(): Int =
        (this[size - 2].toInt() and 0xFF shl 8) or (this[size - 1].toInt() and 0xFF)

    private fun ByteArray.body(): ByteArray = copyOfRange(0, size - 2)

    private val SELECT_AID = byteArrayOf(
        0x00, 0xA4.toByte(), 0x04, 0x00, 0x07,
        0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01
    )
    private val SELECT_NDEF = byteArrayOf(0x00, 0xA4.toByte(), 0x00, 0x00, 0x02, 0xE1.toByte(), 0x04)

    private fun readBinary(offset: Int, length: Int) = byteArrayOf(
        0x00, 0xB0.toByte(),
        ((offset shr 8) and 0xFF).toByte(),
        (offset and 0xFF).toByte(),
        length.toByte()
    )

    @Test
    fun servesTheArmedProfileUriAsAnNdefUriRecord() {
        val e = emulator()

        assertThat(e.process(SELECT_AID).statusWord()).isEqualTo(0x9000)
        assertThat(e.process(SELECT_NDEF).statusWord()).isEqualTo(0x9000)

        val nlenResp = e.process(readBinary(0, 2))
        assertThat(nlenResp.statusWord()).isEqualTo(0x9000)
        val nlen = (nlenResp[0].toInt() and 0xFF shl 8) or (nlenResp[1].toInt() and 0xFF)

        val bodyResp = e.process(readBinary(2, nlen))
        assertThat(bodyResp.statusWord()).isEqualTo(0x9000)
        assertThat(bodyResp.body()).isEqualTo(NdefBuilder.buildUriRecord(URI))
    }

    @Test
    fun noArmedUriServesAnEmptyNdefFile() {
        val e = Type4TagEmulator(uriProvider = { null })
        e.process(SELECT_AID)
        e.process(SELECT_NDEF)
        assertThat(e.process(readBinary(0, 2)).body()).isEqualTo(byteArrayOf(0, 0))
    }

    @Test
    fun readBeforeAnySelect_returnsCommandNotAllowed() {
        assertThat(emulator().process(readBinary(0, 2)).statusWord()).isNotEqualTo(0x9000)
    }

    @Test
    fun oversizedLe_isClampedToAvailableContent() {
        val e = emulator()
        e.process(SELECT_AID)
        e.process(SELECT_NDEF)
        val resp = e.process(readBinary(0, 128))
        assertThat(resp.statusWord()).isEqualTo(0x9000)
        val nlen = (resp[0].toInt() and 0xFF shl 8) or (resp[1].toInt() and 0xFF)
        assertThat(resp.body().size).isEqualTo(2 + nlen)
    }

    @Test
    fun readAtOffsetBeyondContent_returnsWrongLength() {
        val e = emulator()
        e.process(SELECT_AID)
        e.process(SELECT_NDEF)
        assertThat(e.process(readBinary(1000, 2)).statusWord())
            .isEqualTo(ApduConstants.SW_WRONG_LENGTH_CODE)
    }

    @Test
    fun selectUnknownAid_returnsFileNotFound() {
        val cmd = byteArrayOf(
            0x00, 0xA4.toByte(), 0x04, 0x00, 0x07,
            0x12, 0x34, 0x56, 0x78, 0x9A.toByte(), 0xBC.toByte(), 0xDE.toByte()
        )
        assertThat(emulator().process(cmd).statusWord()).isNotEqualTo(0x9000)
    }

    @Test
    fun reset_clearsSelectionState() {
        val e = emulator()
        e.process(SELECT_AID)
        e.process(SELECT_NDEF)
        e.reset()
        assertThat(e.process(readBinary(0, 2)).statusWord()).isNotEqualTo(0x9000)
    }

    @Test
    fun successfulNdefRead_invokesOnTapCompleted_once() {
        var taps = 0
        val e = emulator(onTap = { taps += 1 })
        e.process(SELECT_AID)
        e.process(SELECT_NDEF)
        e.process(readBinary(0, 2))
        e.process(readBinary(2, NdefBuilder.buildUriRecord(URI).size))
        e.process(readBinary(2, NdefBuilder.buildUriRecord(URI).size))
        assertThat(taps).isEqualTo(1)
    }

    private companion object {
        const val URI = "https://yohabay.github.io/bumpshare/p/demo"
    }
}
