allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Força versões específicas para compatibilidade entre AGP 8.6.0 e Plugins
    configurations.all {
        resolutionStrategy {
            // Browser 1.8.0 deve ser suficiente para flutter_inappwebview e compatível com AGP 8.6
            force("androidx.browser:browser:1.8.0")
            
            // Outras libs em versões estáveis de ~2023/Inicio 2024
            force("androidx.activity:activity:1.8.2")
            force("androidx.activity:activity-ktx:1.8.2")
            force("androidx.core:core:1.12.0")
            force("androidx.core:core-ktx:1.12.0")
            force("androidx.annotation:annotation:1.7.0")
            
            force("org.jetbrains.kotlin:kotlin-stdlib:1.9.24")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.24")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
