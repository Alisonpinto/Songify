allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        if (project.name == "on_audio_query_android") {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                val hasNamespace = try {
                    androidExt.javaClass.getMethod("getNamespace").invoke(androidExt) != null
                } catch (e: Exception) {
                    false
                }
                if (!hasNamespace) {
                    try {
                        androidExt.javaClass.getMethod("setNamespace", String::class.java)
                            .invoke(androidExt, project.group.toString())
                    } catch (e: Exception) {
                        println("Failed to inject namespace into ${project.name}")
                    }
                }
                try {
                    androidExt.javaClass.getMethod("compileSdkVersion", Int::class.java).invoke(androidExt, 34)
                } catch (e: Exception) {
                    try {
                        androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.java).invoke(androidExt, 34)
                    } catch (e2: Exception) {}
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (project.name == "on_audio_query_android") {
        project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
