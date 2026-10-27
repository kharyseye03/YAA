import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaa/service/permissions/file_autorisations.dart';

void main() {
  group('FileAutorisations', () {
    test('une seule demande à la fois, même lancées ensemble', () async {
      // Chaque demande note son entrée et sa sortie. Si deux boîtes de
      // dialogue se chevauchaient, on lirait « entre B » avant
      // « sort A » — c'est le défaut qu'on corrige.
      final trace = <String>[];

      Future<void> demande(String nom, Duration duree) =>
          FileAutorisations.enFile(() async {
            trace.add('entre $nom');
            await Future<void>.delayed(duree);
            trace.add('sort $nom');
          });

      // A est la plus lente : sans file, B la doublerait.
      final a = demande('A', const Duration(milliseconds: 40));
      final b = demande('B', const Duration(milliseconds: 1));
      await Future.wait([a, b]);

      expect(trace, ['entre A', 'sort A', 'entre B', 'sort B']);
    });

    test('rend le résultat de la demande à son appelant', () async {
      final valeur = await FileAutorisations.enFile(() async => 42);
      expect(valeur, 42);
    });

    test('une demande qui échoue ne bloque pas les suivantes', () async {
      // Une autorisation refusée remonte parfois une exception. Si
      // elle restait dans la file, plus aucune demande ne partirait
      // de la session — l'app cesserait de poser ses questions.
      await expectLater(
        FileAutorisations.enFile(() async => throw StateError('refusé')),
        throwsStateError,
      );

      expect(await FileAutorisations.enFile(() async => 'ok'), 'ok');
    });
  });
}
