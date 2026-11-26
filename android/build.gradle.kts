group = "com.faceplugin.face_liveness_sdk"
version = "0.2.0"

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // AGP only — do not apply the Kotlin Gradle Plugin (Built-in Kotlin / AGP 9+).
        classpath("com.android.tools.build:gradle:8.9.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.faceplugin.face_liveness_sdk"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
    }
}

// Built-in Kotlin (AGP 9+ / Flutter consumer) — no org.jetbrains.kotlin.android apply.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.core:core-ktx:1.13.1")

    // The vendored kit binds CameraX for the preview and the frame analyzer.
    val cameraX = "1.4.2"
    implementation("androidx.camera:camera-core:$cameraX")
    implementation("androidx.camera:camera-camera2:$cameraX")
    implementation("androidx.camera:camera-lifecycle:$cameraX")
    implementation("androidx.camera:camera-view:$cameraX")

    // The engine. AGP forbids implementation(files("…aar")) on an Android library module —
    // :face_liveness_sdk:bundleDebugAar would fail — so the runtime always arrives as a flat
    // :libfacesdk artifact module (see example/android/libfacesdk).
    val libfacesdk = findProject(":libfacesdk")
    val strayAar = file("libs/facerecognitionsdk.aar")
    when {
        libfacesdk != null -> implementation(project(":libfacesdk"))
        strayAar.exists() ->
            throw GradleException(
                """
                Found android/libs/facerecognitionsdk.aar, but AGP cannot link a local .aar with
                implementation(files(…)) from a plugin library module.

                Demo app: move it to example/android/libfacesdk/facerecognitionsdk.aar
                (settings.gradle.kts already includes :libfacesdk).

                Your own app: copy example/android/libfacesdk/ into your Android project, place
                facerecognitionsdk.aar there, and add include(":libfacesdk") to settings.gradle —
                then depend on this plugin as usual.
                """.trimIndent()
            )
        else ->
            throw GradleException(
                """
                Missing the Face Liveness Android runtime (facerecognitionsdk.aar).

                It is the same engine the native apps run. Put it at
                example/android/libfacesdk/facerecognitionsdk.aar, with:

                  python scripts/sync_liveness_native.py --engine \
                      --engine-dest <this repo>/example/android/libfacesdk

                or copy it from Face-LivenessDetection-Android/libs/.
                """.trimIndent()
            )
    }
}
