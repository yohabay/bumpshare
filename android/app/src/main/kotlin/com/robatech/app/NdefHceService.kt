package com.robatech.app
import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import com.robatech.app.hce.NdefBuilder
import com.robatech.app.hce.Type4TagEmulator
/**
 * Emulates an NFC Forum Type 4 tag containing a single NDEF URI record.
 *
 * Any modern phone reads this tag with its own NFC stack: Android opens the
 * link in the browser, iPhone shows its NFC notification. No receiver app.
 */
class NdefHceService : HostApduService() {
    private val emulator = Type4TagEmulator(
        uriProvider = { currentUri },
        onTapCompleted = { onTapCallback?.invoke() }
    )
    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray =
        emulator.process(commandApdu)
    override fun onDeactivated(reason: Int) {
        emulator.reset()
    }
    companion object {
        /** URI armed by the sender for the current sharing session. */
        @Volatile
        var currentUri: String? = null
        @Volatile
        var onTapCallback: (() -> Unit)? = null
    }
}
