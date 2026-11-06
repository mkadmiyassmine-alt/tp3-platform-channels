
import 'package:flutter/services.dart';

class CanauxNatifs {
  // Étape 1 : informations appareil
  static const MethodChannel _infos =
      MethodChannel('appareil/infos');

  static Future<Map<String, dynamic>> lireInfos() async {
    final r = await _infos.invokeMapMethod<String, dynamic>('lire');
    return r ?? {};
  }

  // Étape 2 : vibration
  static const MethodChannel _vibration =
      MethodChannel('appareil/vibrer');

  static Future<void> vibrer(String motif) async {
    await _vibration.invokeMethod('vibrer', {
      'motif': motif,
    });
  }

  // Exercice 2 : lampe torche
  static const MethodChannel _torche =
      MethodChannel('appareil/torche');

  static Future<void> allumerTorche(bool etat) async {
    await _torche.invokeMethod('allumer', {
      'etat': etat,
    });
  }

  // Étape 3 : capteur de lumière
  static const EventChannel _lumiere =
      EventChannel('capteur/lumiere');

  static Stream<double> lumiere() {
    return _lumiere
        .receiveBroadcastStream()
        .map((v) => (v as num).toDouble());
  }

  // Exercice 1 : capteur de proximité
  static const EventChannel _proximite =
      EventChannel('capteur/proximite');

  static Stream<bool> proximite() {
    return _proximite
        .receiveBroadcastStream()
        .map((valeur) => valeur as bool);
  }

  // Étape 4 : permission microphone
  static const MethodChannel _permission =
      MethodChannel('audio/permission');

  static Future<bool> demanderPermissionMicro() async {
    final resultat =
        await _permission.invokeMethod<bool>('demander');

    return resultat ?? false;
  }

  // Étape 4 : flux du niveau sonore
  static const EventChannel _audio =
      EventChannel('audio/niveau');

  static Stream<double> niveauSonore() {
    return _audio
        .receiveBroadcastStream()
        .map((v) => (v as num).toDouble());
  }
}
