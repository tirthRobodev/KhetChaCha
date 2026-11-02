import java.io.File

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Permanent KhetChacha release signing configuration
val releaseKeystore = file("khetchacha-release.jks")

val releaseStorePassword = System.getenv("KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("KEY_ALIAS")
val releaseKeyPassword = System.getenv("KEY_PASSWORD")

val hasReleaseSigning =
    releaseKeystore.exists() &&
    !releaseStorePassword.isNullOrBlank() &&
    !releaseKeyAlias.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.example.khetchacha"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.khetchacha"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseKeystore
            storePassword = releaseStorePassword ?: ""
            keyAlias = releaseKeyAlias ?: ""
            keyPassword = releaseKeyPassword ?: ""
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = null
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val isReleaseBuild = allTasks.any { task ->
        val name = task.name.lowercase()
        name.contains("release") && (name.contains("assemble") || name.contains("bundle") || name.contains("package"))
    }
    if (isReleaseBuild && !hasReleaseSigning) {
        throw GradleException(
            "KhetChacha release signing is not configured. " +
            "Check the keystore file and signing environment variables."
        )
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
