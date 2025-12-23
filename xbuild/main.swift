import Foundation
import Noora

if CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h") {
    print("""
    xbuild - Fast xcodebuild wrapper with persistent configuration

    USAGE: xbuild [OPTIONS]

    OPTIONS:
      --configure     Reconfigure scheme, configuration, and simulator
      --verbose       Show full xcodebuild output
      --path <dir>    Path to project directory
      -h, --help      Show this help message
    """)
    exit(0)
}

let forceReconfigure = CommandLine.arguments.contains("--configure")
let verbose = CommandLine.arguments.contains("--verbose")

var customPath: String?
if let pathIndex = CommandLine.arguments.firstIndex(of: "--path"),
   pathIndex + 1 < CommandLine.arguments.count {
    customPath = CommandLine.arguments[pathIndex + 1]
}

let noora = Noora()
let searchDir = customPath ?? FileManager.default.currentDirectoryPath

guard let projectPath = ProjectInfo.findProjectPath(inDirectory: searchDir) else {
    noora.error("No .xcodeproj or .xcworkspace found in \(searchDir)")
    exit(1)
}

var config = Config.load(forProjectPath: projectPath)

if config == nil || forceReconfigure {
    let projectInfo: ProjectInfo? = try await noora.progressStep(
        message: "Loading project configuration",
        successMessage: "Configuration loaded",
        errorMessage: "Failed to load configuration",
        showSpinner: true
    ) { _ in
        ProjectInfo.fetchDetails(forProjectAt: projectPath)
    }

    guard let projectInfo else {
        exit(1)
    }

    let simulators = Simulators.fetchAvailable()

    if simulators.isEmpty {
        fputs("No available iOS simulators found\n", stderr)
        exit(1)
    }

    let existingIdentifier = config?.identifier
    config = Prompts.run(projectInfo: projectInfo, simulators: simulators, existingIdentifier: existingIdentifier)
    Config.save(config!)
}

Builder.run(config: config!, verbose: verbose)
