# Notifications push YAA — spécification backend

Document destiné au développeur backend. Côté mobile, l'app est une
application Flutter publiée sous l'identifiant `gn.yaa.client`.

Le service utilisé est **Firebase Cloud Messaging (FCM)**. Il est
gratuit et sans quota pour ce volume.

---

## 1. Ce que tu reçois

- un fichier **JSON de compte de service** Firebase (à garder hors du
  dépôt Git, dans un gestionnaire de secrets ou une variable
  d'environnement) ;
- l'**ID du projet** Firebase.

⚠️ **Utiliser l'API HTTP v1**, pas l'ancienne API `legacy` à clé
serveur (`https://fcm.googleapis.com/fcm/send`) : Google l'a arrêtée.
Les tutoriels qui parlent d'une « Server Key » sont périmés.

---

## 2. Enregistrement des appareils

Chaque installation de l'app possède un **jeton FCM**. L'app l'envoie
après connexion, et à chaque fois que Firebase le renouvelle.

### `POST /api/v1/appareils` — authentifié

```json
{
  "token": "fK3nR9...",          // jeton FCM, ~160 caractères
  "plateforme": "ANDROID"        // ANDROID | IOS
}
```

Réponse : `204 No Content`.

Règles importantes :

- **Idempotent.** L'app peut renvoyer le même jeton plusieurs fois ;
  cela ne doit pas créer de doublon.
- **Un utilisateur peut avoir plusieurs appareils** (téléphone +
  tablette) : un envoi doit atteindre tous ses jetons.
- **Un jeton n'appartient qu'à un seul utilisateur à la fois.** Si un
  jeton déjà connu est enregistré par un autre compte — téléphone
  partagé, revendu —, il faut le **réaffecter**, pas le dupliquer.
  Sinon la nouvelle personne reçoit les notifications de l'ancienne.
- Stocker la date de dernière mise à jour : elle sert au ménage.

### `DELETE /api/v1/appareils/{token}` — authentifié

Appelé par l'app **à la déconnexion** et avant une suppression de
compte. Réponse `204`, y compris si le jeton n'existe pas.

---

## 3. Envoi d'une notification

`POST https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send`

Authentification : jeton OAuth2 obtenu à partir du compte de service,
avec le scope `https://www.googleapis.com/auth/firebase.messaging`.
Les bibliothèques Google (Java, Node, Python, PHP) le font pour toi —
inutile de signer le JWT à la main.

### Format attendu

```json
{
  "message": {
    "token": "fK3nR9...",
    "notification": {
      "title": "Commande confirmée",
      "body": "Votre commande #1042 a bien été confirmée."
    },
    "data": {
      "type": "COMMANDE_CONFIRMEE",
      "commandeId": "1042"
    },
    "android": {
      "priority": "high",
      "notification": { "channel_id": "yaa_commandes" }
    },
    "apns": {
      "payload": { "aps": { "sound": "default" } }
    }
  }
}
```

**Le bloc `data` n'est pas décoratif** : c'est lui qui permet à l'app
d'ouvrir le bon écran quand l'utilisateur touche la notification.
Toujours envoyer un `type`, et l'identifiant concerné. Toutes les
valeurs de `data` doivent être des **chaînes de caractères** — FCM
refuse les nombres et les booléens.

`channel_id` doit valoir exactement **`yaa_commandes`** : c'est le
canal déclaré côté application.

---

## 4. Événements à notifier

Types à utiliser dans `data.type`, à faire évoluer ensemble si besoin :

| `type` | Quand | Titre / corps suggérés |
|---|---|---|
| `COMMANDE_CONFIRMEE` | la structure accepte la commande | « Commande confirmée » / « Votre commande #1042 a bien été confirmée. » |
| `COURSIER_ASSIGNE` | un coursier prend la course | « Un coursier a été assigné » / « {prénom} arrive bientôt récupérer votre commande. » |
| `EN_LIVRAISON` | le coursier est en route | « En cours de livraison » / « Votre livreur est en route. » |
| `LIVREE` | livraison terminée | « Commande livrée » / « Votre commande #1042 a bien été livrée. » |
| `ANNULEE` | annulation, quelle qu'en soit l'origine | « Commande annulée » / préciser le motif |

Champs `data` attendus selon le cas : `commandeId` pour une commande,
`courseId` pour une livraison simple.

**Ne pas notifier ce que l'utilisateur vient de faire lui-même.** Une
notification « commande créée » arrivant deux secondes après le clic
sur « Commander » est perçue comme un bug.

---

## 5. Ménage des jetons

FCM répond en erreur pour un jeton devenu invalide — app désinstallée,
données effacées :

| Réponse FCM | Signification | Action |
|---|---|---|
| `404 UNREGISTERED` | jeton mort | **supprimer** le jeton en base |
| `400 INVALID_ARGUMENT` | jeton malformé | **supprimer** le jeton |
| `429`, `503` | quota ou panne passagère | réessayer en différé, backoff exponentiel |
| `401`, `403` | authentification | vérifier le compte de service, ne pas réessayer en boucle |

Sans ce ménage, la base se remplit de jetons morts et chaque envoi
devient plus lent.

L'envoi doit être **asynchrone** : jamais dans la transaction qui
change l'état de la commande. Si FCM est lent, la commande ne doit pas
l'être.

---

## 6. Historique des notifications (second temps)

L'app a un écran « Notifications », aujourd'hui vide. Une push ne se
stocke nulle part : pour que l'utilisateur retrouve ce qu'il a reçu,
il faut un endpoint dédié.

### `GET /api/v1/notifications` — authentifié

```json
[
  {
    "id": 87,
    "type": "COMMANDE_CONFIRMEE",
    "titre": "Commande confirmée",
    "message": "Votre commande #1042 a bien été confirmée.",
    "commandeId": 1042,
    "lu": false,
    "creeLe": "2026-10-08T14:32:11Z"
  }
]
```

Plus un `POST /api/v1/notifications/{id}/lu` pour marquer comme lue.

Idéalement, la ligne est écrite en base **au même endroit** que l'envoi
de la push : même événement, deux sorties. Cette partie peut venir
après, les notifications fonctionnent sans elle.

---

## 7. Comment tester sans l'app

Firebase permet d'envoyer une notification de test depuis sa console,
à un jeton donné. Côté backend, une fois le premier jeton en base, un
simple appel `curl` avec un jeton OAuth2 valide suffit pour vérifier
toute la chaîne — avant même que l'app soit prête.
