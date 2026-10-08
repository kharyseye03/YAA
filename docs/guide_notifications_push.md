# Guide : intégrer les notifications push dans YAA

Écrit le 08/10/2026. Pour la partie backend, voir le document séparé
[`specs_notifications_backend.md`](specs_notifications_backend.md), à
transmettre au développeur backend.

---

## Ce qu'il faut comprendre avant de commencer

Une notification push, c'est **trois acteurs** :

1. **Ton backend** décide qu'il se passe quelque chose : « la commande
   1042 vient d'être confirmée ».
2. **Firebase Cloud Messaging (FCM)**, le service de Google, achemine
   le message jusqu'au téléphone. C'est gratuit, sans limite de volume
   pour un usage comme le tien.
3. **L'application** reçoit le message et l'affiche.

Pour que FCM sache à quel téléphone parler, chaque appareil possède un
**jeton** (`token`) : une longue chaîne de caractères générée par
Firebase à l'installation. L'app doit l'envoyer au backend, qui le
range à côté du compte utilisateur. Sans cette étape, rien ne marche —
c'est la pièce que les gens oublient.

**Push ≠ liste de notifications.** La push est une livraison, elle ne
se stocke nulle part. L'écran « Notifications » de YAA, aujourd'hui
vide, a besoin de son propre endpoint pour afficher un historique. Les
deux se complètent mais ne se remplacent pas.

---

## Étape 1 — Créer le projet Firebase (toi, ~20 min)

1. Va sur **https://console.firebase.google.com**, connecte-toi avec
   le **compte Google qui possède déjà le projet Cloud de YAA** — celui
   des clés Maps. Ça évite d'éparpiller les accès.
2. **Ajouter un projet** → tu peux rattacher le projet Cloud existant
   (`yaa-delivery-498912`) plutôt que d'en créer un nouveau.
3. Google Analytics : facultatif. Tu peux refuser, ça n'a aucun effet
   sur les notifications.

## Étape 2 — Déclarer l'app Android (toi, ~10 min)

1. Dans le projet Firebase : **Ajouter une application → Android**.
2. Nom du package : **`gn.yaa.client`**. Exactement celui-là, c'est
   l'identifiant de YAA sur le Play Store.
3. Empreinte SHA-1 : facultative pour les notifications. Ne t'embête
   pas maintenant.
4. Télécharge le fichier **`google-services.json`** et donne-le moi :
   il va dans `android/app/`.

> Ce fichier n'est pas un secret au sens des clés Maps — Google le
> documente comme publiable. On le versionnera dans Git, sinon le
> projet ne compilera plus sur ton Mac ni sur aucune autre machine.

## Étape 3 — Déclarer l'app iOS (toi, quand tu seras sur le Mac)

À faire seulement quand tu attaqueras l'App Store.

1. Dans Firebase : **Ajouter une application → iOS**, identifiant
   **`gn.yaa.client`**.
2. Télécharge **`GoogleService-Info.plist`** → il ira dans
   `ios/Runner/`.
3. Chez Apple, sur **developer.apple.com** → Certificates, Identifiers
   & Profiles → **Keys** → créer une clé avec le service **Apple Push
   Notifications service (APNs)** activé. Tu télécharges un fichier
   `.p8` — **une seule fois, il n'est jamais retéléchargeable.**
   Garde-le précieusement.
4. Reviens dans Firebase → Paramètres du projet → Cloud Messaging →
   section iOS → téléverse le `.p8`, avec le **Key ID** et ton **Team
   ID** (visibles sur la page Apple).

Sans cette clé APNs, les notifications fonctionnent sur Android et
reste silencieuses sur iPhone, sans message d'erreur.

## Étape 4 — Ce que je fais dans l'app (moi, ~1 journée)

- Ajouter `firebase_core`, `firebase_messaging` et
  `flutter_local_notifications`.
- Initialiser Firebase au démarrage.
- **Demander l'autorisation** : obligatoire sur iOS, et sur Android
  depuis la version 13. Au bon moment — pas au premier lancement, mais
  après la première commande, quand la notification a un sens.
- **Récupérer le jeton et l'envoyer au backend**, puis réagir à ses
  renouvellements (Firebase le change parfois tout seul).
- **Supprimer le jeton à la déconnexion**, sinon la personne suivante
  reçoit les notifications de la précédente — le même problème que les
  favoris, en plus visible.
- Gérer les trois cas de réception : app ouverte, app en arrière-plan,
  app fermée. Et router vers le bon écran quand on touche la
  notification.
- Créer le canal Android et poser l'icône de notification.

## Étape 5 — Ce que fait le backend (ton dev, ~1 à 2 jours)

Tout est détaillé dans `specs_notifications_backend.md`. En résumé :
stocker les jetons, et appeler l'API FCM à chaque changement d'état
d'une commande.

---

## Ce que tu dois donner à ton dev backend

Deux choses, et seulement deux :

| Quoi | Où le prendre |
|---|---|
| Le **fichier de compte de service** (JSON) | Firebase → ⚙️ Paramètres du projet → **Comptes de service** → « Générer une nouvelle clé privée » |
| L'**identifiant du projet** Firebase | Même page, en haut (`yaa-delivery-498912`) |

⚠️ **Ce fichier JSON est un vrai secret** : il permet d'envoyer des
notifications à tous tes utilisateurs. Transmets-le par un canal privé,
jamais par WhatsApp ni par e-mail, et qu'il ne soit **jamais** commité
dans un dépôt Git.

Précise-lui aussi d'utiliser l'**API HTTP v1**. L'ancienne API avec une
simple « clé serveur » a été arrêtée par Google : s'il suit un vieux
tutoriel, il perdra une journée.

---

## Dans quel ordre

1. Toi : étapes 1 et 2, puis tu me donnes `google-services.json`.
2. Toi : tu envoies le JSON de compte de service et la spec au dev
   backend. Il peut commencer immédiatement, en parallèle.
3. Moi : le côté application.
4. Ensemble : on teste avec un vrai téléphone. Firebase permet
   d'envoyer une notification de test depuis sa console, sans attendre
   que le backend soit prêt — c'est comme ça qu'on validera l'app
   seule.
5. Le dev branche ses événements, et on teste le parcours complet.

L'étape iOS (3) peut se faire plus tard, elle n'empêche rien sur
Android.
