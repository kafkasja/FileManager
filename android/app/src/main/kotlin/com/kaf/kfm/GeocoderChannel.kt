package com.kaf.kfm

import android.content.Context
import android.location.Address
import android.location.Geocoder
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.Executors

/**
 * `com.kaf.kfm/geocoder` (TASK-C5): one place name per group centre, only when the user
 * turned on "Look up place names online". Geocoder runs in the system / Play services
 * process. Any failure answers null (offline "Place N" titles stay).
 */
class GeocoderChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "com.kaf.kfm/geocoder")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "nameFor") {
            result.notImplemented()
            return
        }
        val lat = call.argument<Double>("lat")
        val lng = call.argument<Double>("lng")
        if (lat == null || lng == null || !Geocoder.isPresent()) {
            result.success(null)
            return
        }
        val geocoder = Geocoder(context, Locale.getDefault())
        var answered = false
        val reply = { name: String? ->
            main.post {
                if (!answered) {
                    answered = true
                    result.success(name)
                }
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                geocoder.getFromLocation(lat, lng, 1, object : Geocoder.GeocodeListener {
                    override fun onGeocode(addresses: MutableList<Address>) {
                        reply(nameOf(addresses.firstOrNull()))
                    }

                    override fun onError(errorMessage: String?) {
                        Log.w(TAG, "geocode failed: $errorMessage")
                        reply(null)
                    }
                })
            } catch (e: Exception) {
                Log.w(TAG, "geocode failed: $e")
                reply(null)
            }
            return
        }
        io.execute {
            val name = try {
                @Suppress("DEPRECATION")
                nameOf(geocoder.getFromLocation(lat, lng, 1)?.firstOrNull())
            } catch (e: Exception) {
                Log.w(TAG, "geocode failed: $e")
                null
            }
            reply(name)
        }
    }

    private fun nameOf(a: Address?): String? {
        if (a == null) return null
        return listOf(a.locality, a.subAdminArea, a.adminArea, a.countryName)
            .firstOrNull { !it.isNullOrBlank() }
            ?.trim()
            ?.take(120)
    }

    companion object {
        private const val TAG = "KfmGeocoder"
    }
}
