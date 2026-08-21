import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// کلیدِ انتشار در مخزن نیست و نباید باشد. اگر بود — یعنی
// android/key.properties ساخته شده — با آن امضا می‌شود؛ وگرنه با کلیدِ debug،
// که برای نصبِ دستی بس است ولی برای بازار نه.
val keyProps = Properties()
val keyFile = rootProject.file("key.properties")
if (keyFile.exists()) {
    keyFile.inputStream().use { keyProps.load(it) }
}
val signRelease = !keyProps.isEmpty

android {
    namespace = "com.sareh.sareh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sareh.sareh"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // از pubspec.yaml می‌آید. با --split-per-abi، خودِ Flutter برای هر
        // معماری ۱۰۰۰×ABI به versionCode می‌افزاید تا سه APK با هم قاتی نشوند.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signRelease) {
            create("release") {
                storeFile = file(keyProps.getProperty("storeFile"))
                storePassword = keyProps.getProperty("storePassword")
                keyAlias = keyProps.getProperty("keyAlias")
                keyPassword = keyProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.getByName(if (signRelease) "release" else "debug")
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
