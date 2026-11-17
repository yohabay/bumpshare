package com.robatech.app

import android.content.ComponentName
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var channel: MethodChannel
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NFC_METHOD_CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isNfcAvailable" -> result.success(adapter() != null)
                "isNfcEnabled" -> result.success(adapter()?.isEnabled == true)
                "isHceSupported" -> result.success(isHceSupported())
                "openNfcSettings" -> result.success(openNfcSettings())
                "startSharing" -> result.success(startSharing(call.arguments as? String))
                "stopSharing" -> result.success(stopSharing())
                else -> result.notImplemented()
            }
        }
        NdefHceService.onTapCallback = {
            mainHandler.post {
                channel.invokeMethod("onSharingComplete", null)
            }
        }
    }

    private fun adapter(): NfcAdapter? = NfcAdapter.getDefaultAdapter(this)

    private fun isHceSupported(): Boolean =
        packageManager.hasSystemFeature(
            android.content.pm.PackageManager.FEATURE_NFC_HOST_CARD_EMULATION
        )

    private fun startSharing(uri: String?): Boolean {
        if (uri.isNullOrBlank()) return false
        val nfc = adapter() ?: return false
        if (!nfc.isEnabled || !isHceSupported()) return false
        return runCatching {
            CardEmulation.getInstance(nfc)
                .setPreferredService(this, ComponentName(this, NdefHceService::class.java))
            NdefHceService.currentUri = uri
            true
        }.getOrDefault(false)
    }

    private fun stopSharing(): Boolean = runCatching {
        adapter()?.let { CardEmulation.getInstance(it).unsetPreferredService(this) }
        NdefHceService.currentUri = null
        true
    }.getOrDefault(false)

    private fun openNfcSettings(): Boolean = runCatching {
        startActivity(Intent(Settings.ACTION_NFC_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    }.getOrDefault(false)

    override fun onDestroy() {
        NdefHceService.onTapCallback = null
        runCatching { stopSharing() }
        super.onDestroy()
    }

    companion object {
        const val NFC_METHOD_CHANNEL = "bumpshare_nfc"
    }
}
