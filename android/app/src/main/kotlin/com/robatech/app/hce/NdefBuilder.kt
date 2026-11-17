package com.robatech.app.hce

/** Builds the NDEF application file (E1 04) for a single RTD URI record. */
object NdefBuilder {

    private val URI_PREFIXES: List<Pair<Int, String>> = listOf(
        0x01 to "http://www.",
        0x02 to "https://www.",
        0x03 to "http://",
        0x04 to "https://",
        0x05 to "tel:",
        0x06 to "mailto:",
        0x07 to "ftp://anonymous:anonymous@",
        0x08 to "ftp://ftp.",
        0x09 to "ftps://",
        0x0A to "sftp://",
        0x0B to "smb://",
        0x0C to "nfs://",
        0x0D to "ftp://",
        0x0E to "dav://",
        0x0F to "news:",
        0x10 to "telnet://",
        0x11 to "imap:",
        0x12 to "rtsp://",
        0x13 to "urn:",
        0x14 to "pop:",
        0x15 to "sip:",
        0x16 to "sips://",
        0x17 to "tftp://",
        0x18 to "btspp://",
        0x19 to "btl2cap://",
        0x1A to "btgoep://",
        0x1B to "tcpobex://",
        0x1C to "irdaobex://",
        0x1D to "file://",
        0x1E to "urn:epc:id:",
        0x1F to "urn:epc:tag:",
        0x20 to "urn:epc:pat:",
        0x21 to "urn:epc:raw:",
        0x22 to "urn:epc:",
        0x23 to "urn:nfc:"
    )

    /** TNF = 0x01 (Well Known), type = 'U' (RTD URI). */
    fun buildUriRecord(uri: String): ByteArray {
        require(uri.isNotEmpty()) { "URI must not be empty" }

        val best = URI_PREFIXES
            .filter { (_, prefix) -> uri.startsWith(prefix) }
            .maxByOrNull { (_, prefix) -> prefix.length }

        val prefixCode = best?.first ?: 0x00
        val suffix = uri.substring(best?.second?.length ?: 0)
        val suffixBytes = suffix.toByteArray(Charsets.UTF_8)
        val payload = ByteArray(1 + suffixBytes.size).also {
            it[0] = prefixCode.toByte()
            System.arraycopy(suffixBytes, 0, it, 1, suffixBytes.size)
        }

        return buildRecord(tnf = 0x01, typeBytes = byteArrayOf('U'.code.toByte()), payload = payload)
    }

    fun buildNdefFileContent(uri: String): ByteArray {
        val record = buildUriRecord(uri)
        val nlen = record.size
        return byteArrayOf(
            ((nlen ushr 8) and 0xFF).toByte(),
            (nlen and 0xFF).toByte()
        ) + record
    }

    /** Valid empty NDEF file, used when no URI is armed. */
    fun buildEmptyNdefFileContent(): ByteArray = byteArrayOf(0x00, 0x00)

    private fun buildRecord(tnf: Int, typeBytes: ByteArray, payload: ByteArray): ByteArray {
        val payloadLen = payload.size
        val typeLen = typeBytes.size
        return if (payloadLen <= 0xFF) {
            // MB=1 ME=1 CF=0 SR=1 IL=0 + TNF
            val header = ByteArray(3 + typeLen).also {
                it[0] = (0xD0 or (tnf and 0x07)).toByte()
                it[1] = typeLen.toByte()
                it[2] = payloadLen.toByte()
                System.arraycopy(typeBytes, 0, it, 3, typeLen)
            }
            header + payload
        } else {
            val header = ByteArray(6 + typeLen).also {
                it[0] = (0xC0 or (tnf and 0x07)).toByte()
                it[1] = typeLen.toByte()
                it[2] = ((payloadLen ushr 24) and 0xFF).toByte()
                it[3] = ((payloadLen ushr 16) and 0xFF).toByte()
                it[4] = ((payloadLen ushr 8) and 0xFF).toByte()
                it[5] = (payloadLen and 0xFF).toByte()
                System.arraycopy(typeBytes, 0, it, 6, typeLen)
            }
            header + payload
        }
    }
}
