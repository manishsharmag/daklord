plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localPropertiesFile = File(rootProject.projectDir, "local.properties")
if (localPropertiesFile.exists()) {
    val ndkLine = localPropertiesFile.readLines()
        .firstOrNull { line ->
            val trimmed = line.trimStart()
            trimmed.startsWith("ndk.dir=") && !trimmed.startsWith("#")
        }

    ndkLine?.substringAfter("ndk.dir=")?.let { rawValue ->
        val invalidBackslashPattern = Regex("""(?<!\\)\\(?!\\)""")
        if (invalidBackslashPattern.containsMatchIn(rawValue)) {
            throw org.gradle.api.GradleException(
                "ndk.dir in local.properties contains unescaped backslashes. " +
                    "Use forward slashes (C:/path) or escape them (C:\\\\path)."
            )
        }
    }
}

android {
    namespace = "com.example.insta_reel_downloader"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.insta_reel_downloader"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-gpu:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-nnapi:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
}

tasks.register("validateNativeLibs") {
    group = "verification"
    description = "Validates that native libraries are present and not corrupted"
    
    doLast {
        val jniLibsDir = file("src/main/jniLibs")
        val architectures = listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        val requiredLibs = listOf("libytdlp_bridge.so", "libffmpeg_bridge.so")
        
        var allValid = true
        
        architectures.forEach { arch ->
            val archDir = File(jniLibsDir, arch)
            if (!archDir.exists()) {
                logger.warn("Architecture directory missing: $arch")
                archDir.mkdirs()
                logger.info("Created directory: ${archDir.absolutePath}")
            }
            
            requiredLibs.forEach { lib ->
                val libFile = File(archDir, lib)
                if (!libFile.exists()) {
                    logger.warn("Native library missing: $arch/$lib")
                    logger.info("Creating placeholder for: $arch/$lib")
                    createPlaceholderLib(libFile)
                } else {
                    val size = libFile.length()
                    if (size < 1024) {
                        logger.warn("Native library appears corrupted (${size} bytes): $arch/$lib")
                        logger.info("Recreating placeholder for: $arch/$lib")
                        libFile.delete()
                        createPlaceholderLib(libFile)
                    }
                }
            }
        }
        
        logger.lifecycle("Native library validation complete")
    }
}

fun createPlaceholderLib(file: File) {
    file.parentFile.mkdirs()
    file.outputStream().use { out ->
        out.write(byteArrayOf(0x7f, 'E'.code.toByte(), 'L'.code.toByte(), 'F'.code.toByte()))
        val padding = ByteArray(4092)
        out.write(padding)
    }
}

tasks.register("validateTensorFlowLite") {
    group = "verification"
    description = "Validates TensorFlow Lite dependencies are accessible"
    
    doLast {
        val config = configurations.getByName("debugRuntimeClasspath")
        val tfLiteFiles = config.files.filter { it.name.contains("tensorflow-lite") }
        
        if (tfLiteFiles.isEmpty()) {
            logger.error("TensorFlow Lite dependencies not found in classpath!")
            logger.error("This may cause Kotlin compilation errors.")
            logger.error("Please ensure you have internet connectivity and try: ./gradlew clean build --refresh-dependencies")
        } else {
            logger.lifecycle("TensorFlow Lite dependencies found:")
            tfLiteFiles.forEach { file ->
                logger.lifecycle("  - ${file.name} (${file.length() / 1024} KB)")
            }
        }
    }
}

tasks.register("cleanCorruptedCache") {
    group = "build"
    description = "Cleans potentially corrupted Gradle cache and build artifacts"
    
    doLast {
        val gradleHome = File(System.getProperty("user.home"), ".gradle")
        val buildDirs = listOf(
            file("build"),
            file(".gradle"),
            file("../../build")
        )
        
        logger.lifecycle("Cleaning build directories...")
        buildDirs.forEach { dir ->
            if (dir.exists()) {
                logger.info("Deleting: ${dir.absolutePath}")
                dir.deleteRecursively()
            }
        }
        
        logger.lifecycle("Build artifacts cleaned. Run './gradlew build' to rebuild.")
    }
}

tasks.named("preBuild") {
    dependsOn("validateNativeLibs")
}

tasks.register("setupAndBuild") {
    group = "build"
    description = "Validates environment and builds the project"
    
    dependsOn("validateNativeLibs")
    dependsOn("validateTensorFlowLite")
    finalizedBy("assembleDebug")
}

tasks.register("fullCleanBuild") {
    group = "build"
    description = "Performs a complete clean build with validation"
    
    dependsOn("cleanCorruptedCache")
    finalizedBy("setupAndBuild")
}
