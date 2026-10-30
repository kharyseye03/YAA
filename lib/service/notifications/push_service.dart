import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/utils/journal.dart';
import '../api/api_service.dart';
import '../location/location_service.dart';
import '../permissions/file_autorisations.dart';

/// Notifications push, de bout en bout.
///
/// Trois acteurs : le backend décide qu'il se passe quelque chose,
/// Firebase achemine le message, cette classe le reçoit et l'affiche.
/// Le lien entre les trois est le **jeton** : une chaîne que Firebase
/// attribue à chaque installation et que le backend range à côté du
/// compte. Sans [enregistrerAppareil], tout le reste est inutile —
/// Firebase ne saurait à quel téléphone parler.
///
/// **Rien ici ne doit empêcher l'app de démarrer.** Une notification
/// est un confort ; une app qui ne s'ouvre plus parce que Firebase
/// n'a pas répondu, c'est un incident. D'où les `try` un peu partout
/// et [_actif], qui coupe proprement le reste quand l'initialisation
/// échoue — notamment sur iOS tant que `GoogleService-Info.plist`
/// n'est pas en place.

/// Canal Android. **Doit être identique** à la valeur déclarée dans
/// `AndroidManifest.xml` : app fermée, c'est Android qui affiche la
/// notification, en lisant le manifeste. Deux valeurs différentes
/// donnent deux canaux, dont un que l'utilisateur croit avoir coupé.
const String _canalId = 'yaa_commandes';

const AndroidNotificationChannel _canal = AndroidNotificationChannel(
  _canalId,
  'Commandes et livraisons',
  description:
      'Confirmation de commande, coursier assigné, livraison en cours.',
  importance: Importance.high,
);

