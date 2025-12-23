import Foundation

struct Config: Codable {
    let projectPath: String
    let scheme: String
    let configuration: String
    let destinationId: String
    let identifier: String

    static var xbuildDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".xbuild")
    }

    var projectDirectory: URL {
        Config.xbuildDirectory.appendingPathComponent(identifier)
    }

    var derivedDataPath: String {
        projectDirectory.appendingPathComponent("DerivedData").path
    }

    static func load(forProjectPath projectPath: String) -> Config? {
        let projectName = URL(fileURLWithPath: projectPath).deletingPathExtension().lastPathComponent
        let configDir = xbuildDirectory

        guard FileManager.default.fileExists(atPath: configDir.path) else {
            return nil
        }

        do {
            let dirs = try FileManager.default.contentsOfDirectory(at: configDir, includingPropertiesForKeys: nil)
            let matchingDirs = dirs.filter { $0.lastPathComponent.hasPrefix("\(projectName)-") }

            for dir in matchingDirs {
                let configFile = dir.appendingPathComponent("config.json")
                guard FileManager.default.fileExists(atPath: configFile.path) else { continue }

                let data = try Data(contentsOf: configFile)
                let config = try JSONDecoder().decode(Config.self, from: data)
                if config.projectPath == projectPath {
                    return config
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    static func create(
        projectPath: String,
        scheme: String,
        configuration: String,
        destinationId: String,
        existingIdentifier: String? = nil
    ) -> Config {
        let projectName = URL(fileURLWithPath: projectPath).deletingPathExtension().lastPathComponent
        let identifier = existingIdentifier ?? "\(projectName)-\(generateRandomSuffix())"

        return Config(
            projectPath: projectPath,
            scheme: scheme,
            configuration: configuration,
            destinationId: destinationId,
            identifier: identifier
        )
    }

    static func save(_ config: Config) {
        let projectDir = config.projectDirectory

        do {
            try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)

            let fileURL = projectDir.appendingPathComponent("config.json")
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: fileURL)
        } catch {
            fputs("Failed to save config: \(error.localizedDescription)\n", stderr)
        }
    }

    private static func generateRandomSuffix() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<5).map { _ in chars.randomElement()! })
    }
}
