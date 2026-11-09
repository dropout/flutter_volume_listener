group = "dev.adampalinkas.flutter_volume_listener"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.3.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.5.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply(plugin = "com.android.library")

configure<com.android.build.api.dsl.LibraryExtension> {
    namespace = "dev.adampalinkas.flutter_volume_listener"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main").java.srcDir("src/main/kotlin")
        getByName("test").java.srcDir("src/test/kotlin")
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests.all { test ->
            test.useJUnitPlatform()
            test.testLogging.events("passed", "skipped", "failed", "standardOut", "standardError")
            test.outputs.upToDateWhen { false }
            test.testLogging.showStandardStreams = true
        }
    }
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
}

dependencies {
    add("testImplementation", "org.jetbrains.kotlin:kotlin-test")
    add("testImplementation", "org.mockito:mockito-core:5.0.0")
}
