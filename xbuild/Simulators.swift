import Foundation

struct Simulator: CustomStringConvertible, Equatable {
    let udid: String
    let name: String
    let runtime: String
    let state: String

    var description: String {
        "\(name) (\(runtime))"
    }
}

struct Simulators {
    static func fetchAvailable() -> [Simulator] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl", "list", "devices", "available", "--json"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            fputs("Failed to run xcrun simctl: \(error.localizedDescription)\n", stderr)
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]] else {
            fputs("Failed to parse simctl output\n", stderr)
            return []
        }

        var simulators: [Simulator] = []

        for (runtimeIdentifier, deviceList) in devices {
            let runtime = parseRuntime(runtimeIdentifier)

            guard runtime.contains("iOS") else { continue }

            for device in deviceList {
                guard let udid = device["udid"] as? String,
                      let name = device["name"] as? String,
                      let state = device["state"] as? String,
                      device["isAvailable"] as? Bool == true else { continue }

                let simulator = Simulator(udid: udid, name: name, runtime: runtime, state: state)
                simulators.append(simulator)
            }
        }

        simulators.sort { lhs, rhs in
            if lhs.state == "Booted" && rhs.state != "Booted" { return true }
            if lhs.state != "Booted" && rhs.state == "Booted" { return false }
            if lhs.runtime != rhs.runtime { return lhs.runtime > rhs.runtime }
            return lhs.name < rhs.name
        }

        return simulators
    }

    private static func parseRuntime(_ identifier: String) -> String {
        let parts = identifier.split(separator: ".")
        guard let last = parts.last else { return identifier }

        let versionPart = String(last)
        let components = versionPart.split(separator: "-")

        guard components.count >= 2 else { return identifier }

        let platform = String(components[0])
        let version = components.dropFirst().joined(separator: ".")

        return "\(platform) \(version)"
    }
}
