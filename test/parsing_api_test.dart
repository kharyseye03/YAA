import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaa/model/category/structure.dart';
import 'package:yaa/model/order/livraison_course_model.dart';
import 'package:yaa/model/user/user_profile.dart';

/// Ce que l'application fait des réponses du serveur.
///
/// **Pourquoi ces tests plutôt que d'autres.** C'est ici que l'app
/// casse en production. Un débordement de mise en page est laid mais
/// inoffensif : en release, Flutter rogne sans planter. Un champ qui
/// change de nom, disparaît, ou revient nul là où on l'attendait plein
/// produit une exception, un écran vide, une commande impossible.
///
/// Les charges utiles ci-dessous sont **de vraies réponses** de
/// api.yaagn.com, pas des exemples inventés — y compris leurs
/// bizarreries : le `"VEHICLE"` mal orthographié, les champs nuls que
/// le backend n'a pas encore remplis.
void main() {
  group('Livreur — la fiche du coursier', () {
    test('réponse complète de /livraisons-courses/client', () {
      final livreur = Livreur.fromJson(json.decode('''
        {
          "id": 14,
          "fullName": "Momar Diagne",
          "telephone": "706494085",
          "imageFileName": "c68f09ce-15f7-4dd4-998c-48051a91c67a.jpg",
          "latitude": 14.7166767,
          "longitude": -17.467685,
          "vehicule": "VEHICLE",
          "noteMoyenne": 3.888888888888889,
          "vehiculeCoursier": {
            "marque": "Toyota",
            "immatriculation": "DK543AA",
            "couleur": "Noir"
          }
        }
      '''));

      expect(livreur.fullName, 'Momar Diagne');
      expect(livreur.hasPosition, isTrue);
      expect(livreur.vehiculeCoursier?.immatriculation, 'DK543AA');
      expect(livreur.initiales, 'MD');
    });

    test('coursier sans véhicule ni position — ne lève pas', () {
      // Cas observé pendant la recette : le backend renvoyait le
      // coursier avant d'avoir ses coordonnées.
      final livreur = Livreur.fromJson(json.decode('''
        {"id": 3, "fullName": "Awa Ba", "telephone": null,
         "latitude": null, "longitude": null, "vehiculeCoursier": null}
      '''));

      expect(livreur.hasPosition, isFalse);
      expect(livreur.vehiculeCoursier, isNull);
      expect(livreur.photoUrl, isNull);
    });

    test('objet vide — aucun champ requis ne fait planter', () {
      // Le contrat le plus important : si le backend renvoie {} un
      // jour, l'app doit dégrader, pas mourir.
      final livreur = Livreur.fromJson(<String, dynamic>{});
      expect(livreur.fullName, '');
      expect(livreur.hasPosition, isFalse);
    });

    test('un nom en un seul mot donne une seule initiale', () {
      final livreur = Livreur.fromJson({'fullName': 'Momar'});
      expect(livreur.initiales, 'M');
    });
  });

  group('Structure — la liste « Autour de vous »', () {
    test('réponse type de /structures', () {
      final s = Structure.fromJson(json.decode('''
        {
          "id": 17, "name": "Le Djoloff", "categorie": "restaurant",
          "logoFile": "logo.png", "latitude": 14.69, "longitude": -17.44,
          "adresse": "Mermoz, Dakar", "nombreEtoile": 4,
          "tempsLivraison": "25-35 min", "codeStructure": "DJL",
          "distance": 487.0
        }
      '''));

      expect(s.id, 17);
      expect(s.name, 'Le Djoloff');
      expect(s.distance, 487.0);
    });

    test('champs optionnels absents — valeurs de repli', () {
      final s = Structure.fromJson({'id': 1});
      expect(s.name, '');
      expect(s.nombreEtoile, 0);
      expect(s.distance, 0);
    });

    test('un id absent lève — et c\'est voulu', () {
      // Seul champ non tolérant du modèle : une structure sans id ne
      // peut ni être ouverte, ni mise en favori. Mieux vaut échouer
      // franchement que promener un objet inutilisable.
      expect(() => Structure.fromJson(<String, dynamic>{}), throwsA(anything));
    });

    test('un entier là où un double est attendu', () {
      // Le JSON ne distingue pas 14 de 14.0 : selon la valeur, le
      // serveur envoie l'un ou l'autre pour le même champ.
      final s = Structure.fromJson({'id': 1, 'latitude': 14, 'distance': 500});
      expect(s.latitude, 14.0);
      expect(s.distance, 500.0);
    });
  });

  group('UserProfile — le profil client', () {
    test('réponse de /registrations/detail', () {
      final p = UserProfile.fromJson(json.decode('''
        {"firstName": "Mame Khary", "lastName": "Seye",
         "email": "mk@yopmail.com", "telephone": "622123456",
         "address": "Mermoz, Dakar", "latitude": 14.69, "longitude": -17.44}
      '''));

      expect(p.fullName, 'Mame Khary Seye');
      expect(p.address, 'Mermoz, Dakar');
    });

    test('profil sans adresse — le cas du testeur', () {
      // C'est ce qui affichait « Définir une adresse » : le compte
      // n'avait jamais enregistré d'adresse, ce n'était pas un bug.
      final p = UserProfile.fromJson({
        'firstName': 'Test', 'lastName': 'Sup', 'email': 't@y.com',
      });
      expect(p.address, isNull);
      expect(p.telephone, '');
    });
  });
}
