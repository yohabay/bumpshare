package com.robatech.app.hce
/**
 * Minimal ISO 7816-4 APDU parser used by the BumpShare tag emulator and reader.
 *
 * Understood commands (mirrors the protocol implemented in the EA NFC demo):
 *  - CLA=0x00, INS=0xA4, P1=0x04 -> SELECT AID
 *  - CLA=0x00, INS=0xA4, P1=0x00 -> SELECT File (by file ID)
 *  - CLA=0x00, INS=0xB0          -> READ BINARY (P1/P2 = offset, byte 4 = length/Le)
 */
sealed class Apdu {
    data class SelectAid(val aid: ByteArray) : Apdu() {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            return other is SelectAid && aid.contentEquals(other.aid)
        }
        override fun hashCode(): Int = aid.contentHashCode()
    }
    data class SelectFile(val fileId: ByteArray) : Apdu() {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            return other is SelectFile && fileId.contentEquals(other.fileId)
        }
        override fun hashCode(): Int = fileId.contentHashCode()
    }
    data class ReadBinary(val offset: Int, val length: Int) : Apdu()
    data object Unknown : Apdu()
    companion object {
        fun parse(cmd: ByteArray): Apdu {
            if (cmd.size < 4) return Unknown
            val cla = cmd[0].toInt() and 0xFF
            val ins = cmd[1].toInt() and 0xFF
            val p1 = cmd[2].toInt() and 0xFF
            val p2 = cmd[3].toInt() and 0xFF
            return when {
                cla == 0x00 && ins == 0xA4 && p1 == 0x04 -> {
                    if (cmd.size < 5) return Unknown
                    val lc = cmd[4].toInt() and 0xFF
                    if (cmd.size < 5 + lc) return Unknown
                    SelectAid(cmd.copyOfRange(5, 5 + lc))
                }
                cla == 0x00 && ins == 0xA4 && p1 == 0x00 -> {
                    if (cmd.size < 5) return Unknown
                    val lc = cmd[4].toInt() and 0xFF
                    if (cmd.size < 5 + lc) return Unknown
                    SelectFile(cmd.copyOfRange(5, 5 + lc))
                }
                cla == 0x00 && ins == 0xB0 -> {
                    val offset = (p1 shl 8) or p2
                    val length = if (cmd.size >= 5) cmd[4].toInt() and 0xFF else 0
                    ReadBinary(offset, length)
                }
                else -> Unknown
            }
        }
    }
}
