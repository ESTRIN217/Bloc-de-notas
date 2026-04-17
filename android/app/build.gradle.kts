import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 2. Cargamos las propiedades de forma segura
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.estrin217.bloc_de_notas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.estrin217.bloc_de_notas"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 3. signingConfigs DEBE ir antes de buildTypes
    signingConfigs {
        create("release") {
            // Usamos .getProperty() en lugar de corchetes para evitar errores de tipo
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            // Usamos rootProject.file() para evitar confusiones de alcance (scope)
            storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    // 4. Unificamos los bloques buildTypes en uno solo
    buildTypes {
        getByName("release") {
            // Aquí le asignamos la configuración de firma que creamos arriba
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = false // Cambia a true si usas Proguard en el futuro
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
