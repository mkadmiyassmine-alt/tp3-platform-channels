
package tn.isetbizerte.tp3_channels

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import io.flutter.plugin.common.EventChannel

class CapteurProximite(context: Context) :
    EventChannel.StreamHandler, SensorEventListener {

    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    // Récupérer le capteur de proximité
    private val capteur: Sensor? =
        sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)

    private var sink: EventChannel.EventSink? = null

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        sink = events

        // Vérifier si le capteur existe
        if (capteur == null) {
            Log.e("CAPTEUR_TEST", "Capteur de proximité absent")

            events?.error(
                "PAS_DE_CAPTEUR",
                "Capteur de proximité absent sur cet appareil",
                null
            )
            sink = null
            return
        }

        Log.d(
            "CAPTEUR_TEST",
            "Capteur détecté : ${capteur.name}, portée : ${capteur.maximumRange}"
        )

        // Démarrer l'écoute du capteur
        val enregistre = sensorManager.registerListener(
            this,
            capteur,
            SensorManager.SENSOR_DELAY_NORMAL
        )

        if (!enregistre) {
            events?.error(
                "ERREUR_CAPTEUR",
                "Impossible de démarrer le capteur",
                null
            )
            sink = null
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || sink == null || capteur == null) return

        val distance = event.values[0]

        // true = proche, false = loin
        val proche = distance < capteur.maximumRange

        Log.d("CAPTEUR_TEST", "Distance : $distance, proche : $proche")

        sink?.success(proche)
    }

    override fun onAccuracyChanged(
        sensor: Sensor?,
        accuracy: Int
    ) {
    }

    override fun onCancel(arguments: Any?) {
        // Arrêter l'écoute
        sensorManager.unregisterListener(this)
        sink = null
    }
}
