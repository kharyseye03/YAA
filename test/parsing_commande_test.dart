import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaa/model/cart/cart_model.dart';
import 'package:yaa/model/course/estimation_model.dart';
import 'package:yaa/model/order/commande_model.dart';
import 'package:yaa/model/transaction/transaction_model.dart';

/// Le parcours de commande : panier, estimation, transaction, suivi.
///
/// C'est la chaîne dont la casse coûte le plus cher — un client qui ne
/// peut pas commander est un client perdu, et le commerçant avec lui.
/// Chaque modèle est confronté à trois situations : la réponse
/// nominale, celle où le backend omet ce qu'il peut omettre, et les
/// calculs dérivés qui alimentent l'écran.
void main() {
  group('CartModel — le panier', () {
    // Forme réelle : le panier groupe ses lignes par établissement,
    // chaque groupe portant sa structure et ses produits.
    const panierJson = '''
    {
      "id": 42,
      "montantTotal": 17500.0,
      "multipleLivraison": false,
      "lignes": [
        {
          "structure": {"structureId": 17, "nomStructure": "Le Djoloff",
                        "adresseStructure": "Mermoz", "telephoneStructure": "771112233"},
          "produits": [
            {"id": 101, "produitId": 5, "nom": "Thieboudienne",
             "prixUnitaire": 5000.0, "quantite": 2, "sousTotal": 10000.0},
            {"id": 102, "produitId": 8, "nom": "Bissap",
             "prixUnitaire": 2500.0, "quantite": 3, "sousTotal": 7500.0}
          ]
        }
      ]
    }
    ''';

    test('le total vient du serveur, jamais d\'un calcul local', () {
      final panier = CartModel.fromJson(json.decode(panierJson));
      // Si le backend applique un jour une remise ou des frais, c'est
      // sa valeur qui doit s'afficher — pas une somme reconstituée.
      expect(panier.montantTotal, 17500.0);
    });

    test('le compteur d\'articles somme les quantités, pas les lignes', () {
      final panier = CartModel.fromJson(json.decode(panierJson));
      // Deux lignes, mais cinq articles : 2 thieb + 3 bissap. La
      // pastille de l'accueil affiche ce nombre-là.
      expect(panier.totalArticles, 5);
      expect(panier.allProduits.length, 2);
    });

    test('panier vide — aucune ligne, pas d\'exception', () {
      final panier = CartModel.fromJson(json.decode(
          '{"id": 1, "montantTotal": 0, "lignes": []}'));
      expect(panier.lignes, isEmpty);
      expect(panier.totalArticles, 0);
    });

    test('une ligne illisible est ignorée, le panier survit', () {
      // Avant : structureId manquant sur une ligne faisait echouer
      // tout le panier. L'ecran devenait vide et le client ne pouvait
      // plus commander — pour un champ absent sur un article.
      final panier = CartModel.fromJson(json.decode('''
        {"id": 1, "montantTotal": 5000, "lignes": [
          {"structure": {"nomStructure": "Sans identifiant"}, "produits": []},
          {"structure": {"structureId": 9, "nomStructure": "Valide",
                        "adresseStructure": "", "telephoneStructure": ""},
           "produits": [{"id": 1, "produitId": 1, "nom": "P",
                         "prixUnitaire": 5000, "quantite": 1}]}]}
      '''));
      expect(panier.lignes.length, 1);
      expect(panier.lignes.first.nomStructure, 'Valide');
      expect(panier.totalArticles, 1);
    });

    test('sousTotal absent — recalculé depuis prix et quantité', () {
      // Repli prévu dans le modèle : le serveur ne renvoie pas
      // toujours ce champ, l'écran en a pourtant besoin.
      final panier = CartModel.fromJson(json.decode('''
        {"id": 1, "montantTotal": 6000, "lignes": [
          {"structure": {"structureId": 2, "nomStructure": "X", "adresseStructure": "", "telephoneStructure": ""},
           "produits": [{"id": 1, "produitId": 1, "nom": "P",
                         "prixUnitaire": 2000, "quantite": 3}]}]}
      '''));
      expect(panier.lignes.first.produits.first.sousTotal, 6000.0);
    });
  });

  group('EstimationModel — le tarif d\'une course', () {
    test('réponse de /livraisons-courses/estimation/course', () {
      final e = EstimationModel.fromJson(json.decode('''
        {"distanceMetres": 4200, "distanceKm": 4.2, "distanceText": "4,2 km",
         "dureeSecondes": 900, "dureeMinutes": 15, "dureeText": "15 min",
         "fraisLivraison": 2500.0, "devise": "GNF", "typeVehicule": "MOTO"}
      '''));
      expect(e.fraisLivraison, 2500.0);
      expect(e.typeVehicule, 'MOTO');
      expect(e.devise, 'GNF');
    });

    test('le type de véhicule accepte les deux noms de champ', () {
      // Le backend a renvoyé tantôt typeVehicule, tantôt
      // typeVehiculeTarification. Les deux doivent aboutir, sinon le
      // tarif ne se range pas en face du bon véhicule et l'écran de
      // course affiche deux prix identiques.
      final a = EstimationModel.fromJson({'typeVehicule': 'VEHICULE'});
      final b = EstimationModel.fromJson({'typeVehiculeTarification': 'MOTO'});
      expect(a.typeVehicule, 'VEHICULE');
      expect(b.typeVehicule, 'MOTO');
    });

    test('devise absente — GNF par défaut, jamais vide', () {
      // Un montant sans unité ne veut rien dire à l'écran.
      final e = EstimationModel.fromJson({'fraisLivraison': 3000});
      expect(e.devise, 'GNF');
    });
  });

  group('TransactionModel — la commande créée', () {
    test('la réponse est enveloppée dans data', () {
      final t = TransactionModel.fromJson(json.decode('''
        {"status": 201, "success": true,
         "data": {"id": 88, "reference": "TRX-2026-0088",
                  "montant": 17500.0, "statut": "EN_ATTENTE"}}
      '''));
      expect(t.id, 88);
      expect(t.reference, 'TRX-2026-0088');
    });

    test('une réponse sans enveloppe lève — et doit lever', () {
      // Sans référence, le paiement ne peut pas aboutir. Mieux vaut
      // une erreur franche qu'une transaction fantôme.
      expect(
        () => TransactionModel.fromJson({'id': 1, 'reference': 'X'}),
        throwsA(anything),
      );
    });
  });

  group('CommandeModel — l\'onglet Achat', () {
    test('réponse de /commandes-clients', () {
      final c = CommandeModel.fromJson(json.decode('''
        {"id": 55, "structureName": "Le Djoloff", "structureAdresse": "Mermoz",
         "structureTelephone": "771112233", "referenceCommande": "CMD-55",
         "modeLivraison": "LIVRAISON", "modeReceptionCommande": "LIVRAISON",
         "montantTotal": 17500.0, "statut": "EN_COURS",
         "adresseLivraison": "Sacré-Coeur", "telephoneClient": "622123456"}
      '''));
      expect(c.id, 55);
      expect(c.referenceCommande, 'CMD-55');
      expect(c.montantTotal, 17500.0);
    });

    test('mode de réception absent — LIVRAISON par défaut', () {
      // Le repli du modèle : sans lui, l'écran ne saurait pas s'il
      // doit afficher une adresse ou un point de retrait.
      final c = CommandeModel.fromJson({'id': 1});
      expect(c.modeReceptionCommande, 'LIVRAISON');
    });

    test('champs de livraison nuls — le cas signalé au backend', () {
      // Observé sur la commande 55 : de nombreux champs revenaient
      // nuls. L'app doit rester utilisable en attendant.
      final c = CommandeModel.fromJson({
        'id': 55, 'typeVehicule': null, 'fraisLivraison': null,
      });
      expect(c.typeVehicule, isNull);
      expect(c.fraisLivraison, isNull);
      expect(c.structureName, '');
    });
  });
}
