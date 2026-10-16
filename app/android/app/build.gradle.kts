import org.gradle.api.provider.ValueSource
import org.gradle.api.provider.ValueSourceParameters
import org.gradle.process.ExecOperations
import java.io.ByteArrayOutputStream
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

android {
    buildFeatures {
        buildConfig = true
    }

    namespace = "com.example.six_minute_walk_test"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        buildConfigField("String", "GIT_COMMIT", "\"${gitCommit.get()}\"")
        applicationId = "com.example.six_minute_walk_test"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
