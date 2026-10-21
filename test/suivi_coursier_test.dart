import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:yaa/shared/utils/suivi_coursier.dart';

void main() {
  group('cap', () {
    test('plein nord vaut 0°', () {
      final c = SuiviCoursier.cap(
          const LatLng(9.60, -13.60), const LatLng(9.70, -13.60));
      expect(c, closeTo(0, 0.5));
    });

    test('plein est vaut 90°', () {
      final c = SuiviCoursier.cap(
          const LatLng(9.60, -13.60), const LatLng(9.60, -13.50));
      expect(c, closeTo(90, 0.5));
    });

    test('plein sud vaut 180°', () {
      final c = SuiviCoursier.cap(
          const LatLng(9.70, -13.60), const LatLng(9.60, -13.60));
      expect(c, closeTo(180, 0.5));
    });
  });

  group('capInterpole — le piège du passage par le nord', () {
    test('de 350° à 10°, on tourne par le nord et non à l\'envers', () {
      // À mi-chemin on doit être à 0°, pas à 180° : sans le traitement
      // du plus court chemin, le véhicule ferait un tour complet sur
      // lui-même à chaque fois qu'il croise le nord.
      final milieu = SuiviCoursier.capInterpole(350, 10, 0.5);
      expect(milieu, closeTo(0, 0.001));
    });

    test('de 10° à 350°, on repasse par le nord dans l\'autre sens', () {
      expect(SuiviCoursier.capInterpole(10, 350, 0.5), closeTo(0, 0.001));
    });

    test('reste dans [0, 360)', () {
      expect(SuiviCoursier.capInterpole(350, 10, 1), closeTo(10, 0.001));
      expect(SuiviCoursier.capInterpole(350, 10, 0), closeTo(350, 0.001));
    });

    test('un demi-tour passe par un côté, sans osciller', () {
      final milieu = SuiviCoursier.capInterpole(0, 180, 0.5);
      expect(milieu, anyOf(closeTo(90, 0.001), closeTo(270, 0.001)));
    });
  });

  group('traceRestant', () {
    final trace = const [
      LatLng(9.60, -13.60),
      LatLng(9.61, -13.60),
      LatLng(9.62, -13.60),
      LatLng(9.63, -13.60),
    ];

    test('coupe ce qui est déjà parcouru', () {
      // Coursier au troisième point : il ne reste que la fin.
      final restant =
          SuiviCoursier.traceRestant(trace, const LatLng(9.62, -13.60));
      expect(restant.first.latitude, closeTo(9.62, 0.0001));
      expect(restant.length, 2); // sa position + le dernier point
    });

    test('au départ, presque tout reste à parcourir', () {
      final restant =
          SuiviCoursier.traceRestant(trace, const LatLng(9.60, -13.60));
      expect(restant.length, 4);
    });

    test('à l\'arrivée, il ne reste que la position', () {
      final restant =
          SuiviCoursier.traceRestant(trace, const LatLng(9.63, -13.60));
      expect(restant.length, 1);
    });

    test('un tracé vide ne lève pas', () {
      expect(SuiviCoursier.traceRestant(const [], const LatLng(9.6, -13.6)),
          isEmpty);
    });
  });

  group('capSurTrace', () {
    test('suit la direction du segment courant', () {
      final cap = SuiviCoursier.capSurTrace(
        const [LatLng(9.60, -13.60), LatLng(9.61, -13.60)],
        const LatLng(9.60, -13.60),
      );
      expect(cap, closeTo(0, 0.5)); // vers le nord
    });

    test('null si le tracé ne donne aucune direction', () {
      expect(
        SuiviCoursier.capSurTrace(
            const [LatLng(9.60, -13.60)], const LatLng(9.60, -13.60)),
        isNull,
      );
    });
  });
}
