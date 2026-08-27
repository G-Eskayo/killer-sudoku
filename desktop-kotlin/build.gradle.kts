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
    implementation(compose.materialIconsExtended)
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

        // macOS-only flag (harmless no-op elsewhere). Needs to be a real launch argument, not a
        // System.setProperty call from inside main() -- AWT's Cocoa bridge reads it at native
        // launch time, before the JVM even reaches user code, so setting it from there had no
        // effect (confirmed by testing). Only gets the title bar to AWT's own stock dark-aqua
        // gray (RGB 96,98,99) -- not an exact match to this app's own background (RGB 37,41,43),
        // which would need `apple.awt.transparentTitleBar`/`fullWindowContent`. Tried those too;
        // neither had any visible effect here, including in the actual packaged .app bundle, not
        // just `./gradlew run` -- this JVM's AWT build (plain OpenJDK, not JetBrains Runtime)
        // just doesn't implement them. Getting an exact match would mean switching the whole
        // toolchain to JBR, out of proportion for a title-bar color match.
        jvmArgs += listOf("-Dapple.awt.application.appearance=NSAppearanceNameDarkAqua")

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
