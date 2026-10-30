import org.gradle.api.provider.ValueSource
import org.gradle.api.provider.ValueSourceParameters
import org.gradle.process.ExecOperations
import java.io.ByteArrayOutputStream
import java.util.Properties
import javax.inject.Inject

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// A ValueSource is re-evaluated when checking configuration-cache validity,
// including when HEAD changes without a change to a tracked source file.
abstract class GitCommitValueSource : ValueSource<String, GitCommitValueSource.Parameters> {
    interface Parameters : ValueSourceParameters {
        val directory: DirectoryProperty
    }

    @get:Inject abstract val execOperations: ExecOperations

    override fun obtain(): String {
        return try {
            val output = ByteArrayOutputStream()
            val result = execOperations.exec {
                workingDir(parameters.directory.get().asFile)
                commandLine("git", "rev-parse", "--verify", "HEAD")
                standardOutput = output
                errorOutput = ByteArrayOutputStream()
                isIgnoreExitValue = true
            }
            val hash = output.toString().trim()
            if (result.exitValue == 0 && hash.matches(Regex("[0-9a-f]{40,64}"))) {
                hash
            } else {
                println("WARNING: Git commit unavailable; exporting null commitHash")
                ""
            }
        } catch (exception: Exception) {
            println("WARNING: Git commit unavailable; exporting null commitHash")
            ""
        }
    }
}

val gitCommit = providers.of(GitCommitValueSource::class) {
    parameters.directory.set(rootProject.layout.projectDirectory)
}

val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
if (releasePropertiesFile.exists()) {
    releasePropertiesFile.inputStream().use { releaseProperties.load(it) }
}
val hasReleaseSigning = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !releaseProperties.getProperty(it).isNullOrBlank() }
if (providers.environmentVariable("REQUIRE_RELEASE_SIGNING").orNull == "true") {
    check(hasReleaseSigning) { "Release signing is required but key.properties is missing or incomplete" }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
android {
    buildFeatures {
        buildConfig = true
        resValues = true
    }

    namespace = "de.uniulm.in.se.sixmwt"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        buildConfigField("String", "GIT_COMMIT", "\"${gitCommit.get()}\"")
        applicationId = "de.uniulm.in.se.sixmwt"
        resValue("string", "app_name", "6MWT")
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            resValue("string", "app_name", "6MWT Debug")
        }
        release {
            // Local and PR builds work without the private release keystore.
            signingConfig = signingConfigs.getByName(if (hasReleaseSigning) "release" else "debug")
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
