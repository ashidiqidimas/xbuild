import Foundation

struct Builder {
    static func run(config: Config, verbose: Bool) {
        let destination = "platform=iOS Simulator,id=\(config.destinationId)"

        var arguments = [
            "-scheme", config.scheme,
            "-configuration", config.configuration,
            "-derivedDataPath", config.derivedDataPath,
            "-destination", destination,
            "-parallelizeTargets",
            "COMPILATION_CACHE_ENABLE_CACHING=YES",
            "COMPILER_INDEX_STORE_ENABLE=NO",
            "DEBUG_INFORMATION_FORMAT=dwarf",
            "ONLY_ACTIVE_ARCH=YES",
            "CODE_SIGNING_REQUIRED=NO",
            "CODE_SIGNING_ALLOWED=NO",
            "SWIFT_OPTIMIZATION_LEVEL=-Onone",
            "SWIFT_COMPILATION_MODE=incremental",
            "ENABLE_BITCODE=NO",
            "GCC_OPTIMIZATION_LEVEL=0"
        ]

        if !verbose {
            arguments.append("-quiet")
        }

        let projectDir = URL(fileURLWithPath: config.projectPath).deletingLastPathComponent().path
        print("Building \(config.scheme) (\(config.configuration))...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.currentDirectoryURL = URL(fileURLWithPath: projectDir)
        process.arguments = arguments
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("\nBuild succeeded!")
            } else {
                print("\nBuild failed with exit code \(process.terminationStatus)")
            }
        } catch {
            fputs("Failed to run xcodebuild: \(error.localizedDescription)\n", stderr)
        }
    }
}
