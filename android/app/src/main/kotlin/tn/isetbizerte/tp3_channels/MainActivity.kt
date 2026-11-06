
package tn.isetbizerte.tp3_channels

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel

class MainActivity : FlutterActivity() {

    private val scope = MainScope()

    private var resultatPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Étape 1 : informations appareil
        MethodChannel(messenger, "appareil/infos")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "lire" -> result.success(
                        mapOf(
                            "marque" to Build.MANUFACTURER,
                            "modele" to Build.MODEL,
                            "version" to Build.VERSION.RELEASE,
                            "sdk" to Build.VERSION.SDK_INT
                        )
                    )
                    else -> result.notImplemented()
                }
            }

        // Étape 2 : vibration
        MethodChannel(messenger, "appareil/vibrer")
            .setMethodCallHandler(Vibrer(this))

        // Étape 3 : capteur de luminosité
        EventChannel(messenger, "capteur/lumiere")
            .setStreamHandler(CapteurLumiere(this))

        // Étape 4a : demander la permission du microphone
        MethodChannel(messenger, "audio/permission")
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "demander" -> {

                        if (checkSelfPermission(
                                Manifest.permission.RECORD_AUDIO
                            ) == PackageManager.PERMISSION_GRANTED
                        ) {
                            result.success(true)

                        } else {
                            resultatPermission = result

                            requestPermissions(
                                arrayOf(Manifest.permission.RECORD_AUDIO),
                                REQ_MICRO
                            )
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // Étape 4b : flux continu du niveau sonore
        EventChannel(messenger, "audio/niveau")
            .setStreamHandler(NiveauSonore(scope))
    }

    // Réponse de l'utilisateur à la demande de permission
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        )

        if (requestCode == REQ_MICRO) {

            val autorise =
                grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED

            resultatPermission?.success(autorise)
            resultatPermission = null
        }
    }

    // Arrêter les coroutines quand l'activité est détruite
    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    companion object {
        private const val REQ_MICRO = 42
    }
}
