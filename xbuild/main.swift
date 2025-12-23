import Foundation
import Noora

let forceReconfigure = CommandLine.arguments.contains("--configure")
let verbose = CommandLine.arguments.contains("--verbose")

var customPath: String?
if let pathIndex = CommandLine.arguments.firstIndex(of: "--path"),
   pathIndex + 1 < CommandLine.arguments.count {
    customPath = CommandLine.arguments[pathIndex + 1]
}

let noora = Noora()

let projectInfo: ProjectInfo? = try await noora.progressStep(
    message: "Loading project",
    successMessage: "Project loaded",
    errorMessage: "Failed to load project",
    showSpinner: true
) { _ in
    ProjectInfo.fetch(inDirectory: customPath)
}

guard let projectInfo else {
    exit(1)
}

var config = Config.load(forProjectPath: projectInfo.path)

if config == nil || forceReconfigure {
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
