# Formulaire Google — Demande de suppression de compte YAA

Texte prêt à coller dans un formulaire Google. L'URL publique du
formulaire va ensuite dans la Play Console, sous **Contenu de
l'application → Suppression des données**.

Les formulations reprennent celles de l'écran de suppression dans
l'app (`lib/features/screens/profile/suppression_compte_sheet.dart`) :
les deux doivent dire la même chose, c'est ce que le vérificateur
compare.

---

## Titre du formulaire

```
Supprimer mon compte YAA
```

## Description du formulaire

```
YAA — application de livraison et de courses (gn.yaa.client)

Ce formulaire permet de demander la suppression de votre compte YAA et
des données associées, sans avoir à installer l'application. Si vous
avez encore l'application, vous pouvez aussi le faire directement
depuis Profil → Supprimer mon compte.

Seront supprimés :
• Votre profil, vos coordonnées et votre adresse
• Votre historique de commandes et de courses
• Vos favoris et votre panier en cours

Les documents que la loi nous oblige à conserver, comme les pièces
comptables, sont conservés puis anonymisés.

Votre demande est traitée sous 30 jours. Une confirmation vous est
envoyée une fois la suppression effectuée.

Une question ? yaa.support@gmail.com — +224 610 781 799
```

---

## Questions

### 1. Numéro de téléphone du compte
- Type : **Réponse courte**
- Obligatoire : **oui**
- Description : `Le numéro avec lequel vous vous connectez à YAA, par exemple 622 12 34 56.`

### 2. Adresse e-mail pour la confirmation
- Type : **Réponse courte**
- Obligatoire : **non**
- Description : `Facultatif. Sans e-mail, la confirmation vous sera envoyée par SMS.`

### 3. Motif de la suppression
- Type : **Réponse courte** (ou paragraphe)
- Obligatoire : **non**
- Description : `Facultatif. Cela nous aide à améliorer le service.`

### 4. Confirmation
- Type : **Cases à cocher**, une seule option
- Obligatoire : **oui**
- Option :
```
Je comprends que la suppression est définitive et que mon historique de commandes sera perdu.
```

---

## Message de confirmation

À mettre dans **Paramètres → Présentation → Message de confirmation** :

```
Votre demande a bien été enregistrée. Votre compte et vos données
seront supprimés sous 30 jours, et vous recevrez une confirmation.

Si vous avez encore l'application installée, pensez à la désinstaller
après la suppression.

Une question ? yaa.support@gmail.com
```

---

## Réglages à vérifier avant de publier

Ce sont eux qui font accepter ou refuser le lien par Google :

- [ ] **Connexion non obligatoire.** Dans Paramètres → Réponses,
      décocher « Limiter à 1 réponse » et toute option exigeant un
      compte Google. Le vérificateur ouvre le lien sans être connecté ;
      s'il tombe sur un écran de connexion, c'est un refus.
- [ ] **Ne pas collecter les adresses e-mail automatiquement**, sauf à
      le déclarer. La question 2 suffit.
- [ ] **Formulaire publié et lien testé** en navigation privée, sur
      téléphone. C'est le seul test qui compte.
- [ ] **Notifications par e-mail activées** (onglet Réponses → menu
      ⋮ → Recevoir des notifications par e-mail), sinon les demandes
      s'accumulent sans que personne ne le voie.

## Ensuite

1. Copier l'URL publique du formulaire (bouton **Envoyer → lien**,
   version longue de préférence, pas le lien raccourci).
2. La coller dans la Play Console, **Contenu de l'application →
   Suppression des données**.
3. Vérifier que la politique de confidentialité sur yaagn.com dit la
   même chose : 30 jours, pièces comptables anonymisées. Un écart
   entre les deux est un motif de rejet à lui seul.
