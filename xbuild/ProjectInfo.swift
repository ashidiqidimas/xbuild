import Foundation

struct ProjectInfo {
    let path: String
    let name: String
    let schemes: [String]
    let configurations: [String]

    static func findProjectPath(inDirectory directory: String? = nil) -> String? {
        let searchDir = directory ?? FileManager.default.currentDirectoryPath
        return findPath(inDirectory: searchDir)
    }

    static func fetchDetails(forProjectAt path: String) -> ProjectInfo? {
        let directory = URL(fileURLWithPath: path).deletingLastPathComponent().path

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        process.arguments = ["-list", "-json"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            fputs("Failed to run xcodebuild: \(error.localizedDescription)\n", stderr)
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            fputs("Failed to parse xcodebuild output\n", stderr)
            return nil
        }

        if let project = json["project"] as? [String: Any] {
            let name = project["name"] as? String ?? "Unknown"
            let schemes = project["schemes"] as? [String] ?? []
            let configurations = project["configurations"] as? [String] ?? []
            return ProjectInfo(path: path, name: name, schemes: schemes, configurations: configurations)
        }

        if let workspace = json["workspace"] as? [String: Any] {
            let name = workspace["name"] as? String ?? "Unknown"
            let schemes = workspace["schemes"] as? [String] ?? []
            return ProjectInfo(path: path, name: name, schemes: schemes, configurations: ["Debug", "Release"])
        }

        return nil
    }

    private static func findPath(inDirectory directory: String) -> String? {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: directory)

            if let workspace = contents.first(where: { $0.hasSuffix(".xcworkspace") }) {
                return "\(directory)/\(workspace)"
            }

            if let project = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
                return "\(directory)/\(project)"
            }
        } catch {
            return nil
        }

        return nil
    }
}
