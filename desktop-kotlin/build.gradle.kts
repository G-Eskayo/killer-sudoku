import org.jetbrains.compose.desktop.application.dsl.TargetFormat
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    kotlin("jvm") version "2.2.20"
    id("org.jetbrains.compose") version "1.12.0"
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.20"
    id("org.jetbrains.kotlin.plugin.serialization") version "2.2.20"
}

group = "me.gileskayo.killersudoku"
version = "1.0.0"

repositories {
    mavenCentral()
    google()
}

dependencies {
    implementation(compose.desktop.currentOs)
    implementation(compose.material3)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")

    testImplementation(kotlin("test"))
    testImplementation(kotlin("test-junit5"))
}

tasks.withType<KotlinCompile> {
    compilerOptions.freeCompilerArgs.add("-Xjsr305=strict")
}

tasks.test {
    useJUnitPlatform()
}

compose.desktop {
    application {
        mainClass = "me.gileskayo.killersudoku.MainKt"

        nativeDistributions {
            // ADR: same reasoning as the Swift app's docs/adr/0004 -- a real packaged app, not
            // a bare launched JAR, so it behaves like a normal installed application on each OS.
            targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
            packageName = "KillerSudoku"
            packageVersion = "1.0.0"
            description = "A native Killer Sudoku puzzle game."
            copyright = "© 2026 Gil Eskayo"
        }
    }
}
