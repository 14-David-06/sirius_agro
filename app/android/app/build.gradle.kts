import java.util.Properties

// La llave de firma vive fuera del repositorio, en `android/key.properties`.
// Nunca se commitea: quien la tenga puede publicar una actualizacion que los
// telefonos van a aceptar como legitima.
val propsFirma = Properties().apply {
    val archivo = rootProject.file("key.properties")
    if (archivo.exists()) archivo.inputStream().use { load(it) }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.siriusregenerative.sirius_agro"
    // Fijado en 37, no heredado de flutter.compileSdkVersion (36), porque
    // permission_handler_android exige compilar contra 37 o mas. Compilar
    // contra 37 no cambia el comportamiento en runtime: eso lo define targetSdk.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.siriusregenerative.sirius_agro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Tres canales que pueden convivir en el mismo telefono. Cada uno lleva su
    // propio applicationId, asi que Android los trata como apps distintas:
    // instalar uno NO desinstala el que el visitador esta usando en campo, ni
    // le toca su base local de visitas.
    flavorDimensions += "canal"

    productFlavors {
        create("prod") {
            dimension = "canal"
            manifestPlaceholders["nombreApp"] = "Sirius Agro"
        }
        // La linea nueva que se reparte al piloto sin tocar la que ya esta en
        // los telefonos. Es produccion —se firma igual y no permite http en
        // claro— pero con su propio applicationId, o sea su propia base local:
        // arranca vacia y las visitas de la app vieja se quedan donde estan.
        create("v2") {
            dimension = "canal"
            applicationIdSuffix = ".v2"
            versionNameSuffix = "-v2"
            manifestPlaceholders["nombreApp"] = "Sirius Agro v2"
        }
        create("dev") {
            dimension = "canal"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            // El nombre bajo el icono: en el cajon de apps hay dos iconos
            // iguales y lo unico que los distingue es esta palabra.
            manifestPlaceholders["nombreApp"] = "Sirius Agro Dev"
        }
    }

    signingConfigs {
        create("release") {
            // Solo se configura si existe key.properties. Sin eso, un `flutter
            // build` en la maquina de otro no falla: cae a la llave de debug,
            // que sirve para probar pero NO para repartir.
            if (propsFirma.isNotEmpty()) {
                storeFile = file(propsFirma.getProperty("storeFile"))
                storePassword = propsFirma.getProperty("storePassword")
                keyAlias = propsFirma.getProperty("keyAlias")
                keyPassword = propsFirma.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // La llave de firma es la identidad de la app para Android: un APK
            // firmado con otra llave NO puede actualizar al instalado, hay que
            // desinstalar — y desinstalar borra la base local, o sea las visitas
            // que todavia no se sincronizaron. Por eso hay que fijarla ANTES de
            // repartir el primer APK, no despues.
            //
            // La de debug se genera sola en cada maquina: si este PC se pierde,
            // ningun APK nuevo podria actualizar los telefonos del piloto.
            signingConfig = if (propsFirma.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
