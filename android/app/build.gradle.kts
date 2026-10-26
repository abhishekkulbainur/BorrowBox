import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(f.inputStream())
}

android {
    namespace = "de.oppahansi.lendnborrow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    defaultConfig {
        applicationId = "de.oppahansi.lendnborrow"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        val storeFilePath = keystoreProps.getProperty("storeFile") ?: System.getenv("ANDROID_KEYSTORE")
        if (!storeFilePath.isNullOrBlank()) {
            create("release") {
                val storePwd = keystoreProps.getProperty("storePassword") ?: System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: ""
                val alias = keystoreProps.getProperty("keyAlias") ?: System.getenv("ANDROID_KEY_ALIAS") ?: ""
                val keyPwd = keystoreProps.getProperty("keyPassword") ?: System.getenv("ANDROID_KEY_PASSWORD") ?: ""

                storeFile = file(storeFilePath)
                storePassword = storePwd
                keyAlias = alias
                keyPassword = keyPwd
            }
        }
    }
    buildTypes {
        getByName("release") {
            val releaseSigning = signingConfigs.findByName("release")
            if (releaseSigning != null) {
                signingConfig = releaseSigning
            }
            isMinifyEnabled = false // Optional: disable minification, adjust as needed
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}
