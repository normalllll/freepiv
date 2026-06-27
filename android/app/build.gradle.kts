import com.android.build.api.dsl.ApplicationExtension

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreFileArg = project.findProperty("KEYSTORE_FILE") as String?
val keystorePasswordArg = project.findProperty("KEYSTORE_PASSWORD") as String?
val keyAliasArg = project.findProperty("KEY_ALIAS") as String?
val keyPasswordArg = project.findProperty("KEY_PASSWORD") as String?

val hasReleaseSigning =
    !keystoreFileArg.isNullOrBlank() &&
            !keystorePasswordArg.isNullOrBlank() &&
            !keyAliasArg.isNullOrBlank() &&
            !keyPasswordArg.isNullOrBlank()

extensions.configure<ApplicationExtension> {
    namespace = "io.github.normalllll.freepiv"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "io.github.normalllll.freepiv"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }


    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(keystoreFileArg!!)
                storePassword = keystorePasswordArg
                keyAlias = keyAliasArg
                keyPassword = keyPasswordArg
            }
        }
    }

    buildTypes {
        getByName("debug") {

        }

        getByName("release") {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }

            signingConfig = signingConfigs.getByName("release")

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = true
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

dependencies {
    implementation("com.squareup.okhttp3:okhttp:5.4.0")
}
