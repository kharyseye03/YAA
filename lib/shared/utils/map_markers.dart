import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Marqueur construit à partir d'une image d'asset (moto, voiture…).
///
/// Le véhicule est posé nu sur la carte, sans pastille ni cadre : il
/// se fond dans le décor, comme les voitures des apps de VTC. L'image
/// doit donc être un PNG à fond transparent, vu de dessus.
///
/// [largeur] est en **pixels logiques** — la taille réellement perçue,
/// identique d'un appareil à l'autre.
///
/// [densite] doit valoir `MediaQuery.devicePixelRatioOf(context)`.
/// Voir la note sur la mise à l'échelle en bas de fichier : l'omettre
/// donne un marqueur agrandi et flou.
Future<BitmapDescriptor> createImageMarker(
  String assetPath, {
  double largeur = 48,
  double densite = 1,
}) async {
  final data  = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(),
    targetWidth: (largeur * densite).round(),
  );
  final image = (await codec.getNextFrame()).image;
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: densite,
  );
}

/// Dessine un marqueur « pin arrondi » (cercle coloré + anneau blanc
/// + pointe + icône au centre) et le convertit en BitmapDescriptor
/// utilisable par Google Maps.
///
/// Généré à la volée plutôt que chargé depuis un asset : les couleurs
/// suivent celles de la marque et restent modifiables en une ligne.
///
/// [scale] fixe la taille perçue, en pixels logiques ; [densite] ne
/// joue que sur la finesse du tracé. Voir la note en bas de fichier.
Future<BitmapDescriptor> createPinMarker(
  Color color,
  IconData icon, {
  double scale = 0.7,
  double densite = 1,
}) async {
  // Tout est dessiné à l'échelle densité pour que le canvas ait assez
  // de pixels ; imagePixelRatio ramène ensuite à la taille voulue.
  final double s       = scale * densite;
  final double w       = 78 * s;
  final double circleR = 29 * s;
  final double stemH   = 14 * s;
  final center   = Offset(w / 2, circleR + 5 * s);
  final recorder = ui.PictureRecorder();
  final canvas   = Canvas(recorder);

  // Ombre douce
  canvas.drawCircle(
    center.translate(0, 2 * s),
    circleR + 4 * s,
    Paint()..color = Colors.black.withValues(alpha: 0.15),
  );
  // Anneau blanc
  canvas.drawCircle(
      center, circleR + 4 * s, Paint()..color = Colors.white);
  // Cercle coloré
  final fill = Paint()..color = color;
  canvas.drawCircle(center, circleR, fill);
  // Pointe (triangle vers le bas)
  final stem = Path()
    ..moveTo(center.dx - 9 * s, center.dy + circleR - 4 * s)
    ..lineTo(center.dx + 9 * s, center.dy + circleR - 4 * s)
    ..lineTo(center.dx, center.dy + circleR + stemH)
    ..close();
  canvas.drawPath(stem, fill);
  // Icône blanche au centre
  final tp = TextPainter(textDirection: TextDirection.ltr)
    ..text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize   : 30 * s,
        fontFamily : icon.fontFamily,
        package    : icon.fontPackage,
        color      : Colors.white,
      ),
    )
    ..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

  final img = await recorder.endRecording().toImage(
        w.toInt(),
        (circleR + 5 * s + circleR + stemH + 4 * s).toInt(),
      );
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(
    data!.buffer.asUint8List(),
    imagePixelRatio: densite,
  );
}

// ── Pourquoi ce paramètre densite ────────────────────────────
//
// `BitmapDescriptor.bytes` prend un `imagePixelRatio` qui, s'il est
// omis, vaut 1.0 — « ces pixels sont des pixels logiques ». Comme le
// `bitmapScaling` par défaut est `auto`, Google Maps agrandit alors
// l'image de la densité de l'écran pour la ramener à cette taille
// supposée : sur un téléphone en densité 3, un bitmap de 55 px est
// étiré sur 165 px physiques. D'où un marqueur à la fois trop gros
// et flou.
//
// En dessinant à `taille × densite` et en déclarant cette densité, la
// taille perçue devient exactement celle demandée, et l'image est
// nette. Un appel qui oublie `densite` reste correct — juste moins
// fin, comme avant.
