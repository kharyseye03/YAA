# Guide : Intégration de Google Maps API pour une application de livraison

---

## Pourquoi Google Maps ?

Pour une application de livraison, **Google Maps est la solution recommandée** pour les raisons suivantes :

| Critère | Google Maps | Mapbox | OpenStreetMap |
|---|---|---|---|
| Couverture Afrique de l'Ouest | ✅ Excellente | ✅ Bonne | ⚠️ Partielle |
| Autocomplétion d'adresses | ✅ | ✅ | ⚠️ Limitée |
| Précision des données | ✅ Très haute | ✅ Haute | ⚠️ Variable |
| Facilité d'intégration Flutter | ✅ | ✅ | ⚠️ |
| Fiabilité | ✅ Maximale | ✅ | ⚠️ |

Google Maps est utilisé par Uber, Bolt, Glovo, et la quasi-totalité des applications de livraison dans le monde.

---

## APIs Google Maps nécessaires pour une app de livraison

Voici les 5 APIs à activer sur votre projet :

| API | Utilité dans l'app |
|---|---|
| **Maps SDK for Android** | Afficher la carte dans l'application Android |
| **Maps SDK for iOS** | Afficher la carte dans l'application iOS |
| **Places API** | Autocomplétion lors de la saisie d'une adresse |
| **Geocoding API** | Convertir une adresse en coordonnées GPS (et inversement) |
| **Directions API** | Calculer l'itinéraire entre le livreur et le client |
| **Distance Matrix API** | Estimer le temps et la distance de livraison |

---

## Étape 1 — Créer un compte Google Cloud

### 1.1 Aller sur Google Cloud Console

Rendez-vous sur : **https://console.cloud.google.com**

