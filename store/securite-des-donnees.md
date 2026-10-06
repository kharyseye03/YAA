# Questionnaire « Sécurité des données » — réponses pour YAA

Relevé de ce que l'app envoie réellement, fait le 29/09/2026 en lisant
le code (`lib/service/api/api_service.dart`, le manifeste Android et
`lib/config/maps/maps_config.dart`). À reporter dans la Play Console,
**Contenu de l'application → Sécurité des données**.

Google compare ces réponses au comportement réel de l'app. Un écart est
un motif de retrait, donc ne déclare rien « au cas où » : seulement ce
qui part vraiment.

Tout part vers `https://api.yaagn.com` et `https://auth.yaagn.com`.

---

## Les deux questions générales

| Question | Réponse | Pourquoi |
|---|---|---|
| Les données sont-elles chiffrées en transit ? | **Oui** | Tout est en HTTPS et le manifeste pose `usesCleartextTraffic="false"` : une requête en clair est refusée par le système. |
| L'utilisateur peut-il demander la suppression de ses données ? | **Oui** | Bouton dans le profil, branché sur l'API, plus le formulaire Google. |

---

## Ce qui est collecté

Pour chaque ligne : **collectée = oui**, **partagée = non** (sauf
mention), traitement sur nos serveurs.

### Informations personnelles

| Type Play | Ce que l'app envoie | Obligatoire | Finalité |
|---|---|---|---|
| Nom | `nom`, `prenom` à l'inscription et au profil | Oui | Fonctionnalité de l'app, gestion du compte |
| Adresse e-mail | `email` — inscription, connexion, OTP, mot de passe oublié | Oui | Gestion du compte |
| Numéro de téléphone | `telephone` du compte, `telephoneClient` sur commande | Oui | Fonctionnalité de l'app |
| Adresse postale | `adresse`, `adresseLivraison` | Oui | Fonctionnalité de l'app |
| ID utilisateur | identifiant de compte Keycloak | Oui | Gestion du compte |
| Autres informations | **numéros de l'expéditeur et du destinataire** d'une course | Oui | Fonctionnalité de l'app |

> La dernière ligne est celle qu'on oublie : ces numéros sont ceux de
> **tierces personnes**, qui n'ont pas installé l'app. Ils sont bien
> collectés au sens de Play. Le sélecteur de contacts ne change rien —
> l'app ne reçoit que le numéro choisi, jamais le carnet d'adresses.

### Position

| Type Play | Ce que l'app envoie | Obligatoire | Finalité |
|---|---|---|---|
| Position exacte | `latitude` / `longitude` — départ, arrivée, livraison | Oui | Fonctionnalité de l'app |
| Position approximative | idem (`ACCESS_COARSE_LOCATION` déclarée) | Oui | Fonctionnalité de l'app |

Les deux permissions sont dans le manifeste, donc déclare les deux.

### Photos et vidéos

| Type Play | Ce que l'app envoie | Obligatoire | Finalité |
|---|---|---|---|
| Photos | photo de profil, envoyée en multipart | **Non** — facultative | Fonctionnalité de l'app |

Prise depuis la galerie ou l'appareil photo, à la seule initiative de
l'utilisateur, dans la modification du profil.

### Informations financières

| Type Play | Ce que l'app envoie | Obligatoire | Finalité |
|---|---|---|---|
| Historique des achats | commandes, courses, montants | Oui | Fonctionnalité de l'app |

**Aucune donnée bancaire n'est collectée.** Le seul mode de paiement
actif est « Espèces » ; Orange Money, Wave et MTN sont affichés mais
désactivés. Ne coche ni « Informations de paiement », ni « Numéro de
carte ». À revoir le jour où le paiement mobile sera branché.

---

## Ce qui n'est PAS collecté — à laisser décoché

- Aucun outil d'analyse ni de rapport de plantage : pas de Firebase,
  pas de Crashlytics, pas de Sentry. Donc ni « Journaux de plantage »,
  ni « Diagnostics », ni « Identifiants d'appareil ».
- Aucun contact : le sélecteur passe par l'écran du système, sans
  permission `READ_CONTACTS`, et ne lit pas le carnet d'adresses.
- Aucun message, aucun fichier, aucun contenu audio.
- Les jetons de connexion restent sur le téléphone, chiffrés par le
  Keystore Android (`flutter_secure_storage`). Ils ne sont pas envoyés
  ailleurs, donc rien à déclarer.

---

## Le point à trancher : Google Maps

L'app appelle `maps.googleapis.com` (Places pour l'autocomplétion,
Directions pour l'itinéraire). Ces appels transmettent la position et
l'adresse tapée à Google.

Mon avis : déclarer la position comme **collectée** mais **non
partagée**, Google Maps Platform agissant comme prestataire technique
qui traite pour ton compte. C'est la lecture courante, mais ce n'est
pas un point sur lequel je peux t'affirmer une certitude. Si tu veux
zéro risque, coche « partagée » pour la position : Google ne reproche
jamais une déclaration plus large que la réalité, l'inverse si.

---

## Après le questionnaire

Vérifie que la politique de confidentialité sur yaagn.com mentionne au
moins : le numéro de téléphone, la position exacte, l'adresse, la photo
de profil, et les numéros des tiers (expéditeur, destinataire). Le
questionnaire et la politique doivent raconter la même histoire.
