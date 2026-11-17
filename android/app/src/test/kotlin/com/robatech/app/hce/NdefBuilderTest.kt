package com.robatech.app.hce

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class NdefBuilderTest {

    @Test
    fun buildUriRecordForBumpShareDemoUrl() {
        val record = NdefBuilder.buildUriRecord("https://bumpshare.vercel.app/demo")

        // Short record header: MB=1 ME=1 CF=0 SR=1 IL=0 TNF=001 -> 0xD1, typeLen=1, payloadLen, type='U'
        assertThat(record[0].toInt() and 0xFF).isEqualTo(0xD1.toInt())
        assertThat(record[1].toInt()).isEqualTo(0x01)
        assertThat(record[2].toInt()).isEqualTo(26) // 1 prefix byte + 25 suffix bytes ("bumpshare.vercel.app/demo")
        assertThat(record[3].toInt()).isEqualTo(0x55.toInt()) // 'U' = RTD_URI
        assertThat(record[4].toInt()).isEqualTo(0x04.toInt()) // prefix code: https://

        val suffix = String(record.copyOfRange(5, record.size), Charsets.UTF_8)
        assertThat(suffix).isEqualTo("bumpshare.vercel.app/demo")
        assertThat(record.size).isEqualTo(30) // 3 header + 1 type + 26 payload
    }

    @Test
    fun buildNdefFileContentPrefixesNlenAndMatchesRecord() {
        val uri = "https://bumpshare.vercel.app/demo"
        val record = NdefBuilder.buildUriRecord(uri)
        val file = NdefBuilder.buildNdefFileContent(uri)

        val nlen = ((file[0].toInt() and 0xFF) shl 8) or (file[1].toInt() and 0xFF)
        assertThat(nlen).isEqualTo(record.size)
        assertThat(file.copyOfRange(2, file.size)).isEqualTo(record)
    }

    @Test
    fun buildUriRecordPickHttpsPrefix() {
        val bytes = NdefBuilder.buildUriRecord("https://www.example.com")
        assertThat(bytes[4].toInt()).isEqualTo(0x02.toInt()) // https://www.
        assertThat(bytes[2].toInt()).isEqualTo(12) // 1 + "example.com".length
    }

    @Test
    fun buildUriRecordPickHttpPrefix() {
        val bytes = NdefBuilder.buildUriRecord("http://example.com")
        assertThat(bytes[4].toInt()).isEqualTo(0x03.toInt()) // http://
    }

    @Test
    fun buildUriRecordUnknownSchemeFallsBackToNoPrefix() {
        val bytes = NdefBuilder.buildUriRecord("custom://foo")
        assertThat(bytes[4].toInt()).isEqualTo(0x00.toInt())
    }

    @Test
    fun buildUriRecordLongPayloadUsesLongRecordHeader() {
        val longUri = "https://example.com/" + "a".repeat(300)
        val bytes = NdefBuilder.buildUriRecord(longUri)
        assertThat(bytes[0].toInt() and 0x07).isEqualTo(0x01) // TNF = well-known
        assertThat(bytes[0].toInt() and 0xFF).isEqualTo(0xC1.toInt()) // long record: SR=0
        val payloadLen = ((bytes[2].toInt() and 0xFF) shl 24) or
            ((bytes[3].toInt() and 0xFF) shl 16) or
            ((bytes[4].toInt() and 0xFF) shl 8) or
            (bytes[5].toInt() and 0xFF)
        val expectedPayload = 1 + (longUri.length - "https://".length)
        assertThat(payloadLen).isEqualTo(expectedPayload)
    }

    @Test(expected = IllegalArgumentException::class)
    fun buildUriRecordEmptyUriThrows() {
        NdefBuilder.buildUriRecord("")
    }
}
