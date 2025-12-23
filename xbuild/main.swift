import Foundation

let forceReconfigure = CommandLine.arguments.contains("--configure")
let verbose = CommandLine.arguments.contains("--verbose")

var customPath: String?
if let pathIndex = CommandLine.arguments.firstIndex(of: "--path"),
   pathIndex + 1 < CommandLine.arguments.count {
    customPath = CommandLine.arguments[pathIndex + 1]
}

guard let projectInfo = ProjectInfo.fetch(inDirectory: customPath) else {
    exit(1)
}

let simulators = Simulators.fetchAvailable()

if simulators.isEmpty {
    fputs("No available iOS simulators found\n", stderr)
    exit(1)
}

var config = Config.load(forProjectPath: projectInfo.path)

if config == nil || forceReconfigure {
    let existingIdentifier = config?.identifier
    config = Prompts.run(projectInfo: projectInfo, simulators: simulators, existingIdentifier: existingIdentifier)
    Config.save(config!)
}

Builder.run(config: config!, verbose: verbose)

