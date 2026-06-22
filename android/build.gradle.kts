import org.gradle.api.JavaVersion

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android is com.android.build.api.dsl.ApplicationExtension) {
            android.compileSdk = 37
            android.defaultConfig {
                minSdk    = 24
                targetSdk = 37
            }
            android.compileOptions {
                sourceCompatibility            = JavaVersion.VERSION_17
                targetCompatibility            = JavaVersion.VERSION_17
            }
        } else if (android is com.android.build.api.dsl.LibraryExtension) {
            android.compileSdk = 36
            android.defaultConfig {
                minSdk = 24
            }
            android.compileOptions {
                sourceCompatibility            = JavaVersion.VERSION_17
                targetCompatibility            = JavaVersion.VERSION_17
            }
        }
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    description = "Deletes the build directory"
    delete(rootProject.layout.buildDirectory)
}
