
package tn.isetbizerte.tp3_channels

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class Vibrer(context: Context) : MethodChannel.MethodCallHandler {

    // Android 12+ : VibratorManager
    // Anciennes versions : Vibrator
    private val vibrator: Vibrator =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            context.getSystemService(Vibrator::class.java)
        }

    // Motifs de vibration
    private val motifs = mapOf(
        "court" to longArrayOf(0, 100),
        "long" to longArrayOf(0, 500),
        "sos" to longArrayOf(
            0, 100, 100, 100, 100, 100,
            300, 400, 100, 400, 100, 400,
            100, 100, 100, 100, 100
        )
    )

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {

            "vibrer" -> {
                val motif = call.argument<String>("motif")
                val timings = motifs[motif]

                if (timings == null) {
                    result.error(
                        "MOTIF_INCONNU",
                        "Motif '$motif' inconnu. Choix : ${motifs.keys}",
                        null
                    )
                    return
                }

                if (!vibrator.hasVibrator()) {
                    result.error(
                        "PAS_DE_VIBREUR",
                        "Cet appareil ne peut pas vibrer",
                        null
                    )
                    return
                }

                vibrator.vibrate(
                    VibrationEffect.createWaveform(timings, -1)
                )

                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
