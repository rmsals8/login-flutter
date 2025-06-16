plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun getEnvVariable(name: String, defaultValue: String = ""): String {
    // 1. System environment variables first
    val systemValue = System.getenv(name)
    if (!systemValue.isNullOrBlank()) {
        println("Found $name in system environment")
        return systemValue
    }
    
    // 2. Read from root .env file
    val rootEnvFile = rootProject.file("../.env")  // Go to Flutter root
    if (rootEnvFile.exists()) {
        println("Root .env file path: ${rootEnvFile.absolutePath}")
        try {
            val envContent = rootEnvFile.readText()
            println(".env file preview:")
            envContent.lines().take(3).forEach { line ->
                if (line.trim().isNotEmpty() && !line.startsWith("#")) {
                    println("   $line")
                }
            }
            
            // Parse .env file (KEY=VALUE format)
            envContent.lines().forEach { line ->
                val trimmedLine = line.trim()
                if (trimmedLine.isNotEmpty() && !trimmedLine.startsWith("#") && "=" in trimmedLine) {
                    val parts = trimmedLine.split("=", limit = 2)
                    if (parts.size == 2 && parts[0].trim() == name) {
                        val value = parts[1].trim()
                        println("Found $name in root .env file")
                        return value
                    }
                }
            }
        } catch (e: Exception) {
            println("Failed to read .env file: ${e.message}")
        }
    } else {
        println("Root .env file not found: ${rootEnvFile.absolutePath}")
    }
    
    return defaultValue
}

android {
    namespace = "com.example.login"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.login"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        println("Starting environment variable loading...")
        
        // Read environment variables from root .env file
        val naverClientId = getEnvVariable("NAVER_CLIENT_ID")
        val naverClientSecret = getEnvVariable("NAVER_CLIENT_SECRET") 
        val naverClientName = getEnvVariable("NAVER_CLIENT_NAME")
        val kakaoAppKey = getEnvVariable("KAKAO_NATIVE_APP_KEY")
        val serverDomain = getEnvVariable("SERVER_DOMAIN")
        // Validate loaded values (show only length for security)
        println("Loaded environment variables:")
        println("   - NAVER_CLIENT_ID: ${naverClientId.length} characters")
        println("   - NAVER_CLIENT_SECRET: ${naverClientSecret.length} characters")  
        println("   - NAVER_CLIENT_NAME: ${naverClientName.length} characters")
        println("   - KAKAO_APP_KEY: ${kakaoAppKey.length} characters")
    
        // Check that required values are not empty
        if (naverClientId.isBlank() || naverClientSecret.isBlank()) {
            throw GradleException("Naver Client ID or Secret is empty!")
        }
        if (kakaoAppKey.isBlank()) {
            throw GradleException("Kakao App Key is empty!")
        }
   
        // Set manifestPlaceholders
        manifestPlaceholders["naverClientId"] = naverClientId
        manifestPlaceholders["naverClientSecret"] = naverClientSecret
        manifestPlaceholders["naverClientName"] = naverClientName
        manifestPlaceholders["kakaoAppKey"] = kakaoAppKey
        manifestPlaceholders["serverDomain"] = serverDomain 
        println("All environment variables successfully set in manifestPlaceholders")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}