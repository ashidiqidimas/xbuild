# xbuild CLI Design

## Overview

A command-line wrapper around `xcodebuild` that provides interactive prompts for scheme, configuration, and destination selection, with persistent configuration per project.

## Commands

```
xbuild              # Build with saved config (or prompt if none exists)
xbuild --configure  # Force re-prompt and save new choices
```

## Configuration Storage

**Location:** `~/.xbuild/<project-folder-name>-<random-5-alphanumerics>.json`

**Example:** `~/.xbuild/MyApp-a7f2x.json`

**Structure:**
```json
{
  "projectPath": "/Users/dimas/Projects/MyApp/MyApp.xcodeproj",
  "scheme": "MyApp",
  "configuration": "Debug",
  "destinationId": "02CD8A1D-A2E9-4CA7-83AD-917F8B5DFEEF"
}
```

**Matching logic:** Scan `~/.xbuild/` for files starting with `<project-folder-name>-`, then match by `projectPath` inside the JSON.

## Data Sources

1. **Schemes & Configurations:** `xcodebuild -list -json`
2. **Simulators:** `xcrun simctl list devices available --json`

## File Structure

```
xbuild/
├── main.swift          # Entry point, argument parsing
├── Config.swift        # Load/save ~/.xbuild/*.json
├── ProjectInfo.swift   # Parse xcodebuild -list -json
├── Simulators.swift    # Parse xcrun simctl list --json
├── Prompts.swift       # Noora interactive prompts
└── Builder.swift       # Execute xcodebuild command
```

## Flow

```swift
@main
struct XBuild {
    static func main() {
        let forceReconfigure = CommandLine.arguments.contains("--configure")

        let projectInfo = ProjectInfo.fetch()
        let simulators = Simulators.fetchAvailable()

        var config = Config.load(for: projectInfo.path)

        if config == nil || forceReconfigure {
            config = Prompts.run(projectInfo: projectInfo, simulators: simulators)
            Config.save(config)
        }

        Builder.run(config: config)
    }
}
```

## Build Flags

Hardcoded optimization flags for fast incremental builds:

```
-parallelizeTargets
COMPILATION_CACHE_ENABLE_CACHING=YES
COMPILER_INDEX_STORE_ENABLE=NO
DEBUG_INFORMATION_FORMAT=dwarf
ONLY_ACTIVE_ARCH=YES
CODE_SIGNING_REQUIRED=NO
CODE_SIGNING_ALLOWED=NO
SWIFT_OPTIMIZATION_LEVEL=-Onone
SWIFT_COMPILATION_MODE=incremental
ENABLE_BITCODE=NO
GCC_OPTIMIZATION_LEVEL=0
```

## Dependencies

- **Noora** (tuist/Noora) - Interactive terminal prompts
