import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clés natives lues depuis android/secrets.properties (non versionné).
// Voir secrets.properties.example pour le gabarit.
val secrets = Properties().apply {
    val file = rootProject.file("secrets.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val mapsApiKey: String = secrets.getProperty("MAPS_API_KEY") ?: ""

// Clé de signature de publication, lue depuis android/key.properties
// (non versionné, voir key.properties.example).
//
// Absente, le build retombe sur la clé de debug : `flutter run
// --release` continue de fonctionner sur un poste qui n'a pas la clé.
// Play refuse en revanche un binaire signé ainsi — d'où le garde-fou
// plus bas, qui arrête le build de publication plutôt que de livrer
// un AAB impubliable après plusieurs minutes d'attente.
val keyProps = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val aUneCleDePublication = keyProps.getProperty("storeFile") != null

android {
    namespace = "gn.yaa.client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
        }
    }

    defaultConfig {
        // Identifiant définitif de l'app client (l'app livreur est gn.yaa.pro).
        // ⚠️ Ne peut plus être modifié après la première publication.
        applicationId = "gn.yaa.client"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Injectée dans AndroidManifest.xml — la clé n'apparaît donc
        // jamais dans un fichier versionné.
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (aUneCleDePublication) {
            create("release") {
                storeFile     = rootProject.file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias      = keyProps.getProperty("keyAlias")
                keyPassword   = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (aUneCleDePublication) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Réduction et obscurcissement du code Java/Kotlin. Sans
            // effet sur le Dart, déjà compilé en natif, mais allège le
            // binaire et complique la lecture des bibliothèques
            // natives par quelqu'un qui décompresserait l'APK.
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
