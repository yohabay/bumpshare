package com.robatech.app.hce

/**
 * Small Type 4 tag state machine used by Android Host Card Emulation.
 *
 * Reader flow: SELECT AID -> SELECT File (E1 04) -> READ BINARY.
 */
class Type4TagEmulator(
    private val uriProvider: () -> String?,
    private val onTapCompleted: () -> Unit = {}
) {

    private enum class Selected { NONE, CC, NDEF }

    private var selected: Selected = Selected.NONE
    private var ndefBytes: ByteArray = ByteArray(0)
    private var tapCounted: Boolean = false

    fun process(commandApdu: ByteArray): ByteArray =
        when (val parsed = Apdu.parse(commandApdu)) {
            is Apdu.SelectAid -> handleSelectAid(parsed)
            is Apdu.SelectFile -> handleSelectFile(parsed)
            is Apdu.ReadBinary -> handleReadBinary(parsed)
            Apdu.Unknown -> ApduConstants.SW_FUNCTION_NOT_SUPPORTED
        }

    fun reset() {
        selected = Selected.NONE
        ndefBytes = ByteArray(0)
        tapCounted = false
    }

    private fun handleSelectAid(cmd: Apdu.SelectAid): ByteArray =
        if (cmd.aid.contentEquals(ApduConstants.NDEF_AID)) {
            selected = Selected.NONE
            tapCounted = false
            ApduConstants.SW_OK
        } else {
            ApduConstants.SW_FILE_NOT_FOUND
        }

    private fun handleSelectFile(cmd: Apdu.SelectFile): ByteArray = when {
        cmd.fileId.contentEquals(ApduConstants.FILE_ID_CC) -> {
            selected = Selected.CC
            ApduConstants.SW_OK
        }
        cmd.fileId.contentEquals(ApduConstants.FILE_ID_NDEF) -> {
            selected = Selected.NDEF
            ndefBytes = uriProvider()?.let(NdefBuilder::buildNdefFileContent)
                ?: NdefBuilder.buildEmptyNdefFileContent()
            ApduConstants.SW_OK
        }
        else -> ApduConstants.SW_FILE_NOT_FOUND
    }

    private fun handleReadBinary(cmd: Apdu.ReadBinary): ByteArray {
        val source = when (selected) {
            Selected.CC -> CapabilityContainer.BYTES
            Selected.NDEF -> ndefBytes
            Selected.NONE -> return ApduConstants.SW_COMMAND_NOT_ALLOWED
        }
        if (cmd.offset < 0 || cmd.length < 0 || cmd.offset >= source.size) {
            return ApduConstants.SW_WRONG_LENGTH
        }
        // Le is a maximum (ISO 7816-4); clamp so OS readers issuing oversized
        // Le values still receive the whole NDEF content instead of an error.
        val available = source.size - cmd.offset
        val toRead = if (cmd.length == 0) available else minOf(cmd.length, available)
        val data = source.copyOfRange(cmd.offset, cmd.offset + toRead)
        if (selected == Selected.NDEF && cmd.offset >= 2 && !tapCounted) {
            tapCounted = true
            onTapCompleted()
        }
        return data + ApduConstants.SW_OK
    }
}