Connectez-vous avec un compte Gmail professionnel (de préférence un compte lié à l'entreprise, pas un compte personnel).

> ⚠️ **Important :** Utilisez un compte Google que vous contrôlerez durablement. Si le titulaire du compte quitte l'entreprise, l'accès aux APIs pourrait être compromis.

### 1.2 Accepter les conditions d'utilisation

Lors de la première connexion, Google vous demandera d'accepter ses conditions d'utilisation. Cochez et cliquez sur **"Accepter"**.

---

## Étape 2 — Configurer la facturation (Billing)

> ⚠️ **Google Maps API n'est pas gratuite**, mais Google offre un crédit mensuel de **200 $ USD** qui couvre largement les besoins d'une application en phase de développement et de démarrage.

### 2.1 Créer un compte de facturation

1. Dans le menu de gauche, allez dans **"Facturation"** (Billing)
2. Cliquez sur **"Créer un compte de facturation"**
3. Renseignez :
   - Nom du compte (ex : *YAA Delivery*)
   - Pays : **Sénégal** (ou votre pays)
   - Mode de paiement : carte bancaire internationale (Visa/Mastercard)

> 💡 **Note :** Google ne débite pas immédiatement. Le crédit gratuit de 200 $/mois est déduit en premier. Vous ne payez que si vous dépassez ce crédit.

### 2.2 Estimer vos coûts

Voici les tarifs approximatifs (après le crédit de 200 $/mois) :

| API | Prix | Gratuit jusqu'à |
|---|---|---|
| Maps SDK (affichage carte) | 7 $ / 1 000 chargements | ~28 500 chargements/mois |
| Places Autocomplete | 2,83 $ / 1 000 requêtes | ~70 700 requêtes/mois |
| Geocoding | 5 $ / 1 000 requêtes | ~40 000 requêtes/mois |
| Directions | 5 $ / 1 000 requêtes | ~40 000 requêtes/mois |

Pour une application en démarrage (< 10 000 utilisateurs actifs/mois), **le crédit gratuit de 200 $ couvre généralement l'intégralité des coûts**.

---

## Étape 3 — Créer un projet Google Cloud

1. En haut de la console, cliquez sur le sélecteur de projet (à côté du logo Google Cloud)
2. Cliquez sur **"Nouveau projet"**
3. Renseignez :
   - **Nom du projet** : `YAA-Delivery` (ou le nom de votre application)
   - **Organisation** : laissez vide si vous n'en avez pas
4. Cliquez sur **"Créer"**
5. Attendez quelques secondes, puis **sélectionnez ce projet** dans le sélecteur en haut

> 💡 Associez ensuite ce projet à votre compte de facturation :
> Facturation → Mes projets → Trouver votre projet → Actions → Changer la facturation

---

## Étape 4 — Activer les APIs

### 4.1 Aller dans la bibliothèque d'APIs

1. Menu de gauche → **"APIs et services"** → **"Bibliothèque"**

### 4.2 Activer chaque API une par une

Recherchez et activez les APIs suivantes en cliquant sur chacune puis sur **"Activer"** :

- [ ] `Maps SDK for Android`
- [ ] `Maps SDK for iOS`
- [ ] `Places API`
- [ ] `Geocoding API`
- [ ] `Directions API`
- [ ] `Distance Matrix API`

---

## Étape 5 — Créer les clés API

### 5.1 Créer une clé pour Android

1. Menu de gauche → **"APIs et services"** → **"Identifiants"**
2. Cliquez sur **"+ Créer des identifiants"** → **"Clé API"**
3. Une clé est générée (ex : `AIzaSyXXXXXXXXXXXXXXXXXXXXX`)
4. Cliquez sur **"Modifier la clé"** (icône crayon)
5. Renommez-la : `YAA Android Key`
6. Sous **"Restrictions d'application"**, sélectionnez **"Applications Android"**
7. Ajoutez votre application Android :
   - **Nom du package** : vous devrez le demander à votre développeur (ex : `com.yaa.delivery`)
   - **Empreinte SHA-1** : votre développeur peut la générer avec la commande `keytool`
8. Sous **"Restrictions d'API"**, sélectionnez **"Limiter la clé"** et cochez :
   - Maps SDK for Android
   - Places API
   - Geocoding API
   - Directions API
   - Distance Matrix API
9. Cliquez sur **"Enregistrer"**

### 5.2 Créer une clé pour iOS

Répétez la même procédure avec ces paramètres différents :
- Renommez-la : `YAA iOS Key`
- Sous **"Restrictions d'application"**, sélectionnez **"Applications iOS"**
- **Bundle ID** : à demander à votre développeur (ex : `com.yaa.delivery`)

### 5.3 (Optionnel) Clé pour le backend/serveur

Si votre serveur fait des appels aux APIs (Geocoding, Distance Matrix) :
- Renommez-la : `YAA Server Key`
- Sous **"Restrictions d'application"**, sélectionnez **"Adresses IP"**
- Ajoutez l'adresse IP de votre serveur

---

## Étape 6 — Sécuriser les clés API

> ⚠️ **Ne partagez jamais vos clés API publiquement** (ne les mettez pas sur GitHub, ne les envoyez pas par email en clair).

### Bonnes pratiques :

- **Toujours restreindre** les clés (par application ou par IP) — fait à l'étape 5
- Transmettez les clés à votre développeur via un **canal sécurisé** (gestionnaire de mots de passe, message chiffré)
- En cas de suspicion de fuite : retournez sur la console → Identifiants → **Regénérer la clé**
- Activez les **alertes de budget** pour être notifié si les coûts dépassent un seuil

### Configurer une alerte de budget :

1. Menu → **"Facturation"** → **"Budgets et alertes"**
2. Cliquez sur **"Créer un budget"**
3. Définissez un montant (ex : 50 $) et votre email
4. Google vous alertera si vos coûts approchent ce seuil

---

## Étape 7 — Transmettre les informations au développeur

Une fois toutes les étapes terminées, transmettez à votre développeur de façon sécurisée :

```
Clé Android : AIzaSy...
Clé iOS     : AIzaSy...
Clé Serveur : AIzaSy... (si applicable)
```

> Le développeur les intégrera dans les fichiers de configuration de l'application. Ces clés ne doivent **jamais** apparaître dans le code source versionné (Git).

---

## Récapitulatif des étapes

```
1. Créer un compte sur console.cloud.google.com
2. Configurer la facturation (carte bancaire)
3. Créer un projet "YAA-Delivery"
4. Activer les 6 APIs listées
5. Créer 2 clés API (Android + iOS)
6. Restreindre chaque clé à son application
7. Configurer une alerte de budget
8. Transmettre les clés au développeur de façon sécurisée
```

---

## Support

En cas de problème lors de la configuration :
- Documentation officielle : https://developers.google.com/maps/documentation
- Support Google Cloud : https://cloud.google.com/support

*Document préparé pour le projet YAA Delivery*