/// Reçoit les messages quand l'app est fermée ou en arrière-plan.
///
/// Tourne dans un isolate séparé, sans accès à l'état de l'app : ni
/// providers, ni navigation. On ne fait donc rien ici — Android se
/// charge d'afficher la notification à partir du bloc `notification`
/// du message. Cette fonction doit exister, être de premier niveau et
/// porter l'annotation, sinon Firebase refuse de s'enregistrer.
@pragma('vm:entry-point')
Future<void> _messageEnArrierePlan(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();

  bool _actif = false;
  String? _jeton;

  /// Le serveur connaît ce jeton. Faux tant qu'il ne le connaît pas,
  /// ce qui autorise [reprendreEnregistrement] à réessayer.
  bool _enregistre = false;

  /// L'écoute du renouvellement est posée une fois pour toutes :
  /// la reposer à chaque tentative empilerait les abonnements, et le
  /// jeton partirait en plusieurs exemplaires.
  bool _ecouteRenouvellement = false;

  /// Appelé quand l'utilisateur touche une notification. Renseigné par
  /// l'application une fois le routeur construit — le service ne sait
  /// pas naviguer, il se contente de transmettre les données.
  ///
  /// L'affectation rejoue ce qui est arrivé trop tôt : [initialiser]
  /// tourne avant `runApp`, donc le message qui a réveillé une app
  /// fermée est connu avant qu'il y ait un routeur pour l'ouvrir.
  /// Sans ce rattrapage, toucher une notification sur une app fermée
  /// ouvrait l'accueil et rien d'autre.
  set onOuverture(void Function(Map<String, dynamic> donnees)? callback) {
    _onOuverture = callback;
    final enAttente = _messageEnAttente;
    if (callback != null && enAttente != null) {
      _messageEnAttente = null;
      callback(enAttente);
    }
  }

  void Function(Map<String, dynamic> donnees)? _onOuverture;
  Map<String, dynamic>? _messageEnAttente;

  // ── Démarrage ────────────────────────────────────────────────

  /// À appeler une fois au lancement, avant `runApp`.
  Future<void> initialiser() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // iOS sans GoogleService-Info.plist, ou configuration absente :
      // l'app continue sans notifications plutôt que de ne pas démarrer.
      journal('⚠️ Firebase indisponible, notifications désactivées : $e');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(_messageEnArrierePlan);
      await _preparerAffichageLocal();

      // App au premier plan : Android n'affiche rien tout seul, c'est
      // à nous de le faire. iOS sait le faire, on le lui demande.
      FirebaseMessaging.onMessage.listen(_afficherAuPremierPlan);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // App en arrière-plan, l'utilisateur touche la notification.
      FirebaseMessaging.onMessageOpenedApp.listen(_ouvrir);

      // App fermée : le message qui l'a réveillée n'arrive par aucun
      // flux, il faut aller le chercher.
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _ouvrir(initial);

      _actif = true;
    } catch (e) {
      journal('⚠️ Initialisation des notifications échouée : $e');
    }
  }

  Future<void> _preparerAffichageLocal() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
        iOS: DarwinInitializationSettings(
          // L'autorisation est demandée plus tard, au bon moment, par
          // [enregistrerAppareil] — pas au premier lancement.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (reponse) {
        final charge = reponse.payload;
        if (charge == null || charge.isEmpty) return;
        _onOuverture?.call(_decoder(charge));
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);
  }

  // ── Jeton ────────────────────────────────────────────────────

  /// Demande l'autorisation, récupère le jeton et l'envoie au backend.
  ///
  /// À appeler **après la connexion** : le backend range le jeton à
  /// côté d'un compte, il lui faut donc un utilisateur authentifié.
  /// C'est aussi le bon moment pour la demande d'autorisation —
  /// quelqu'un qui vient de se connecter comprend pourquoi on la lui
  /// demande, ce qui n'est pas le cas au tout premier lancement.
  Future<void> enregistrerAppareil() async {
    if (!_actif) return;
    try {
      // Laisser la localisation poser sa question d'abord : l'accueil
      // se monte au même instant et l'attend pour afficher l'adresse.
      // Le délai n'est qu'un garde-fou, pour le cas où cet écran ne
      // demanderait jamais rien ; la file, elle, garantit dans tous
      // les cas qu'une seule boîte de dialogue est à l'écran.
      await LocationService.autorisationTranchee
          .timeout(const Duration(seconds: 10), onTimeout: () {});

      final reglages = await FileAutorisations.enFile(
          () => FirebaseMessaging.instance.requestPermission());
      if (reglages.authorizationStatus == AuthorizationStatus.denied) {
        journal('ℹ️ Notifications refusées par l\'utilisateur');
        return;
      }

      // Sur iOS, le jeton Firebase est dérivé du jeton APNs, qu'Apple
      // délivre de façon asynchrone après l'acceptation. Demander le
      // jeton trop tôt renvoie `null` — et comme on abandonne sur
      // `null`, l'appareil n'était jamais enregistré au premier
      // lancement, celui qui compte. On laisse donc APNs répondre.
      if (Platform.isIOS && !await _attendreJetonApns()) {
        journal('⚠️ Jeton APNs indisponible, enregistrement reporté');
        return;
      }

      final jeton = await FirebaseMessaging.instance.getToken();
      if (jeton == null) return;
      await _envoyerAuBackend(jeton);

      // Firebase renouvelle le jeton de lui-même : réinstallation,
      // restauration, effacement des données. Sans cette écoute, les
      // notifications cessent d'arriver un jour, sans rien signaler.
      if (!_ecouteRenouvellement) {
        _ecouteRenouvellement = true;
        FirebaseMessaging.instance.onTokenRefresh.listen(_envoyerAuBackend);
      }
    } catch (e) {
      journal('⚠️ Enregistrement du jeton échoué : $e');
    }
  }

  /// Attend qu'Apple ait délivré le jeton APNs, au plus dix secondes.
  ///
  /// Il arrive presque toujours en moins d'une seconde ; l'attente ne
  /// se voit pas, puisqu'elle a lieu après la connexion, pendant que
  /// l'accueil se remplit. En l'absence de réseau, ou sur un
  /// simulateur, il ne vient jamais — d'où la sortie au bout du
  /// délai, qui laisse `onTokenRefresh` rattraper le coup plus tard.
  Future<bool> _attendreJetonApns() async {
    for (var essai = 0; essai < 10; essai++) {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns != null) return true;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  /// Envoie le jeton au backend, en réessayant.
  ///
  /// L'enregistrement n'a lieu qu'au démarrage ou à la connexion. S'il
  /// échoue — réseau qui flanche, backend qui redémarre —, rien ne le
  /// retentait et l'appareil restait inconnu du serveur jusqu'à la
  /// prochaine connexion, sans que personne ne s'en aperçoive. C'est
  /// exactement ce qui est arrivé le 30/10/2026 : le jeton était bon,
  /// le backend ne le connaissait pas.
  Future<void> _envoyerAuBackend(String jeton) async {
    _jeton = jeton;

    for (var essai = 1; essai <= 3; essai++) {
      try {
        await ApiService().enregistrerAppareil(
          token: jeton,
          // En minuscules : c'est la forme attendue par le backend.
          plateforme: Platform.isIOS ? 'ios' : 'android',
        );
        _enregistre = true;
        journal('✅ Jeton de notification enregistré');
        return;
      } catch (e) {
        journal('⚠️ Envoi du jeton au backend échoué (essai $essai) : $e');
        if (essai < 3) {
          await Future<void>.delayed(Duration(seconds: 2 * essai));
        }
      }
    }
    // Les trois tentatives ont échoué : [reprendreEnregistrement] le
    // retentera au prochain retour au premier plan.
    _enregistre = false;
  }

  /// Reprend l'enregistrement s'il n'a jamais abouti.
  ///
  /// À appeler au retour au premier plan. Ne fait rien dans le cas
  /// normal, où le jeton est déjà chez le serveur ; sert aux fois où
  /// l'app a démarré sans réseau, ou avant que la configuration soit
  /// complète.
  Future<void> reprendreEnregistrement() async {
    if (!_actif || _enregistre) return;
    await enregistrerAppareil();
  }

  /// À appeler **à la déconnexion**, avant d'effacer la session.
  ///
  /// Sans ça, la personne suivante à se connecter sur ce téléphone
  /// reçoit les notifications de la précédente : son numéro de
  /// commande, le nom de son livreur. Le même défaut que les favoris
  /// qui survivaient à la déconnexion, en plus visible.
  Future<void> oublierAppareil() async {
    if (!_actif) return;
    // Tout est sous `try`, y compris la lecture du jeton. Sur iOS,
    // `getToken` lève quand Apple n'a pas encore délivré son jeton
    // APNs — ce qui arrive dès que la capacité push n'est pas
    // accordée au build. L'exception remontait alors jusqu'à
    // `logout`, qui n'allait jamais jusqu'à effacer la session :
    // impossible de se déconnecter.
    try {
      final jeton = _jeton ?? await FirebaseMessaging.instance.getToken();
      if (jeton != null) await ApiService().supprimerAppareil(token: jeton);
    } catch (e) {
      journal('⚠️ Suppression du jeton côté backend échouée : $e');
    }
    try {
      // Firebase en fabriquera un neuf à la prochaine connexion.
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _jeton = null;
    _enregistre = false;
  }

  // ── Réception ────────────────────────────────────────────────

  Future<void> _afficherAuPremierPlan(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;
    await _local.show(
      id: message.hashCode,
      title: notif.title,
      body: notif.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _canal.id,
          _canal.name,
          channelDescription: _canal.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: _encoder(message.data),
    );
  }

  void _ouvrir(RemoteMessage message) {
    final rappel = _onOuverture;
    if (rappel == null) {
      // Trop tôt : le routeur n'existe pas encore. On garde le message
      // et le setter le rejouera.
      _messageEnAttente = message.data;
      return;
    }
    rappel(message.data);
  }

  // Le payload de flutter_local_notifications est une simple chaîne :
  // on y range les données sous forme `cle=valeur;cle=valeur`. Les
  // valeurs venant de FCM sont toujours des chaînes, jamais de
  // séparateur à échapper en pratique.
  String _encoder(Map<String, dynamic> donnees) =>
      donnees.entries.map((e) => '${e.key}=${e.value}').join(';');

  Map<String, dynamic> _decoder(String charge) {
    final sortie = <String, dynamic>{};
    for (final morceau in charge.split(';')) {
      final i = morceau.indexOf('=');
      if (i > 0) sortie[morceau.substring(0, i)] = morceau.substring(i + 1);
    }
    return sortie;
  }
}
