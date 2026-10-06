# Flutter garde son propre moteur ; ces règles couvrent le code Java
# et Kotlin des greffons, que R8 pourrait élaguer à tort parce qu'il
# n'est appelé que par réflexion depuis le natif.

# Moteur Flutter et canaux de plateforme
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_secure_storage s'appuie sur Jetpack Security, dont les
# fabriques sont résolues par réflexion.
-keep class androidx.security.crypto.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }

# Composants différés de Flutter : le moteur référence Play Core pour
# télécharger des morceaux d'app à la demande. YAA ne s'en sert pas et
# n'embarque donc pas la bibliothèque, mais R8 voit les références et
# refuse de compiler. On lui dit que cette absence est voulue.
-dontwarn com.google.android.play.core.**

# Les traces d'exception gardent leurs numéros de ligne, sinon un
# rapport de plantage devient illisible.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
