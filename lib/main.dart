
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'native/canaux.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PageCanaux(),
    ));

class PageCanaux extends StatefulWidget {
  const PageCanaux({super.key});

  @override
  State<PageCanaux> createState() => _PageCanauxState();
}

class _PageCanauxState extends State<PageCanaux> {

  // Étape 1 : informations appareil
  String _infos = 'Appuyez sur le bouton';

  // Étape 3 : luminosité
  double? _lux;
  StreamSubscription<double>? _abonnementLumiere;

  // Étape 4 : niveau sonore
  double? _dbfs;
  StreamSubscription<double>? _abonnementAudio;

  void _message(String texte) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texte)),
    );
  }

  // ÉTAPE 1 : lire les informations appareil
  Future<void> _lireInfos() async {
    try {
      final r = await CanauxNatifs.lireInfos();

      if (!mounted) return;

      setState(() {
        _infos =
            '${r['marque']} ${r['modele']}\n'
            'Android ${r['version']} (API ${r['sdk']})';
      });
    } on PlatformException catch (e) {
      _message('Erreur : ${e.message}');
    }
  }

  // ÉTAPE 2 : vibration
  Future<void> _vibrer(String motif) async {
    try {
      await CanauxNatifs.vibrer(motif);

      _message('Vibration : $motif');
    } on PlatformException catch (e) {
      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  // ÉTAPE 3 : démarrer / arrêter le capteur de lumière
  void _basculerLumiere() {
    if (_abonnementLumiere == null) {

      _abonnementLumiere = CanauxNatifs.lumiere().listen(
        (lux) {
          if (!mounted) return;

          setState(() {
            _lux = lux;
          });
        },
        onError: (e) {
          _message(
            'Capteur : ${e is PlatformException ? e.message : e}',
          );
        },
      );

    } else {
      _abonnementLumiere!.cancel();
      _abonnementLumiere = null;

      setState(() {});
    }
  }

  // ÉTAPE 4 : démarrer le microphone
  Future<void> _demarrerAudio() async {

    if (_abonnementAudio != null) return;

    try {

      // 1. Demander la permission du microphone
      final autorise =
          await CanauxNatifs.demanderPermissionMicro();

      if (!mounted) return;

      if (!autorise) {
        _message('Permission microphone refusée');
        return;
      }

      // 2. Réinitialiser la valeur
      setState(() {
        _dbfs = null;
      });

      // 3. Écouter le flux envoyé par Kotlin
      _abonnementAudio = CanauxNatifs.niveauSonore().listen(
        (valeur) {
          if (!mounted) return;

          setState(() {
            _dbfs = valeur;
          });
        },
        onError: (e) {
          if (!mounted) return;

          setState(() {
            _abonnementAudio = null;
          });

          _message(
            'Erreur microphone : '
            '${e is PlatformException ? e.message : e}',
          );
        },
      );

    } on PlatformException catch (e) {
      _message('Erreur ${e.code} : ${e.message}');
    } catch (e) {
      _message('Erreur : $e');
    }
  }

  // ÉTAPE 4 : arrêter le microphone
  Future<void> _arreterAudio() async {

    await _abonnementAudio?.cancel();
    _abonnementAudio = null;

    if (!mounted) return;

    setState(() {});
  }

  // Libérer les ressources lorsque la page disparaît
  @override
  void dispose() {
    _abonnementLumiere?.cancel();
    _abonnementAudio?.cancel();

    super.dispose();
  }

  // Création des cartes
  Widget _carte(String titre, List<Widget> contenu) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...contenu,
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TP 3 - Platform Channels'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          // =====================================
          // ÉTAPE 1 : INFORMATIONS APPAREIL
          // =====================================

          _carte('1. Infos appareil (MethodChannel)', [
            Text(_infos),
            const SizedBox(height: 8),

            FilledButton(
              onPressed: _lireInfos,
              child: const Text('Lire les infos'),
            ),
          ]),

          const SizedBox(height: 12),

          // =====================================
          // ÉTAPE 2 : VIBRATION
          // =====================================

          _carte('2. Vibration (arguments + erreurs)', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [

                OutlinedButton(
                  onPressed: () => _vibrer('court'),
                  child: const Text('Court'),
                ),

                OutlinedButton(
                  onPressed: () => _vibrer('long'),
                  child: const Text('Long'),
                ),

                OutlinedButton(
                  onPressed: () => _vibrer('sos'),
                  child: const Text('SOS'),
                ),

                OutlinedButton(
                  onPressed: () => _vibrer('inconnu'),
                  child: const Text('Tester erreur'),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 12),

          // =====================================
          // ÉTAPE 3 : CAPTEUR DE LUMIÈRE
          // =====================================

          _carte('3. Capteur de lumière (EventChannel)', [

            Text(
              _lux == null
                  ? 'Luminosité : -- lux'
                  : 'Luminosité : ${_lux!.toStringAsFixed(0)} lux',

              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 8),

            FilledButton(
              onPressed: _basculerLumiere,

              child: Text(
                _abonnementLumiere == null
                    ? 'Démarrer'
                    : 'Arrêter',
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // =====================================
          // ÉTAPE 4 : MICROPHONE ET COROUTINE
          // =====================================

          _carte('4. Niveau sonore (EventChannel + Coroutine)', [

            Text(
              _dbfs == null
                  ? 'Niveau sonore : -- dBFS'
                  : 'Niveau sonore : '
                      '${_dbfs!.toStringAsFixed(1)} dBFS',

              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 12),

            FilledButton(
              onPressed: _abonnementAudio == null
                  ? _demarrerAudio
                  : _arreterAudio,

              child: Text(
                _abonnementAudio == null
                    ? 'Démarrer'
                    : 'Arrêter',
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
