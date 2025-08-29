plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.option.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
    
    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.option.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // App Bundle otimizações - NDK filtros removidos para usar splits
        
        // Configurações para Shell App
        manifestPlaceholders["enableShellApp"] = "true"
        manifestPlaceholders["optimizedForSize"] = "true"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Shell App otimizações adicionais
            isDebuggable = false
            isZipAlignEnabled = true
            
            buildConfigField("boolean", "SHELL_APP_MODE", "true")
            buildConfigField("boolean", "ENABLE_LAZY_LOADING", "true")
            buildConfigField("String", "CDN_BASE_URL", "\"https://qlbwacmavngtonauxnte.supabase.co\"")
        }
        
        debug {
            applicationIdSuffix = ".debug"
            isDebuggable = true
            buildConfigField("boolean", "SHELL_APP_MODE", "false")
            buildConfigField("boolean", "ENABLE_LAZY_LOADING", "false")
            buildConfigField("String", "CDN_BASE_URL", "\"\"")
        }
    }

    // Splits desabilitados para App Bundle - configurados via bundle block
    
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
    
    packagingOptions {
        pickFirsts += listOf(
            "**/libc++_shared.so",
            "**/libjsc.so",
            "**/libfbjni.so"
        )
        
        excludes += listOf(
            "META-INF/DEPENDENCIES",
            "META-INF/LICENSE",
            "META-INF/LICENSE.txt",
            "META-INF/license.txt",
            "META-INF/NOTICE",
            "META-INF/NOTICE.txt",
            "META-INF/notice.txt",
            "META-INF/ASL2.0"
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
