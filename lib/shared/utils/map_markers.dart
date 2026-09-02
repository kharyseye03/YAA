import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Marqueur construit à partir d'une image d'asset (moto, voiture…).
///
/// Le véhicule est posé nu sur la carte, sans pastille ni cadre : il
/// se fond dans le décor, comme les voitures des apps de VTC. L'image
/// doit donc être un PNG à fond transparent, idéalement vu de dessus.
///
/// [largeur] est en pixels physiques : à l'écran, la taille perçue
/// dépend de la densité de l'appareil.
Future<BitmapDescriptor> createImageMarker(
  String assetPath, {
  double largeur = 55,
}) async {
  final data  = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: largeur.toInt(),
  );
  final image = (await codec.getNextFrame()).image;
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
}

/// Dessine un marqueur « pin arrondi » (cercle coloré + anneau blanc
/// + pointe + icône au centre) et le convertit en BitmapDescriptor
/// utilisable par Google Maps.
///
/// Généré à la volée plutôt que chargé depuis un asset : les couleurs
/// suivent celles de la marque et restent modifiables en une ligne.
Future<BitmapDescriptor> createPinMarker(
  Color color,
  IconData icon, {
  double scale = 0.7,
}) async {
  final double w       = 78 * scale;
  final double circleR = 29 * scale;
  final double stemH   = 14 * scale;
  final center   = Offset(w / 2, circleR + 5 * scale);
  final recorder = ui.PictureRecorder();
  final canvas   = Canvas(recorder);

  // Ombre douce
  canvas.drawCircle(
    center.translate(0, 2 * scale),
    circleR + 4 * scale,
    Paint()..color = Colors.black.withValues(alpha: 0.15),
  );
  // Anneau blanc
  canvas.drawCircle(
      center, circleR + 4 * scale, Paint()..color = Colors.white);
  // Cercle coloré
  final fill = Paint()..color = color;
  canvas.drawCircle(center, circleR, fill);
  // Pointe (triangle vers le bas)
  final stem = Path()
    ..moveTo(center.dx - 9 * scale, center.dy + circleR - 4 * scale)
    ..lineTo(center.dx + 9 * scale, center.dy + circleR - 4 * scale)
    ..lineTo(center.dx, center.dy + circleR + stemH)
    ..close();
  canvas.drawPath(stem, fill);
  // Icône blanche au centre
  final tp = TextPainter(textDirection: TextDirection.ltr)
    ..text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize   : 30 * scale,
        fontFamily : icon.fontFamily,
        package    : icon.fontPackage,
        color      : Colors.white,
      ),
    )
    ..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

  final img = await recorder.endRecording().toImage(
        w.toInt(),
        (circleR + 5 * scale + circleR + stemH + 4 * scale).toInt(),
      );
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(data!.buffer.asUint8List());
}
