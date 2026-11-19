package com.robatech.app.hce
import com.google.common.truth.Truth.assertThat
import org.junit.Test
class ApduTest {
    @Test
    fun parsesSelectAidWithSevenByteLength() {
        val cmd = byteArrayOf(
            0x00, 0xA4.toByte(), 0x04, 0x00, 0x07,
            0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01
        )
        val parsed = Apdu.parse(cmd)
        assertThat(parsed).isInstanceOf(Apdu.SelectAid::class.java)
        assertThat((parsed as Apdu.SelectAid).aid)
            .isEqualTo(byteArrayOf(0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01))
    }
    @Test
    fun parsesTruncatedSelectAidAsUnknown() {
        val cmd = byteArrayOf(0x00, 0xA4.toByte(), 0x04, 0x00, 0x07, 0xD2.toByte())
        assertThat(Apdu.parse(cmd)).isEqualTo(Apdu.Unknown)
    }
    @Test
    fun parsesSelectFileCapabilityContainer() {
        val cmd = byteArrayOf(0x00, 0xA4.toByte(), 0x00, 0x00, 0x02, 0xE1.toByte(), 0x03)
        val parsed = Apdu.parse(cmd)
        assertThat(parsed).isInstanceOf(Apdu.SelectFile::class.java)
        assertThat((parsed as Apdu.SelectFile).fileId)
            .isEqualTo(byteArrayOf(0xE1.toByte(), 0x03))
    }
    @Test
    fun parsesSelectFileNdef() {
        val cmd = byteArrayOf(0x00, 0xA4.toByte(), 0x00, 0x00, 0x02, 0xE1.toByte(), 0x04)
        val parsed = Apdu.parse(cmd)
        assertThat(parsed).isInstanceOf(Apdu.SelectFile::class.java)
        assertThat((parsed as Apdu.SelectFile).fileId)
            .isEqualTo(byteArrayOf(0xE1.toByte(), 0x04))
    }
    @Test
    fun parsesReadBinary() {
        val cmd = byteArrayOf(0x00, 0xB0.toByte(), 0x00, 0x02, 0x10)
        val parsed = Apdu.parse(cmd)
        assertThat(parsed).isInstanceOf(Apdu.ReadBinary::class.java)
        val rb = parsed as Apdu.ReadBinary
        assertThat(rb.offset).isEqualTo(2)
        assertThat(rb.length).isEqualTo(16)
    }
    @Test
    fun parsesReadBinaryZeroLengthReadsAsZero() {
        val cmd = byteArrayOf(0x00, 0xB0.toByte(), 0x00, 0x00)
        val parsed = Apdu.parse(cmd)
        assertThat(parsed).isInstanceOf(Apdu.ReadBinary::class.java)
        assertThat((parsed as Apdu.ReadBinary).length).isEqualTo(0)
    }
    @Test
    fun unknownInstructionYieldsUnknown() {
        val cmd = byteArrayOf(0x00, 0x99.toByte(), 0x00, 0x00, 0x00)
        assertThat(Apdu.parse(cmd)).isEqualTo(Apdu.Unknown)
    }
    @Test
    fun emptyCommandYieldsUnknown() {
        assertThat(Apdu.parse(byteArrayOf())).isEqualTo(Apdu.Unknown)
    }
}
