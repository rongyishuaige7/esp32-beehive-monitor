plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle 插件须在 Android 与 Kotlin Gradle 插件之后应用。
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.beehive.beehive_monitor_app"
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
        // TODO: 指定唯一的 Application ID（见 https://developer.android.com/studio/build/application-id.html）。
        applicationId = "com.beehive.beehive_monitor_app"
        // 可按应用需求修改下列取值。
        // 详见：https://flutter.dev/to/review-gradle-config
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: 为 release 构建添加正式签名配置。
            // 当前暂用 debug 密钥签名，以便 `flutter run --release` 可直接运行。
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
